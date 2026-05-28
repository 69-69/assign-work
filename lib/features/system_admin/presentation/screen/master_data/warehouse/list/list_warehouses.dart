import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/warehouse_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/warehouse_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/warehouse/create/create_warehouse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListWarehouses extends StatefulWidget {
  const ListWarehouses({super.key});

  @override
  State<ListWarehouses> createState() => _ListWarehousesState();
}

class _ListWarehousesState extends State<ListWarehouses> {
  bool _inProgress = false;
  List<String> _selectedIds = [];

  WarehouseBloc get _bloc => context.read<WarehouseBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) => context.showAlertOverlay(msg);

  void _handleBlocState(BuildContext cxt, SetupState<Warehouse> state) {
    switch (state) {
      case SetupDeleted<Warehouse>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case SetupError<Warehouse>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WarehouseBloc, SetupState<Warehouse>>(
      listener: _handleBlocState,
      child: _buildBody(),
    );
  }

  BlocBuilder<WarehouseBloc, SetupState<Warehouse>> _buildBody() {
    return BlocBuilder<WarehouseBloc, SetupState<Warehouse>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Warehouse>() => context.loader,
          SetupsLoaded<Warehouse>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'New Warehouse',
                    onPressed: () => _openWarehouseForm(),
                  )
                : _buildCard(context, results),
          SetupError<Warehouse>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<Warehouse> warehouses) {
    return DynamicDataTable2(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: Warehouse.dataTableHeader,
      toolbar: _buildToolbar(warehouses),
      rows: warehouses.map(_toTableRow).toList(),
      selectedRowKeys: _selectedIds,
      onSelectionChanged: (ids, rows) {
        setState(() => _selectedIds = ids);
      },
      onEditTap: (row) async => await _onEditTap(warehouses, row.id),
      onDeleteTap: (row) async => await _onDeleteTap(warehouses, row.id),
    );
  }

  DataTableRow _toTableRow(Warehouse e) =>
      DataTableRow.fromList(e.id, e.itemAsList);

  Widget _buildToolbar(List<Warehouse> warehouses) {
    return ListToolbarButtons(
      dataLength: warehouses.length,
      primaryLabel: 'New Warehouse',
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete',
      refreshLabel: 'Refresh',
      onPrimary: () => _openWarehouseForm(warehouses: warehouses),
      onRefresh: () => _bloc.add(RefreshSetups<Warehouse>()),
      onDanger: _selectedIds.isNotEmpty
          ? () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (mounted && isConfirmed) {
                _isDeleting(true);
                _bloc.add(DeleteSetup<List<String>>(documentId: _selectedIds));
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
      _bloc.add(DeleteSetup<String>(documentId: warehouse.id));
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
}
