import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/warehouse_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/warehouse_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/warehouse/create/create_warehouse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListWarehouses extends StatefulWidget {
  const ListWarehouses({super.key});

  @override
  State<ListWarehouses> createState() => _ListWarehousesState();
}

class _ListWarehousesState extends State<ListWarehouses> {
  bool _inProgress = false;
  final List<String> _selectedIds = [];

  WarehouseBloc get _bloc => context.read<WarehouseBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
  }

  void _handleBlocState(BuildContext cxt, InventoryState<Warehouse> state) {
    switch (state) {
      case InventoryDeleted<Warehouse>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case InventoryError<Warehouse>():
        _showAlert('Error saving changes');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WarehouseBloc, InventoryState<Warehouse>>(
      listener: _handleBlocState,
      child: _buildBody(),
    );
  }

  BlocBuilder<WarehouseBloc, InventoryState<Warehouse>> _buildBody() {
    return BlocBuilder<WarehouseBloc, InventoryState<Warehouse>>(
      builder: (context, state) {
        return switch (state) {
          LoadingInventory<Warehouse>() => context.loader,
          InventoriesLoaded<Warehouse>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Warehouse',
                    onPressed: () => _openWarehouseForm(),
                  )
                : _buildCard(context, results),
          InventoryError<Warehouse>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<Warehouse> warehouses) {
    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: Warehouse.dataTableHeader,
      toolbar: _buildToolbar(warehouses),
      rows: warehouses.map((d) => d.itemAsList).toList(),
      selectedRowKeys: _selectedIds,
      onChecked: _onChecked,
      onAllChecked: _onAllChecked,
      onEditTap: (row) async => await _onEditTap(warehouses, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(warehouses, row.first),
    );
  }

  Widget _buildToolbar(List<Warehouse> warehouses) {
    return ListToolbarButtons(
      dataLength: warehouses.length,
      primaryLabel: 'Create Warehouse',
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete Warehouse',
      refreshLabel: 'Refresh Warehouses',
      onPrimary: () => _openWarehouseForm(warehouses: warehouses),
      onRefresh: () => _bloc.add(RefreshInventories<Warehouse>()),
      onDanger: _selectedIds.isNotEmpty
          ? () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (mounted && isConfirmed) {
                _isDeleting(true);
                _bloc.add(
                  DeleteInventory<List<String>>(documentId: _selectedIds),
                );
              }
            }
          : null,
    );
  }

  Future<void> _onEditTap(List<Warehouse> warehouses, String id) async {
    final warehouse = Warehouse.findById(warehouses, id);
    if (warehouse == null) return;

    await _openWarehouseForm(warehouses: warehouses, serverWare: warehouse);
  }

  Future<void> _onDeleteTap(List<Warehouse> warehouses, String id) async {
    final warehouse = Warehouse.findById(warehouses, id);
    if (warehouse == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      _bloc.add(DeleteInventory<String>(documentId: warehouse.id));
    }
  }

  Future<void> _openWarehouseForm({
    Warehouse? serverWare,
    List<Warehouse>? warehouses,
  }) async {
    List<String>? existingCodes = Warehouse.getCodes(warehouses ?? []);
    await context.openWarehouseForm(
      serverItem: serverWare,
      existingCodes: existingCodes,
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
}
