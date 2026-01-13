import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
import 'package:assign_erp/core/widgets/see_detail/see_details.dart';
import 'package:assign_erp/features/procurement/data/model/pro_purchase_order_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
/*import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';*/

extension PRDetails on BuildContext {
  Future openPODetails({
    required Employee employee,
    required ProPurchaseOrder po,
    required Function(bool) onPrint,
    required Supplier supplier,
    // required ProPurchaseOrderBloc bloc,
  }) async => await openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetailMode: true,
      title: 'Purchase Order (${po.lineItems.first.getType})',
      subtitle: po.poNumber.toUpperAll,
      secondaryWidget: _showHistory(po),
      body: _POInfoPage(
        order: po,
        supplier: supplier,
        buyerContactPerson: employee.fullName,
      ),
      onPrint: () async => await _printRFQ(employee, po, onPrint),
    ),
  );

  _printRFQ(
    Employee employee,
    ProPurchaseOrder po,
    Function(bool) onPrint,
  ) async {
    await progressBarDialog(
      request: Future.delayed(kRProgressDelay, () async {
        // await PRPrinter(po: po, employee: employee).printPO();
        onPrint(true);
      }),
      onSuccess: (_) => showAlertOverlay('PO printout successful'),
      onError: (e) =>
          showAlertOverlay('PO printout failed', bgColor: kDangerColor),
    );
  }

  Widget _showHistory(ProPurchaseOrder? po) {
    return iconButton(
      Icons.history,
      iconColor: kPrimaryAccentColor,
      bgColor: kPrimaryAccentColor.toAlpha(0.1),
      borderColor: kPrimaryAccentColor.toAlpha(0.3),
      tooltip: 'View PO History',
      onPressed: () async => await _onOpenHistory(po),
    );
  }

  Future<void> _onOpenHistory(ProPurchaseOrder? po) async {
    if (po == null) return;

    await showHistoryBottomSheet<AuditLog>(
      title: 'Workflow History',
      columnLabels: AuditLog.dataTableHeader,
      items: po.history, // list of SQ history
      rowBuilder: (entry) {
        return DataRow(
          cells: entry.itemAsList.map((cell) => DataCell(Text(cell))).toList(),
        );
      },
    );
  }
}

class _POInfoPage extends StatelessWidget {
  final String buyerContactPerson;
  final ProPurchaseOrder order;
  final Supplier supplier;

  const _POInfoPage({
    required this.order,
    required this.supplier,
    required this.buyerContactPerson,
  });

  List<LineItem> get _items => order.lineItems;

  bool get _isPerLineTax => order.taxMode.isPerLineTax;

  String? get _currencySign => getCurrencySign(order.currencyCode);

  List<SummaryItem> get _leftSummaryItems => [
    (title: 'Currency', value: '${order.currencyCode} ($_currencySign)'),
    (title: 'Delivery Date', value: order.getDeliveryDate),
    (title: 'Contact Person', value: buyerContactPerson.toTitle),
    // If Tax Mode is not Per Line, add Tax Details here
    if (!_isPerLineTax) ...{
      (
        title: 'Applied Taxes',
        value: order.lineItems.first.taxNames.toUpperAll,
      ),
    },
  ];

  List<SummaryItem> get _rightSummaryItems => [
    (title: 'Subtotal', value: '$_currencySign${order.subTotal.toCurrency}'),
    (
      title: 'Discount',
      value: '- $_currencySign${order.totalDiscountAmount.toCurrency}',
    ),
    (title: 'Tax %', value: '${order.totalTaxPercent.toPercent}%'),
    (title: 'Net Total', value: '$_currencySign${order.netTotal.toCurrency}'),
    if (order.shippingTaxAmount > 0) ...[
      (
        title: 'Shipping',
        value: '$_currencySign${order.shippingAmount.toCurrency}',
      ),
      (
        title: 'Shipping Tax',
        value: '$_currencySign${order.shippingTaxAmount.toCurrency}',
      ),
    ],
    (
      title: 'Grand Total',
      value: '$_currencySign${order.grandTotal.toCurrency}',
    ),
  ];

  List<SummaryItem> get _headerItems => [
    (title: 'PO#', value: order.poNumber),
    (title: 'Store ID', value: order.storeNumber.toUpperAll),
    (title: 'Status', value: order.status.getLabel.toSentence),
    (title: 'Payment Terms', value: order.paymentTerm.toTitle),
    (title: 'Payment Method', value: order.paymentMethod.toTitle),
    (title: 'Supplier', value: supplier.name.toTitle),
  ];

  List<SummaryItem> get _supplierInfo => [
    (title: 'Supplier Address', value: supplier.address.toSentence),
    (title: 'Phone', value: supplier.phone),
    (title: 'Email', value: supplier.email ?? 'N/A'),
  ];

  List<SummaryItem> get _otherItems => [
    (
      title: 'Terms',
      value: order.termsAndConditions.isNullOrEmpty
          ? 'N/A'
          : order.termsAndConditions.toSentence,
    ),
    (
      title: 'Additional Notes',
      value: order.notes.isNullOrEmpty ? 'N/A' : order.notes.toSentence,
    ),
  ];

  SummaryItem get _approval {
    ApprovalInfo? item = order.getApproval;

    return (
      title: 'Approved By',
      value:
          '\n${item.by ?? 'Not yet approved'}\n${item.at ?? '-----------------'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBody(context),
        DetailsFooter(
          created: (by: order.createdBy, at: order.getCreatedAt),
          updated: (by: order.updatedBy, at: order.getUpdatedAt),
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
          // headingRowColor: context.primaryContainer,
          columnLabels: _items.first.dataTableHeader(_isPerLineTax),
          items: _items,
          // list of POs
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
          children: [
            DetailsSummary(
              alignment: Alignment.topLeft,
              items: _leftSummaryItems,
            ),
            DetailsSummary(
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
        const SizedBox(height: 12),
        _addressesAndNotes(context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DetailsSummary(items: _headerItems, alignment: Alignment.topLeft);
  }

  Widget _addressesAndNotes(BuildContext context) {
    return AdaptiveLayout(
      children: [
        if (order.addresses.isNotNullNorEmpty) ...{
          ...?order.addresses?.map((a) {
            return detailsRow(
              context,
              separator: '\n',
              isReadMore: true,
              title: 'Buyer\'s ${a.getType} address:'.toTitle,
              value: a.address.toSentence,
            );
          }),
        },
        DetailsSummary(
          isAlign: false,
          isReadMore: true,
          items: _supplierInfo,
          alignment: Alignment.topLeft,
        ),

        ..._otherItems.map((a) {
          return detailsRow(
            context,
            separator: '\n',
            isReadMore: true,
            title: a.title,
            value: a.value,
          );
        }),
      ],
    );
  }
}
