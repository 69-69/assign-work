import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_bin_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/wh_bin_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_bin/create/create_wh_bin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListWHBins extends StatefulWidget {
  const ListWHBins({super.key});

  @override
  State<ListWHBins> createState() => _ListWHBinsState();
}

class _ListWHBinsState extends State<ListWHBins> {
  bool _inProgress = false;
  final List<String> _selectedIds = [];

  WHBinBloc get _bloc => context.read<WHBinBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
  }

  void _handleBlocState(BuildContext cxt, InventoryState<WHBin> state) {
    switch (state) {
      case InventoryDeleted<WHBin>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case InventoryError<WHBin>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WHBinBloc, InventoryState<WHBin>>(
      listener: _handleBlocState,
      child: _buildBody(),
    );
  }

  BlocBuilder<WHBinBloc, InventoryState<WHBin>> _buildBody() {
    return BlocBuilder<WHBinBloc, InventoryState<WHBin>>(
      builder: (context, state) {
        return switch (state) {
          LoadingInventory<WHBin>() => context.loader,
          InventoriesLoaded<WHBin>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Bin',
                    onPressed: () => _openWarehouseForm(),
                  )
                : _buildCard(context, results),
          InventoryError<WHBin>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<WHBin> bins) {
    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: WHBin.dataTableHeader,
      toolbar: _buildToolbar(bins),
      rows: bins.map((d) => d.itemAsList).toList(),
      selectedRowKeys: _selectedIds,
      onChecked: _onChecked,
      onAllChecked: _onAllChecked,
      onEditTap: (row) async => await _onEditTap(bins, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(bins, row.first),
    );
  }

  Widget _buildToolbar(List<WHBin> bins) {
    return ListToolbarButtons(
      dataLength: bins.length,
      primaryLabel: 'Create Bin',
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete Bin.',
      refreshLabel: 'Refresh WH Bin',
      onPrimary: () => _openWarehouseForm(bins: bins),
      onRefresh: () => _bloc.add(RefreshInventories<WHBin>()),
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

  Future<void> _onEditTap(List<WHBin> bins, String id) async {
    final bin = WHBin.findById(bins, id);
    if (bin == null) return;

    await _openWarehouseForm(bins: bins, serverBin: bin);
  }

  Future<void> _onDeleteTap(List<WHBin> bins, String id) async {
    final bin = WHBin.findById(bins, id);
    if (bin == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      _bloc.add(DeleteInventory<String>(documentId: bin.id));
    }
  }

  Future<void> _openWarehouseForm({WHBin? serverBin, List<WHBin>? bins}) async {
    List<String>? existingCodes = WHBin.getCodes(bins ?? []);
    await context.openWHBinForm(
      serverItem: serverBin,
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
