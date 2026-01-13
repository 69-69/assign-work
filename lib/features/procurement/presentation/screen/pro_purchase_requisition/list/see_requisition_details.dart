import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/extensions/erp_priority_enum.dart';
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
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_requisition/widget/pr_printer.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
/*import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';*/

extension PRDetails on BuildContext {
  Future openPRDetails({
    required Employee employee,
    required Function(bool) onPrint,
    required PurchaseRequisition requisite,
    // required ProPurchaseRequisiteBloc bloc,
  }) async => await openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetailMode: true,
      title: 'Purchase Requisition (${requisite.lineItems.first.getType})',
      subtitle: requisite.prNumber.toUpperAll,
      secondaryWidget: _showHistory(requisite),
      body: _PRInfoPage(requisite: requisite, employee: employee.fullName),
      onPrint: () async => await _printRFQ(requisite, onPrint, employee),
    ),
  );

  _printRFQ(
    PurchaseRequisition requisite,
    Function(bool) onPrint,
    Employee employee,
    // ProPurchaseRequisiteBloc bloc,
  ) async {
    await progressBarDialog(
      request: Future.delayed(kRProgressDelay, () async {
        await PRPrinter(requisite: requisite, employee: employee).printPR();
        // bloc.add(_updateHistory(requisite));
        onPrint(true);
      }),
      onSuccess: (_) => showAlertOverlay('PR printout successful'),
      onError: (e) =>
          showAlertOverlay('PR printout failed', bgColor: kDangerColor),
    );
  }

  Widget _showHistory(PurchaseRequisition? pr) {
    return iconButton(
      Icons.history,
      iconColor: kPrimaryAccentColor,
      bgColor: kPrimaryAccentColor.toAlpha(0.1),
      borderColor: kPrimaryAccentColor.toAlpha(0.3),
      tooltip: 'View PR History',
      onPressed: () async => await _onOpenHistory(pr),
    );
  }

  Future<void> _onOpenHistory(PurchaseRequisition? pr) async {
    if (pr == null) return;

    await showHistoryBottomSheet<AuditLog>(
      title: 'Workflow History',
      columnLabels: AuditLog.dataTableHeader,
      items: pr.history, // list of PR history
      rowBuilder: (entry) {
        return DataRow(
          cells: entry.itemAsList.map((cell) => DataCell(Text(cell))).toList(),
        );
      },
    );
  }
}

class _PRInfoPage extends StatelessWidget {
  final String _requestBy;
  final PurchaseRequisition? _requisite;
  final Color? _textColor;

  const _PRInfoPage({
    PurchaseRequisition? requisite,
    String employee = '',
    Color? textColor,
  }) : _requisite = requisite,
       _requestBy = employee,
       _textColor = textColor;

  List<LineItem> get _items => _requisite?.lineItems ?? [];

  SummaryItem get _approval {
    ApprovalInfo? item = _requisite?.getApproval;

    return (
      title: 'Approved By',
      value:
          '\n${item?.by ?? 'Not yet approved'}\n${item?.at ?? '-----------------'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_requisite == null) {
      return const Center(child: Text("PR not available."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBody(context),
        DetailsFooter(
          created: (by: _requisite.createdBy, at: _requisite.getCreatedAt),
          updated: (by: _requisite.updatedBy, at: _requisite.getUpdatedAt),
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
        SortableHistoryTable<LineItem>(
          title: 'Line Items (${_items.length})',
          // headingRowColor: context.primaryContainer,
          columnLabels: _items.first.dataTableHeader(false),
          items: _items,
          // list of requisitions
          rowBuilder: (entry) {
            return DataRow(
              cells: entry
                  .itemAsList(false)
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
              textColor: _textColor,
              alignment: Alignment.topLeft,
              items: [
                (title: 'Request Date', value: '${_requisite?.getRequestDate}'),
                (
                  title: 'Expected Date',
                  value: '${_requisite?.getExpectedDate}',
                ),
              ],
              anyWidget: detailsRow(
                context,
                isReadMore: true,
                title: 'Purpose / Reason',
                textColor: _textColor,
                value: _requisite!.purpose.toSentence,
              ),
            ),
            DetailsSummary(textColor: kDangerColor, items: [_approval]),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Build the list of header entries first
    List<SummaryItem> headerItems = [
      (title: 'PR#', value: _requisite?.prNumber ?? 'N/A'),
      (title: 'Store ID', value: _requisite?.storeNumber.toUpperAll ?? 'N/A'),
      (title: 'Status', value: _requisite?.status.getLabel.toSentence ?? 'N/A'),
      (title: 'Priority', value: _requisite?.priority.getName.toTitle ?? 'N/A'),
      (title: 'Department', value: _requisite!.departmentCode.toTitle),
      (title: 'Request By', value: _requestBy.toTitle),
    ];

    return DetailsSummary(
      textColor: _textColor,
      items: headerItems,
      alignment: Alignment.topLeft,
    );
  }
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
