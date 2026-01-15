import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/material_or_service_choice.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_master_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/item_master/item_master_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/item_master/create/create_item_master.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListItemMaster extends StatefulWidget {
  const ListItemMaster({super.key});

  @override
  State<ListItemMaster> createState() => _ListItemMasterState();
}

class _ListItemMasterState extends State<ListItemMaster> {
  bool _inProgress = false;
  final List<String> _selectedIds = [];
  ItemMasterBloc get _bloc => context.read<ItemMasterBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
  }

  void _handleBlocState(BuildContext cxt, InventoryState<ItemMaster> state) {
    switch (state) {
      case InventoryDeleted<ItemMaster>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case InventoryError<ItemMaster>():
        _showAlert('Error saving changes');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ItemMasterBloc, InventoryState<ItemMaster>>(
      listener: _handleBlocState,
      child: _buildBody(),
    );
  }

  BlocBuilder<ItemMasterBloc, InventoryState<ItemMaster>> _buildBody() {
    return BlocBuilder<ItemMasterBloc, InventoryState<ItemMaster>>(
      builder: (context, state) {
        return switch (state) {
          LoadingInventory<ItemMaster>() => context.loader,
          InventoriesLoaded<ItemMaster>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Item Master',
                    onPressed: () => _openItemMasterForm(context),
                  )
                : _buildCard(context, results),
          InventoryError<ItemMaster>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<ItemMaster> masters) {
    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: ItemMaster.dataHeader,
      toolbar: _buildToolbar(masters),
      rows: masters.map((d) => d.itemAsList).toList(),
      selectedRowKeys: _selectedIds,
      onChecked: _onChecked,
      onAllChecked: _onAllChecked,
      onEditTap: (row) async => await _onEditTap(masters, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(masters, row.first),
    );
  }

  Widget _buildToolbar(List<ItemMaster> masters) {
    return ListToolbarButtons(
      dataLength: masters.length,
      primaryLabel: 'Create Item Master',
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete Item Master',
      refreshLabel: 'Refresh Master Data',
      onPrimary: () => _openItemMasterForm(context),
      onRefresh: () => _bloc.add(RefreshInventories<ItemMaster>()),
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

  Future<void> _onEditTap(List<ItemMaster> masters, String id) async {
    final master = ItemMaster.findById(masters, id);
    if (master == null) return;

    await context.openItemMasterForm(serverItem: master);
  }

  Future<void> _onDeleteTap(List<ItemMaster> masters, String id) async {
    final master = ItemMaster.findById(masters, id);
    if (master == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      _bloc.add(DeleteInventory<String>(documentId: master.id));
    }
  }

  Future<void> _openItemMasterForm(
    BuildContext cxt, {
    ItemMaster? serverItem,
  }) async {
    final lineItemType = await cxt.openMaterialOrServiceToggle('Master');
    if (cxt.mounted && '$lineItemType'.hasValue) {
      await cxt.openItemMasterForm(
        serverItem: serverItem,
        itemType: lineItemType,
        onBackPress: () async {
          Navigator.pop(cxt);

          if (cxt.mounted && '$lineItemType'.hasValue) {
            await _openItemMasterForm(cxt);
          }
        },
      );
    }
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
