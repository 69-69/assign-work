import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/data/model/pro_purchase_order_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_po/pro_purchase_order_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/create/create_purchase_order.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/update/update_purchase_order.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_employees.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_taxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// LIST Purchase Orders [ListPurchaseOrders]
class ListPurchaseOrders extends StatefulWidget {
  final bool isApproved;

  const ListPurchaseOrders({super.key, this.isApproved = false});

  @override
  State<ListPurchaseOrders> createState() => _ListPurchaseOrdersState();
}

class _ListPurchaseOrdersState extends State<ListPurchaseOrders> {
  // List to group Purchase Orders for printout
  final List<String> _selectedIds = [];

  bool get _isApproved => widget.isApproved;

  ProPurchaseOrderBloc get _bloc => context.read<ProPurchaseOrderBloc>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      ProPurchaseOrderBloc,
      ProcurementState<ProPurchaseOrder>
    >(
      builder: (context, state) {
        return switch (state) {
          LoadingProcurement<ProPurchaseOrder>() => context.loader,
          ProcurementsLoaded<ProPurchaseOrder>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Purchase Order',
                    onPressed: () async => await context.openPOForm(),
                  )
                : _buildCard(context, results),
          ProcurementError<ProPurchaseOrder>(error: final error) =>
            context.buildError(error),
          _ => const SizedBox.shrink(), // Handle other states if needed
        };
      },
    );
  }

  ({List<List<String>> rows, List<List<String>>? childrenRow})
  _filterPurchaseOrders(List<ProPurchaseOrder> orders) {
    if (_isApproved) {
      final approvedPOs = ProPurchaseOrder.filterApprovedPOs(
        orders,
      ).map((o) => o.itemAsList).toList();
      return (rows: approvedPOs, childrenRow: null);
    }

    final otherPOs = ProPurchaseOrder.filterOthers(
      orders,
    ).map((o) => o.itemAsList).toList();

    return (rows: otherPOs, childrenRow: null);
  }

  Widget _buildCard(BuildContext context, List<ProPurchaseOrder> orders) {
    prettyPrint('results', orders.first.addresses);
    // Filter for Purchase orders by date
    final data = _filterPurchaseOrders(orders);

    return DynamicDataTable(
      omitAtIndex: 0,
      toolbar: _buildToolbar(orders),
      headers: ProPurchaseOrder.dataTableHeader,
      rows: data.rows,
      onViewDetailsTap: (row) async => _onViewDetails(orders, row.first),
      selectedRowKeyIndex: 0,
      // Column index used as row key (e.g., ID)
      selectedRowKeys: _selectedIds,
      // Currently selected row keys
      onChecked: (bool? isChecked, checkedRow) {
        setState(() => _updateSelectedIds(isChecked, checkedRow.first, orders));
      },
      onAllChecked:
          (
            bool isChecked,
            List<bool> isAllChecked,
            List<List<String>> checkedRows,
          ) {
            setState(
              () => _updateAllSelectedIds(isChecked, checkedRows, orders),
            );
          },
      optButtonLabel: 'Print',
      onOptButtonTap: (row) async => await _onPrintPO(orders, row.first),
      onEditTap: (row) async => await _onEditTap(orders, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(orders, row.first),
    );
  }

  // Updates selected IDs and triggers additional logic (like selecting POs)
  void _updateSelectedIds(
    bool? isChecked,
    String id,
    List<ProPurchaseOrder> orders,
  ) {
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
  void _updateAllSelectedIds(
    bool isChecked,
    List<List<String>> checkedRows,
    List<ProPurchaseOrder> orders,
  ) {
    _selectedIds.clear();
    if (isChecked) {
      // Add all selected rows, ensuring uniqueness using a Set
      _selectedIds.addAll(checkedRows.map((e) => e.first).toSet());
    }
  }

  _buildToolbar(List<ProPurchaseOrder> orders) {
    return AdaptiveLayout(
      isFormBuilder: false,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        context.actionInfoButton(
          'Refresh ${_isApproved ? 'Approved' : 'Purchase'} Orders',
          label: 'Purchase Orders',
          count: orders.length,
          // Dispatch an event to refresh data
          onPressed: () {
            // Refresh Purchase orders Data
            _bloc.add(RefreshProcurements<ProPurchaseOrder>());
          },
        ),
        const SizedBox(width: 20),
        context.elevatedButton(
          'Create PO',
          onPressed: () async => await context.openPOForm(),
          bgColor: kDangerColor,
          txtColor: kWhiteColor,
        ),

        if (_selectedIds.length > 1) ...[
          const SizedBox(width: 20),
          context.elevatedButton(
            'Delete',
            txtColor: kWhiteColor,
            bgColor: kDangerColor,
            tooltip: 'Delete selected PO',
            onPressed: () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (mounted && isConfirmed) {
                /// Delete all selected Purchase Orders from DB
                _bloc.add(
                  DeleteProcurement<List<String>>(documentId: _selectedIds),
                );
                _selectedIds.clear();
              }
            },
          ),
        ],
      ],
    );
  }

  ProPurchaseOrder? _getPOById(List<ProPurchaseOrder> orders, String id) {
    final po = ProPurchaseOrder.findPOById(orders, id);
    return po.isEmpty ? null : po;
  }

  Future<ProPurchaseOrder> _applyTaxesToSQ(ProPurchaseOrder po) async {
    final taxMap = await GetTaxes.loadAllTaxRates();
    return po.computeTaxAmounts(taxMap);
  }

  Future _getEmployee(String empId) async {
    final employee = await GetEmployees.byEmployeeId(empId);
    return employee.isEmpty ? null : employee;
  }

  Future<void> _onViewDetails(List<ProPurchaseOrder> orders, String id) async {
    final po = _getPOById(orders, id);
    if (po == null) return;

    final employee = await _getEmployee(po.requestedBy);

    if (mounted) {
      // Log that User viewed details
      if (AuditTracker.shouldLog(id: po.id, type: DocType.rfq)) {
        _bloc.add(_updateHistory(po, action: AuditAction.viewed));
      }

      // User opens PO details screen
      // await context.openPODetails(po: po, employee: employee, bloc: _readBloc);
    }
  }

  Future<void> _onPrintPO(List<ProPurchaseOrder> orders, String id) async {
    // Show progress dialog while loading data
    await context.progressBarDialog(
      request: _printout(orders, id),
      onSuccess: (_) => context.showAlertOverlay('PO Printout successful'),
      onError: (error) =>
          context.showAlertOverlay('PO printout failed', bgColor: kDangerColor),
    );
  }

  Future<dynamic> _printout(List<ProPurchaseOrder> orders, String id) =>
      Future.delayed(kRProgressDelay, () async {
        final po = _getPOById(orders, id);
        if (po == null) return;

        /*final employee = await _getEmployee(po.requestedBy);
        if (employee == null) return;

        if (mounted) {
          _readBloc.add(_updateHistory(po, action: AuditAction.printed));
        }
        // Perform action after loading
        await POPrinter(po: po, employee: employee).printPO();*/
      });

  Future<void> _onEditTap(List<ProPurchaseOrder> orders, String id) async {
    final po = _getPOById(orders, id);
    if (po == null) return;

    final poWithTaxes = await _applyTaxesToSQ(po); // Apply taxes
    if (!mounted) return;

    await context.openUpdatePOForm(serverPO: poWithTaxes);
  }

  Future<void> _onDeleteTap(List<ProPurchaseOrder> orders, String id) async {
    final po = _getPOById(orders, id);
    if (po == null) return;

    final isConfirmed = await context.confirmUserActionDialog();

    if (mounted && isConfirmed) {
      _bloc
        ..add(_updateHistory(po))
        ..add(DeleteProcurement<String>(documentId: po.id));
    }
  }

  /// Audit Log Entry (Tracking actions)
  AuditProcurement<ProPurchaseOrder> _updateHistory(
    ProPurchaseOrder po, {
    AuditAction action = AuditAction.deleted,
  }) {
    return AuditProcurement<ProPurchaseOrder>(
      documentId: po.id,
      log: AuditLog.logScaffold(
        oldLogs: po.history,
        newLog: AuditLog(
          action: action,
          actionBy: context.employee!.employeeId,
          statusAfterAction: po.getPOStatus,
        ),
      ),
    );
  }
}
