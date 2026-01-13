import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/material_or_service_choice.dart';
import 'package:assign_erp/core/widgets/nav/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_requisition/pro_purchase_requisite_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_requisition/create/create_purchase_requisition.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_requisition/list/see_requisition_details.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_requisition/update/update_purchase_requisition.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_requisition/widget/pr_printer.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_employees.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// LIST Purchase Requisitions
class ListPurchaseRequisitions extends StatefulWidget {
  final bool isApproved;

  const ListPurchaseRequisitions({super.key, this.isApproved = false});

  @override
  State<ListPurchaseRequisitions> createState() =>
      _ListPurchaseRequisitionsState();
}

class _ListPurchaseRequisitionsState extends State<ListPurchaseRequisitions> {
  // List to group Requisitions for printout
  final List<String> _selectedIds = [];

  bool get _isApproved => widget.isApproved;

  ProPurchaseRequisiteBloc get _bloc =>
      context.read<ProPurchaseRequisiteBloc>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      ProPurchaseRequisiteBloc,
      ProcurementState<PurchaseRequisition>
    >(
      builder: (context, state) {
        return switch (state) {
          LoadingProcurement<PurchaseRequisition>() => context.loader,
          ProcurementsLoaded<PurchaseRequisition>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Purchase Requisition',
                    onPressed: () async => await _openCreatePR(context),
                  )
                : _buildCard(context, results),
          ProcurementError<PurchaseRequisition>(error: final error) =>
            context.buildError(error),
          _ => const SizedBox.shrink(), // Handle other states if needed
        };
      },
    );
  }

  Future<void> _openCreatePR(BuildContext cxt) async {
    final lineItemType = await cxt.openMaterialOrServiceToggle('PR');
    if (cxt.mounted && '$lineItemType'.hasValue) {
      await cxt.openCreatePurchaseRequisite(
        lineType: lineItemType,
        onBackPress: () async {
          Navigator.pop(cxt);

          if (cxt.mounted && '$lineItemType'.hasValue) {
            await _openCreatePR(cxt);
          }
        },
      );
    }
  }

  ({List<List<String>> rows, List<List<String>>? childrenRow})
  _filterRequisitions(List<PurchaseRequisition> requisitions) {
    if (_isApproved) {
      final approvedPRs = PurchaseRequisition.filterApprovedPR(
        requisitions,
      ).map((o) => o.itemAsList).toList();
      return (rows: approvedPRs, childrenRow: null);
    }

    final otherPRs = PurchaseRequisition.filterOthers(
      requisitions,
    ).map((o) => o.itemAsList).toList();

    return (rows: otherPRs, childrenRow: null);
  }

  Widget _buildCard(
    BuildContext context,
    List<PurchaseRequisition> requisitions,
  ) {
    // Filter for Purchase Requisitions by date
    final data = _filterRequisitions(requisitions);

    return DynamicDataTable(
      omitAtIndex: 0,
      toolbar: _buildToolbar(requisitions),
      headers: PurchaseRequisition.dataTableHeader,
      rows: data.rows,
      onViewDetailsTap: (row) async => _onViewDetails(requisitions, row.first),
      selectedRowKeyIndex: 0,
      // Column index used as row key (e.g., ID)
      selectedRowKeys: _selectedIds,
      // Currently selected row keys
      onChecked: (bool? isChecked, checkedRow) {
        setState(() => _updateSelectedIds(isChecked, checkedRow.first));
      },
      onAllChecked:
          (
            bool isChecked,
            List<bool> isAllChecked,
            List<List<String>> checkedRows,
          ) {
            setState(() => _updateAllSelectedIds(isChecked, checkedRows));
          },
      optButtonLabel: 'Print',
      onOptButtonTap: (row) async => await _onPrintPR(requisitions, row.first),
      onEditTap: (row) async => await _onEditTap(requisitions, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(requisitions, row.first),
    );
  }

  // Updates selected IDs and triggers additional logic (like selecting PRs)
  void _updateSelectedIds(bool? isChecked, String id) {
    if (isChecked == true) {
      if (!_selectedIds.contains(id)) {
        _selectedIds.add(id);
      }
    } else {
      // Remove item from the selected list if unchecked
      _selectedIds.removeWhere((selectedId) => selectedId == id);
    }
  }

  // Updates selected IDs for all checked rows
  void _updateAllSelectedIds(bool isChecked, List<List<String>> checkedRows) {
    _selectedIds.clear();
    if (isChecked) {
      // Add all selected rows, ensuring uniqueness using a Set
      _selectedIds.addAll(checkedRows.map((e) => e.first).toSet());
    }
  }

  _buildToolbar(List<PurchaseRequisition> requisitions) {
    return ListToolbarButtons(
      refreshLabel: 'Refresh PR',
      createLabel: 'Create PR',
      deleteLabel: 'PR',
      dataLength: requisitions.length,
      onCreate: () async => await _openCreatePR(context),
      onRefresh: () => _bloc.add(RefreshProcurements<PurchaseRequisition>()),
      onDelete: _selectedIds.isNotEmpty
          ? () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (mounted && isConfirmed) {
                _bloc.add(
                  DeleteProcurement<List<String>>(documentId: _selectedIds),
                );
                _selectedIds.clear();
              }
            }
          : null,
    );
  }

  PurchaseRequisition? _getRequisiteById(
    List<PurchaseRequisition> requisites,
    String id,
  ) {
    final pr = PurchaseRequisition.findPRById(requisites, id);
    return pr.isEmpty ? null : pr;
  }

  Future _getEmployee(String empId) async {
    final employee = await GetEmployees.byEmployeeId(empId);
    return employee.isEmpty ? null : employee;
  }

  Future<void> _onViewDetails(
    List<PurchaseRequisition> requisites,
    String id,
  ) async {
    final requisite = _getRequisiteById(requisites, id);
    if (requisite == null) return;

    final employee = await _getEmployee(requisite.requestedBy);

    if (mounted) {
      // Log that User viewed details
      if (AuditTracker.shouldLog(id: requisite.id, type: DocType.rfq)) {
        _bloc.add(_updateHistory(requisite, action: AuditAction.viewed));
      }

      // User opens PR details screen
      await context.openPRDetails(
        requisite: requisite,
        employee: employee,
        onPrint: (bool isPrinted) {
          if (isPrinted) _bloc.add(_updateHistory(requisite));
        },
      );
    }
  }

  Future<void> _onPrintPR(
    List<PurchaseRequisition> requisites,
    String id,
  ) async {
    // Show progress dialog while loading data
    await context.progressBarDialog(
      request: _printout(requisites, id),
      onSuccess: (_) => context.showAlertOverlay('PR Printout successful'),
      onError: (error) =>
          context.showAlertOverlay('PR printout failed', bgColor: kDangerColor),
    );
  }

  Future<dynamic> _printout(List<PurchaseRequisition> requisites, String id) =>
      Future.delayed(kRProgressDelay, () async {
        final requisite = _getRequisiteById(requisites, id);
        if (requisite == null) return;

        final employee = await _getEmployee(requisite.requestedBy);
        if (employee == null) return;

        if (mounted) {
          _bloc.add(_updateHistory(requisite, action: AuditAction.printed));
        }
        // Perform action after loading
        await PRPrinter(requisite: requisite, employee: employee).printPR();
      });

  Future<void> _onEditTap(
    List<PurchaseRequisition> requisites,
    String id,
  ) async {
    final requisite = _getRequisiteById(requisites, id);
    if (requisite == null) return;

    await context.openUpdatePurchaseRequisite(requisite: requisite);
  }

  Future<void> _onDeleteTap(
    List<PurchaseRequisition> requisites,
    String id,
  ) async {
    final requisite = _getRequisiteById(requisites, id);
    if (requisite == null) return;

    final isConfirmed = await context.confirmUserActionDialog();

    if (mounted && isConfirmed) {
      final bloc = _bloc;

      bloc
        ..add(_updateHistory(requisite))
        ..add(DeleteProcurement<String>(documentId: requisite.id));
    }
  }

  /// Audit Log Entry (Tracking actions)
  AuditProcurement<PurchaseRequisition> _updateHistory(
    PurchaseRequisition requisite, {
    AuditAction action = AuditAction.deleted,
  }) {
    return AuditProcurement<PurchaseRequisition>(
      documentId: requisite.id,
      log: AuditLog.logScaffold(
        oldLogs: requisite.history,
        newLog: AuditLog(
          action: action,
          actionBy: context.employee!.employeeId,
          statusAfterAction: requisite.getPRStatus,
        ),
      ),
    );
  }
}
