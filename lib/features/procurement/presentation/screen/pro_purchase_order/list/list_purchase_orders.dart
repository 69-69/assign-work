import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/data/data_sources/remote/get_suppliers.dart';
import 'package:assign_erp/features/procurement/data/model/pro_purchase_order_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_po/pro_purchase_order_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/create/create_purchase_order.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/list/see_po_details.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/update/update_purchase_order.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/widget/po_form_inputs.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_employees.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
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
  bool _inProgress = false;
  final List<String> _selectedIds = [];

  bool get _isApproved => widget.isApproved;

  ProPurchaseOrderBloc get _bloc => context.read<ProPurchaseOrderBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
  }

  void _handleBlocState(
    BuildContext cxt,
    ProcurementState<ProPurchaseOrder> state,
  ) {
    switch (state) {
      case ProcurementDeleted<ProPurchaseOrder>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case ProcurementError<ProPurchaseOrder>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      ProPurchaseOrderBloc,
      ProcurementState<ProPurchaseOrder>
    >(listener: _handleBlocState, child: _buildBody());
  }

  BlocBuilder<ProPurchaseOrderBloc, ProcurementState<ProPurchaseOrder>>
  _buildBody() {
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
          _ => const SizedBox.shrink(),
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
    // Filter for Purchase orders by date
    final data = _filterPurchaseOrders(orders);

    return DynamicDataTable(
      omitAtIndex: 0,
      toolbar: _buildToolbar(orders),
      headers: ProPurchaseOrder.dataTableHeader,
      rows: data.rows,
      onViewDetailsTap: (row) async => _onViewDetails(orders, row.first),
      selectedRowKeyIndex: 0,
      selectedRowKeys: _selectedIds,
      onChecked: _onChecked,
      onAllChecked: _onAllChecked,
      optButtonLabel: 'Print',
      onOptButtonTap: (row) async => await _onPrintPO(orders, row.first),
      onEditTap: (row) async => await _onEditTap(orders, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(orders, row.first),
    );
  }

  _onChecked(bool? isChecked, checkedRow) {
    setState(() {
      final id = checkedRow.first;
      if (isChecked == true) {
        if (!_selectedIds.contains(id)) _selectedIds.add(id);
      } else {
        // Remove item from the selected list if unchecked
        _selectedIds.removeWhere((selectedId) => selectedId == id);
      }
    });
  }

  _onAllChecked(
    bool isChecked,
    List<bool> isAllChecked,
    List<List<String>> checkedRows,
  ) {
    setState(() {
      _selectedIds.clear();
      // Add all selected rows, ensuring uniqueness using a Set
      if (isChecked) {
        _selectedIds.addAll(checkedRows.map((e) => e.first).toSet());
      }
    });
  }

  Widget _buildToolbar(List<ProPurchaseOrder> orders) {
    return ListToolbarButtons(
      primaryLabel: 'Create PO',
      dataLength: orders.length,
      secondaryLabel: 'Edit PO',
      secondaryIcon: Icons.edit,
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete PO',
      refreshLabel: '${_isApproved ? 'Approved' : 'Purchase'} Orders',
      onPrimary: () async => await context.openPOForm(),
      onRefresh: () => _bloc.add(RefreshProcurements<ProPurchaseOrder>()),
      onSecondary: _selectedIds.length == 1
          ? () async => _onEditTap(orders, _selectedIds.first)
          : null,
      onDanger: _selectedIds.isNotEmpty
          ? () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (mounted && isConfirmed) {
                _isDeleting(true);
                _bloc.add(
                  DeleteProcurement<List<String>>(documentId: _selectedIds),
                );
              }
            }
          : null,
    );
  }

  ProPurchaseOrder? _getPOById(List<ProPurchaseOrder> orders, String id) {
    final po = ProPurchaseOrder.findPOById(orders, id);
    return po.isEmpty ? null : po;
  }

  Future<Supplier?> _getSupplier(String supplierId) async {
    final supplier = await GetSuppliers.bySupplierId(supplierId);
    return supplier.isEmpty ? null : supplier;
  }

  Future _getEmployee(String empId) async {
    final employee = await GetEmployees.byEmployeeId(empId);
    return employee.isEmpty ? null : employee;
  }

  Future<void> _onViewDetails(List<ProPurchaseOrder> orders, String id) async {
    await _withPOSupplierLink(
      id,
      orders,
      auditAction: AuditAction.viewed,
      onPOProcessed: (po, supplier, employee) async {
        // User opens PO details screen
        return await context.openPODetails(
          po: po,
          employee: employee,
          supplier: supplier,
          onPrint: (bool isPrinted) {
            if (isPrinted) _bloc.add(_updateHistory(po));
          },
        );
      },
    );
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
          _bloc.add(_updateHistory(po, action: AuditAction.printed));
        }
        // Perform action after loading
        await POPrinter(po: po, employee: employee).printPO();*/
      });

  Future<void> _onEditTap(List<ProPurchaseOrder> orders, String id) async {
    final po = _getPOById(orders, id);
    if (po == null) return;

    final poWithTaxes = await POFormInputs.applyTaxesToQuote(po); // Apply taxes
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

  /// Orchestrates an PO action that depends on supplier selection.
  /// [_withRFQSupplierLink]
  /// Resolves the PO by [id], applies taxes, logs the given [auditAction],
  /// and then:
  /// - Executes [onPOProcessed] if exactly one supplier is linked to the PO.
  ///
  /// Safely guards against invalid state (unmounted widget, missing RFQ,
  /// or empty supplier links) and rechecks [mounted] after async gaps.
  Future<void> _withPOSupplierLink(
    String id,
    List<ProPurchaseOrder> orders, {
    bool shouldProcessSupplierInfo = true,
    required AuditAction auditAction,
    required Future<void> Function(
      ProPurchaseOrder rfqWithTaxes,
      Supplier supplier,
      Employee employee,
    )
    onPOProcessed,
  }) async {
    final po = _getPOById(orders, id);
    if (!mounted || po == null || po.supplierLink.isEmpty) return;

    final poWithTaxes = await POFormInputs.applyTaxesToQuote(po);
    if (!mounted) return;

    final supplierLink = po.supplierLink;

    _bloc.add(_updateHistory(po, action: auditAction));

    if (!shouldProcessSupplierInfo) {
      return onPOProcessed(poWithTaxes, Supplier.empty, Employee.empty);
    }

    final employee = await _getEmployee(po.buyerContactPersonId);

    // Single supplier
    final supplier = await _getSupplier(supplierLink.supplierId);
    if (!mounted || supplier == null) return;

    await onPOProcessed(poWithTaxes, supplier, employee);
  }
}
