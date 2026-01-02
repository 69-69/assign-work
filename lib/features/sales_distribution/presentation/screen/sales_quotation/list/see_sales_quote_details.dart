import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/constants/tax_mode.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/sales_distribution/data/model/sales_quotation_model.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_distribution_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_quotation/sales_quotation_bloc.dart';
import 'package:flutter/material.dart';
/*import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';*/

extension SalesQuoteDetails on BuildContext {
  Future openSQDetails({
    // required Customer customer,
    required SalesQuotationBloc bloc,
    required SalesQuotation salesQuote,
  }) async => await openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetailMode: true,
      title: 'Sales Quotation (${salesQuote.lineItems.first.getTypeLabel})',
      subtitle: salesQuote.quoteNumber.toUpperAll,
      secondaryWidget: _showHistory(salesQuote),
      body: _SQInfoPage(salesQuote: salesQuote),
      onPrint: () async => await _printSQ(salesQuote, bloc /*customer*/),
    ),
  );

  _printSQ(
    SalesQuotation salesQuote,
    SalesQuotationBloc bloc,
    // Customer customer,
  ) async {
    await progressBarDialog(
      request: Future.delayed(kRProgressDelay, () async {
        // await PRPrinter(salesQuote: salesQuote, customer: customer).printPR();
        bloc.add(_updateHistory(salesQuote));
      }),
      onSuccess: (_) => showAlertOverlay('SQ printout successful'),
      onError: (e) =>
          showAlertOverlay('SQ printout failed', bgColor: kDangerColor),
    );
  }

  Widget _showHistory(SalesQuotation? salesQuote) {
    return iconButton(
      Icons.history,
      iconColor: kPrimaryAccentColor,
      bgColor: kPrimaryAccentColor.toAlpha(0.1),
      tooltip: 'View Sales Quote History',
      onPressed: () async => await _onOpenHistory(salesQuote),
    );
  }

  Future<void> _onOpenHistory(SalesQuotation? salesQuote) async {
    if (salesQuote == null) return;

    await showHistoryBottomSheet<AuditLog>(
      title: 'Workflow History',
      columnLabels: AuditLog.dataTableHeader,
      items: salesQuote.history, // list of SQ history
      rowBuilder: (entry) {
        return DataRow(
          cells: entry.itemAsList.map((cell) => DataCell(Text(cell))).toList(),
        );
      },
    );
  }

  /// Audit Log Entry (Tracking actions)
  AuditSalesDistribution<SalesQuotation> _updateHistory(SalesQuotation quote) {
    return AuditSalesDistribution<SalesQuotation>(
      documentId: quote.id,
      log: AuditLog.logScaffold(
        oldLogs: quote.history,
        newLog: AuditLog(
          action: AuditAction.printed,
          actionBy: employee!.employeeId,
          statusAfterAction: quote.getSQStatus,
        ),
      ),
    );
  }
}

