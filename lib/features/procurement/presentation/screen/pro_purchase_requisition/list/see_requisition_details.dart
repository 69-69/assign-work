import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/erp_priority_enum.dart';
import 'package:assign_erp/core/constants/workflow_status.dart';
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
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_requisition/widget/pr_printer.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
/*import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';*/

extension PRDetails on BuildContext {
  Future openPRDetails({
    required Employee employee,
    required ProcurementBloc bloc,
    required PurchaseRequisition requisite,
  }) async => await openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetails: true,
      title: 'Purchase Requisition (${requisite.lineItems.first.getTypeLabel})',
      subtitle: requisite.prNumber.toUpperAll,
      body: _PRInfoPage(requisite: requisite, employee: employee.fullName),
      onPrint: () async => await _printRFQ(requisite, bloc, employee),
    ),
  );

  _printRFQ(
    PurchaseRequisition requisite,
    ProcurementBloc bloc,
    Employee employee,
  ) async {
    await progressBarDialog(
      request: Future.delayed(kRProgressDelay, () async {
        await PRPrinter(requisite: requisite, employee: employee).printPR();
        bloc.add(_updateHistory(requisite));
      }),
      onSuccess: (_) => showAlertOverlay('PR printout successful'),
      onError: (e) =>
          showAlertOverlay('PR printout failed', bgColor: kDangerColor),
    );
  }

  /// Audit Log Entry (Tracking actions)
  AuditProcurement<PurchaseRequisition> _updateHistory(
    PurchaseRequisition requisite,
  ) {
    return AuditProcurement<PurchaseRequisition>(
      documentId: requisite.id,
      log: AuditLog.logScaffold(
        oldLogs: requisite.history,
        newLog: AuditLog(
          action: AuditAction.printed,
          actionBy: employee!.employeeId,
          statusAfterAction: requisite.getPRStatus,
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

  @override
  Widget build(BuildContext context) {
    if (_requisite == null) {
      return const Center(child: Text("PR not available."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBody(context),
        _Footer(requisite: _requisite),
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
          items: _items, // list of requisitions
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
            _LeftSummary(requisite: _requisite, textColor: _textColor),
            _RightSummary(requisite: _requisite, textColor: _textColor),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Build the list of header entries first
    final headerItems = <(String, String)>[
      ('PR#', _requisite?.prNumber ?? 'N/A'),
      ('Store ID', _requisite?.storeNumber.toUpperAll ?? 'N/A'),
      ('Status', _requisite?.status.getLabel.toSentence ?? 'N/A'),
      ('Priority', _requisite?.priority.getName.toTitle ?? 'N/A'),
      ('Department', _requisite!.departmentCode.toTitle),
      ('Request By', _requestBy.toTitle),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Text('Purchase Requisition', style: context.textTheme.headlineSmall),
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
      tooltip: 'View PR History',
      label: Text(
        'PR History',
        style: const TextStyle(color: kPrimaryAccentColor),
      ),
    );
  }

  Future<void> _onOpenHistory(BuildContext cxt) async {
    if (_requisite == null) return;

    await cxt.showInlineHistorySheet<AuditLog>(
      title: 'Workflow History',
      columnLabels: AuditLog.dataTableHeader,
      items: _requisite.history, // list of PR history
      rowBuilder: (entry) {
        return DataRow(
          cells: entry.itemAsList.map((cell) => DataCell(Text(cell))).toList(),
        );
      },
    );
  }
}

class _LeftSummary extends StatelessWidget {
  final PurchaseRequisition? requisite;
  final Color? textColor;

  const _LeftSummary({this.requisite, required this.textColor});

  get _summaryItems => <(String, String)>[
    ('Request Date', '${requisite?.getRequestDate}'),
    ('Expected Date', '${requisite?.getExpectedDate}'),
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
            title: 'Purpose / Reason:',
            value: requisite!.purpose.toSentence,
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
  final PurchaseRequisition? requisite;
  final Color? textColor;

  const _RightSummary({this.requisite, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return _buildRightSummary(context);
  }

  Widget _buildRightSummary(BuildContext context) {
    final history = _prHistory(requisite!);

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
  (String?, String?) _prHistory(PurchaseRequisition? req) {
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
  final PurchaseRequisition? requisite;

  const _Footer({this.requisite});

  String? get _updatedBy =>
      requisite!.updatedBy.isNullOrEmpty ? 'N/A' : requisite?.updatedBy;

  String? get _createdBy =>
      requisite!.createdBy.isNullOrEmpty ? 'N/A' : requisite?.createdBy;

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
                  '${requisite?.getCreatedAt} - By: [ ${_createdBy.toTitle} ]',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _buildInfoRow(
              context,
              title: 'Updated',
              value:
                  '${requisite!.getUpdatedAt} - By: [ ${_updatedBy.toTitle} ]',
            ),
          ),
        ],
      ),
    );
  }
}
