import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_location_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/wh_location_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/create/create_wh_location.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/generate_codes/generate_wh_location_codes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListWHLocations extends StatefulWidget {
  const ListWHLocations({super.key});

  @override
  State<ListWHLocations> createState() => _ListWHLocationsState();
}

class _ListWHLocationsState extends State<ListWHLocations> {
  bool _inProgress = false;
  final List<String> _selectedIds = [];

  WHLocationBloc get _bloc => context.read<WHLocationBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
  }

  void _handleBlocState(BuildContext cxt, InventoryState<WHLocation> state) {
    switch (state) {
      case InventoryDeleted<WHLocation>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case InventoryError<WHLocation>():
        _showAlert('Error saving changes');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WHLocationBloc, InventoryState<WHLocation>>(
      listener: _handleBlocState,
      child: _buildBody(),
    );
  }

  BlocBuilder<WHLocationBloc, InventoryState<WHLocation>> _buildBody() {
    return BlocBuilder<WHLocationBloc, InventoryState<WHLocation>>(
      builder: (context, state) {
        return switch (state) {
          LoadingInventory<WHLocation>() => context.loader,
          InventoriesLoaded<WHLocation>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Location',
                    onPressed: () => _openWarehouseForm(),
                  )
                : _buildCard(context, results),
          InventoryError<WHLocation>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<WHLocation> locations) {
    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: WHLocation.dataTableHeader,
      toolbar: _buildToolbar(locations),
      rows: locations.map((d) => d.itemAsList).toList(),
      selectedRowKeys: _selectedIds,
      onChecked: _onChecked,
      onAllChecked: _onAllChecked,
      onEditTap: (row) async => await _onEditTap(locations, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(locations, row.first),
    );
  }

  Widget _buildToolbar(List<WHLocation> locations) {
    return ListToolbarButtons(
      dataLength: locations.length,
      primaryLabel: 'Create Location',
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete Location',
      refreshLabel: 'Refresh WH Locations',
      secondaryIcon: Icons.generating_tokens,
      secondaryLabel: 'Generate Location Codes',
      onPrimary: () => _openWarehouseForm(),
      onRefresh: () => _bloc.add(RefreshInventories<WHLocation>()),
      onSecondary: _selectedIds.isNotEmpty
          ? () async {
              final loc = WHLocation.findById(locations, _selectedIds.first);
              if (loc == null) return;

              await context.openGenerateWHLocCodesForm(serverItem: loc);
            }
          : null,
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

  Future<void> _onEditTap(List<WHLocation> locations, String id) async {
    final loc = WHLocation.findById(locations, id);
    if (loc == null) return;

    await _openWarehouseForm(serverLoc: loc);
  }

  Future<void> _onDeleteTap(List<WHLocation> locations, String id) async {
    final loc = WHLocation.findById(locations, id);
    if (loc == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      _bloc.add(DeleteInventory<String>(documentId: loc.id));
    }
  }

  Future<void> _openWarehouseForm({WHLocation? serverLoc}) async {
    await context.openWHLocationForm(serverItem: serverLoc);
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