/// Helper to build info row
Widget _buildInfoRow(
  BuildContext context, {
  Color? textColor,
  String title = '',
  String value = '',
  String separator = ': ',
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 2.0),
    child: RichText(
      text: TextSpan(
        text: '$title$separator',
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor ?? context.secondaryColor,
        ),
        children: [
          TextSpan(
            text: value,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SQInfoPage extends StatelessWidget {
  final SalesQuotation? _salesQuote;
  final Color? _textColor;

  const _SQInfoPage({SalesQuotation? salesQuote, Color? textColor})
    : _salesQuote = salesQuote,
      _textColor = textColor;

  List<LineItem> get _items => _salesQuote?.lineItems ?? [];

  String? get _currencySign =>
      getCurrencySign(_salesQuote?.currencyCode ?? ghanaCedis);

  @override
  Widget build(BuildContext context) {
    if (_salesQuote == null) {
      return const Center(child: Text("PR not available."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBody(context),
        _Footer(salesQuote: _salesQuote),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),

        SortableHistoryTable<LineItem>(
          title: 'Line Items (${_items.length})',
          columnLabels: _items.first.dataTableHeader,
          items: _items,
          // list of Sales Quotes
          rowBuilder: (entry) {
            return DataRow(
              cells: entry.itemAsList
                  .map((cell) => DataCell(Text(cell)))
                  .toList(),
            );
          },
          sortAccessors: [
            (entry) => entry.description,
            (entry) => entry.quantity,
            (entry) => entry.getCategory,
          ],
        ),
        const SizedBox(height: 12),

        AdaptiveLayout(
          children: [
            _LeftSummary(
              salesQuote: _salesQuote,
              textColor: _textColor,
              currencySign: _currencySign,
            ),
            _RightSummary(
              salesQuote: _salesQuote,
              textColor: _textColor,
              currencySign: _currencySign,
            ),
          ],
        ),
        const SizedBox(height: 20),

        _termsAndConditions(context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Build the list of header entries first
    final headerItems = <(String, String)>[
      ('SQ#', _salesQuote?.quoteNumber ?? 'N/A'),
      ('Store ID', _salesQuote?.storeNumber.toUpperAll ?? 'N/A'),
      ('Status', _salesQuote?.getSQStatus.toSentence ?? 'N/A'),
      ('Sales Channel', _salesQuote?.getSalesChannel.toTitle ?? 'N/A'),
      ('Tax Mode', _salesQuote?.getName.separateWord.toTitle ?? 'N/A'),
      ('Customer', _salesQuote?.customerName.toTitle ?? 'N/A'),
      ('Sales Person', _salesQuote?.salesRepId.toTitle ?? 'N/A'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Text('sales Quote', style: context.textTheme.headlineSmall),
        // const SizedBox(height: 8),
        ...headerItems.map(
          (item) => _buildInfoRow(
            context,
            textColor: _textColor,
            title: item.$1,
            value: item.$2,
          ),
        ),
      ],
    );
  }

  Widget _termsAndConditions(BuildContext context) {
    return AdaptiveLayout(
      children: [
        _buildInfoRow(
          context,
          separator: '\n',
          title: 'Payment Terms:',
          value: _salesQuote?.paymentTerms.toSentence ?? 'N/A',
        ),
        _buildInfoRow(
          context,
          separator: '\n',
          title: 'Warranty:',
          value: _salesQuote?.warrantyTerms.toSentence ?? 'N/A',
        ),
        _buildInfoRow(
          context,
          separator: '\n',
          title: 'Return Policy:',
          value: _salesQuote?.returnPolicy.toSentence ?? 'N/A',
        ),
        _buildInfoRow(
          context,
          separator: '\n',
          title: 'Additional Notes:',
          value: _salesQuote?.notes.toSentence ?? 'N/A',
        ),
      ],
    );
  }

  /* Expanded _buildItem(String text, {bool isBold = true}) => Expanded(
    child: Text(
      text,
      style: TextStyle(
        overflow: TextOverflow.ellipsis,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
  Widget _buildItemTableHeader(BuildContext context) {
    final headerItems = [
      '#',
      'Item',
      'Qty',
      'Category',
      'Unit Of Measure',
      'Notes',
    ];

    return Container(
      color: context.primaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: headerItems.map((item) => _buildItem(item)).toList(),
      ),
    );
  }

  Widget _buildItemRow(PRLineItem item, int index) {
    List rowItems = [
      '${index + 1}',
      item.itemName.toTitle,
      '${item.quantity}',
      item.category.getLabel.toTitle,
      item.unitOfMeasure.getLabel.toTitle,
      item.notes.toSentence,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: rowItems
            .map((item) => _buildItem(item, isBold: false))
            .toList(),
      ),
    );
  }*/
}

class _LeftSummary extends StatelessWidget {
  final SalesQuotation? salesQuote;
  final Color? textColor;
  final String? currencySign;

  const _LeftSummary({
    this.salesQuote,
    required this.textColor,
    this.currencySign,
  });

  TaxMode? get _taxMode => salesQuote?.taxMode;
  bool get _isPerLineTax => _taxMode?.isPerLineTax ?? false;

  get _summaryItems => <(String, String)>[
    ('Currency', '${salesQuote?.currencyCode} ($currencySign)'),
    ('Valid From', '${salesQuote?.getValidFromDate}'),
    ('Valid Until', '${salesQuote?.getValidUntilDate}'),
    ('Expected Date', '${salesQuote?.getExpectedDate}'),
    // If Tax Mode is not Per Line, add Tax Details here
    if (!_isPerLineTax) ...{
      ('Applied Taxes', salesQuote!.lineItems.first.taxNames.toUpperAll),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _buildLeftSummary(context);
  }

  // Helper for optional multiline sections (adds spacing automatically)
  List<Widget> buildOptionalSection(
    BuildContext context,
    String title,
    String? value,
  ) {
    return (value == null || value.isEmpty)
        ? []
        : [
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              separator: ':\n',
              title: title,
              value: value.toSentence,
            ),
          ];
  }

  Widget _buildLeftSummary(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._summaryItems.map(
            (item) => _buildInfoRow(
              context,
              textColor: textColor,
              title: item.$1,
              value: item.$2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RightSummary extends StatelessWidget {
  final SalesQuotation? salesQuote;
  final Color? textColor;
  final String? currencySign;

  const _RightSummary({
    this.salesQuote,
    required this.currencySign,
    required this.textColor,
  });

  double get _grandTotal => salesQuote?.totalAmount ?? 0.0;

  get summaryItems => <(String, String)>[
    ('Subtotal', '$currencySign${(salesQuote?.subTotal ?? 0.0).toCurrency}'),
    (
      'Discount',
      '- $currencySign${(salesQuote?.discountAmount ?? 0.0).toCurrency}',
    ),
    ('Tax %', '${(salesQuote?.taxAmount ?? 0.0)}%'),
    ('Net Total', '$currencySign${(salesQuote?.netTotal ?? 0.0).toCurrency}'),
    (
      'Shipping',
      '$currencySign${(salesQuote?.shippingAmount ?? 0.0).toCurrency}',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _buildRightSummary(context);
  }

  Widget _buildRightSummary(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ...summaryItems.map(
            (item) => _buildInfoRow(
              context,
              textColor: textColor,
              title: item.$1,
              value: item.$2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Grand Total: $currencySign${_grandTotal.toCurrency}',
            style: context.textTheme.titleLarge?.copyWith(color: kDangerColor),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final SalesQuotation? salesQuote;

  const _Footer({this.salesQuote});

  String? get _updatedBy =>
      salesQuote!.updatedBy.isNullOrEmpty ? 'N/A' : salesQuote?.updatedBy;

  String? get _createdBy =>
      salesQuote!.createdBy.isNullOrEmpty ? 'N/A' : salesQuote?.createdBy;

  @override
  Widget build(BuildContext context) {
    return _buildFooter(context);
  }

  Container _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: context.secondaryContainerColor,
      child: AdaptiveLayout(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _buildInfoRow(
              context,
              title: 'Created',
              value:
                  '${salesQuote?.getCreatedAt} - By: [ ${_createdBy.toTitle} ]',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _buildInfoRow(
              context,
              title: 'Updated',
              value:
                  '${salesQuote!.getUpdatedAt} - By: [ ${_updatedBy.toTitle} ]',
            ),
          ),
        ],
      ),
    );
  }
}
