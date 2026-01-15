import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
import 'package:assign_erp/core/widgets/see_detail/see_details.dart';
import 'package:assign_erp/features/sales_distribution/data/model/sales_quotation_model.dart';
import 'package:flutter/material.dart';
/*import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';*/

extension SalesQuoteDetails on BuildContext {
  Future openSQDetails({
    required SalesQuotation salesQuote,
    required Function(bool) onPrint,
    // required Customer customer,
    // required SalesQuotationBloc bloc,
  }) async => await openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetailMode: true,
      title: 'Sales Quotation (${salesQuote.lineItems.first.getType})',
      subtitle: salesQuote.quoteNumber.toUpperAll,
      secondaryWidget: _showHistory(salesQuote),
      body: _SQInfoPage(salesQuote: salesQuote),
      onPrint: () async => await _printSQ(salesQuote, onPrint /*,customer*/),
    ),
  );

  _printSQ(
    SalesQuotation salesQuote,
    Function(bool) onPrint,
    // SalesQuotationBloc bloc,
    // Customer customer,
  ) async {
    await progressBarDialog(
      request: Future.delayed(kRProgressDelay, () async {
        // await PRPrinter(salesQuote: salesQuote, customer: customer).printPR();
        // bloc.add(_updateHistory(salesQuote));
        onPrint(true);
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
      // borderColor: kPrimaryAccentColor.toAlpha(0),
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

  /*/// Audit Log Entry (Tracking actions)
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
  }*/
}

class _SQInfoPage extends StatelessWidget {
  final SalesQuotation? _salesQuote;
  final Color? _textColor;

  const _SQInfoPage({SalesQuotation? salesQuote, Color? textColor})
    : _salesQuote = salesQuote,
      _textColor = textColor;

  List<LineItem> get _items => _salesQuote?.lineItems ?? [];

  bool get _isPerLineTax => _salesQuote?.taxMode.isPerLineTax ?? false;

  String? get _currencySign =>
      getCurrencySign(_salesQuote?.currencyCode ?? ghanaCedis);

  SummaryItem get _approval {
    ApprovalInfo? item = _salesQuote?.getApproval;

    return (
      title: 'Approved By',
      value:
          '\n${item?.by ?? 'Not yet approved'}\n${item?.at ?? '-----------------'}',
    );
  }

  List<SummaryItem> get _rightSummaryItems => [
    (
      title: 'Subtotal',
      value: '$_currencySign${(_salesQuote?.subTotal ?? 0.0).toCurrency}',
    ),
    (
      title: 'Discount',
      value:
          '- $_currencySign${(_salesQuote?.totalDiscountAmount ?? 0.0).toCurrency}',
    ),
    (
      title: 'Tax %',
      value: '${(_salesQuote?.totalTaxPercent ?? 0.0).toPercent}',
    ),
    (
      title: 'Net Total',
      value: '$_currencySign${(_salesQuote?.netTotal ?? 0.0).toCurrency}',
    ),

    if ((_salesQuote?.shippingTaxAmount ?? 0.0) > 0) ...[
      (
        title: 'Shipping',
        value:
            '$_currencySign${(_salesQuote?.shippingAmount ?? 0.0).toCurrency}',
      ),
      (
        title: 'Shipping Tax',
        value:
            '$_currencySign${(_salesQuote?.shippingTaxAmount ?? 0.0).toCurrency}',
      ),
    ],
    (
      title: 'Grand Total',
      value: '$_currencySign${(_salesQuote?.grandTotal ?? 0.0).toCurrency}',
    ),
  ];

  List<SummaryItem> get _leftSummaryItems => [
    (title: 'Currency', value: '${_salesQuote?.currencyCode} ($_currencySign)'),
    (title: 'Exchange Rate', value: '${_salesQuote?.exchangeRate.toCurrency}'),
    (title: 'Valid From', value: '${_salesQuote?.getValidFromDate}'),
    (title: 'Valid Until', value: '${_salesQuote?.getValidUntilDate}'),
    (title: 'Expected Date', value: '${_salesQuote?.getExpectedDate}'),
    // If Tax Mode is not Per Line, add Tax Details here
    if (!_isPerLineTax) ...{
      (
        title: 'Applied Taxes',
        value: _salesQuote!.lineItems.first.taxNames.toUpperAll,
      ),
    },
  ];

  List<SummaryItem> get _terms => [
    (
      title: 'Payment Terms',
      value: _salesQuote?.paymentTerms.toSentence ?? 'N/A',
    ),
    (title: 'Warranty', value: _salesQuote?.warrantyTerms.toSentence ?? 'N/A'),
    (
      title: 'Return Policy',
      value: _salesQuote?.returnPolicy.toSentence ?? 'N/A',
    ),
    (title: 'Additional Notes', value: _salesQuote?.notes.toSentence ?? 'N/A'),
  ];

  @override
  Widget build(BuildContext context) {
    if (_salesQuote == null) {
      return const Center(child: Text("PR not available."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBody(context),
        DetailsFooter(
          created: (by: _salesQuote.createdBy, at: _salesQuote.getCreatedAt),
          updated: (by: _salesQuote.updatedBy, at: _salesQuote.getUpdatedAt),
        ),
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
          columnLabels: _items.first.dataTableHeader(_isPerLineTax),
          items: _items,
          // list of Sales Quotes
          rowBuilder: (entry) {
            return DataRow(
              cells: entry
                  .itemAsList(_isPerLineTax)
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
          isSizedBox: false,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DetailsSummary(
              textColor: _textColor,
              items: _leftSummaryItems,
              alignment: Alignment.topLeft,
            ),
            DetailsSummary(
              crossAxisAlignment: CrossAxisAlignment.end,
              textColor: _textColor,
              items: _rightSummaryItems,
              alignment: Alignment.topRight,
              anyWidget: detailsRow(
                context,
                title: _approval.title,
                textColor: kDangerColor,
                value: _approval.value,
              ),
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
    List<SummaryItem> headerItems = [
      (title: 'SQ#', value: _salesQuote?.quoteNumber ?? 'N/A'),
      (title: 'Store ID', value: _salesQuote?.storeNumber.toUpperAll ?? 'N/A'),
      (title: 'Status', value: _salesQuote?.getSQStatus.toSentence ?? 'N/A'),
      (
        title: 'Sales Channel',
        value: _salesQuote?.getSalesChannel.toTitle ?? 'N/A',
      ),
      (
        title: 'Tax Mode',
        value: _salesQuote?.getTaxName.separateWord.toTitle ?? 'N/A',
      ),
      (title: 'Customer', value: _salesQuote?.customerName.toTitle ?? 'N/A'),
      (title: 'Sales Person', value: _salesQuote?.salesRepId.toTitle ?? 'N/A'),
    ];

    return DetailsSummary(
      isAlign: false,
      items: headerItems,
      textColor: _textColor,
      alignment: Alignment.topLeft,
    );
  }

  Widget _termsAndConditions(BuildContext context) {
    return AdaptiveLayout(
      children: [
        ..._terms.map(
          (item) => detailsRow(
            context,
            isReadMore: true,
            title: item.title,
            value: item.value,
            textColor: _textColor,
          ),
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
