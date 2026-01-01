import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
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
import 'package:assign_erp/features/customer_crm/data/models/customer_model.dart';
import 'package:assign_erp/features/sales_distribution/data/model/sales_quotation_model.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_distribution_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_quotation/sales_quotation_bloc.dart';
import 'package:flutter/material.dart';
/*import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';*/

extension SalesQuoteDetails on BuildContext {
  Future openSQDetails({
    required Customer customer,
    required SalesQuotationBloc bloc,
    required SalesQuotation salesQuote,
  }) async => await openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetailMode: true,
      title: 'Sales Quotation (${salesQuote.lineItems.first.getTypeLabel})',
      subtitle: salesQuote.quoteNumber.toUpperAll,
      body: _SQInfoPage(salesQuote: salesQuote, customer: customer.name),
      onSecondaryTap: () async => await _printSQ(salesQuote, bloc, customer),
    ),
  );

  _printSQ(
    SalesQuotation salesQuote,
    SalesQuotationBloc bloc,
    Customer customer,
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
  final String _requestBy;
  final SalesQuotation? _salesQuote;
  final Color? _textColor;

  const _SQInfoPage({
    SalesQuotation? salesQuote,
    String customer = '',
    Color? textColor,
  }) : _salesQuote = salesQuote,
       _requestBy = customer,
       _textColor = textColor;

  List<LineItem> get _items => _salesQuote?.lineItems ?? [];

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
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveLayout(
          children: [
            _buildHeader(context),

            Align(
              alignment: Alignment.topRight,
              child: _buildHistoryButton(context),
            ),
          ],
        ),

        /*Align(
          alignment: Alignment.center,
          child: Text(
            'Line Items (${_items.length})',
            style: context.textTheme.titleLarge?.copyWith(
              color: _textColor ?? kPrimaryAccentColor,
            ),
          ),
        ),
        HorizontalDivider(),

        Table Headers
        _buildItemTableHeader(context),
        ..._items.asMap().entries.map(
          (item) => _buildItemRow(item.value, item.key),
        ),
        HorizontalDivider(),*/
        InlineHistoryTable<LineItem>(
          title: 'Line Items (${_items.length})',
          // headingRowColor: context.primaryContainer,
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
            _LeftSummary(salesQuote: _salesQuote, textColor: _textColor),
            _RightSummary(salesQuote: _salesQuote, textColor: _textColor),
          ],
        ),
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
      ('Customer', _salesQuote!.customerName.toTitle),
      ('Sales Person', _requestBy.toTitle),
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

  /*
  Expanded _buildItem(String text, {bool isBold = true}) => Expanded(
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

  Widget _buildHistoryButton(BuildContext context) {
    return context.outlinedIconBtn(
      Icon(Icons.explore_outlined, color: kPrimaryAccentColor),
      borderColor: kPrimaryAccentColor,
      onPressed: () async => await _onOpenHistory(context),
      tooltip: 'View Sales Quote History',
      label: Text(
        'SQ History',
        style: const TextStyle(color: kPrimaryAccentColor),
      ),
    );
  }

  Future<void> _onOpenHistory(BuildContext cxt) async {
    if (_salesQuote == null) return;

    await cxt.showInlineHistorySheet<AuditLog>(
      title: 'Workflow History',
      columnLabels: AuditLog.dataTableHeader,
      items: _salesQuote.history, // list of SQ history
      rowBuilder: (entry) {
        return DataRow(
          cells: entry.itemAsList.map((cell) => DataCell(Text(cell))).toList(),
        );
      },
    );
  }
}

class _LeftSummary extends StatelessWidget {
  final SalesQuotation? salesQuote;
  final Color? textColor;

  const _LeftSummary({this.salesQuote, required this.textColor});

  get _summaryItems => <(String, String)>[
    (
      'Valid Date',
      '${salesQuote?.getValidFromDate} - ${salesQuote?.getValidToDate}',
    ),
    ('Expected Date', '${salesQuote?.getExpectedDate}'),
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
          _buildInfoRow(
            context,
            separator: '\n',
            textColor: textColor,
            title: 'Additional notes:',
            value: salesQuote!.notes.toSentence,
          ),
          const SizedBox(height: 10),
          // HorizontalDivider(),
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

  const _RightSummary({this.salesQuote, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return _buildRightSummary(context);
  }

  Widget _buildRightSummary(BuildContext context) {
    final history = _prHistory(salesQuote!);

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            separator: '\n',
            textColor: kDangerColor,
            title: 'Approved By:',
            value:
                '${history.$1 ?? 'Not yet approved'}\n${history.$2 ?? '-----------------'}',
          ),
        ],
      ),
    );
  }

  /// Get the last approved PR entry and the date it was approved [_prHistory]
  (String?, String?) _prHistory(SalesQuotation? req) {
    if (req == null) return (null, null);

    // Find the most recent approved PR entry
    final lastApproved = req.history.lastWhere(
      (h) => h.getAction.toLowerAll == AuditAction.approved.getLabel,
      orElse: () => AuditLog.empty,
    );

    // If none found, return null for both
    if (lastApproved.isEmpty) return (null, null);

    return (lastApproved.actionBy, lastApproved.getActionAt);
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
