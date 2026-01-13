import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/nav/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_master_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/item_master/item_master_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/item_master/create/create_item_master.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListItemMaster extends StatefulWidget {
  const ListItemMaster({super.key});

  @override
  State<ListItemMaster> createState() => _ListItemMasterState();
}

class _ListItemMasterState extends State<ListItemMaster> {
  final List<String> _selectedIds = [];
  ItemMasterBloc get _bloc => context.read<ItemMasterBloc>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ItemMasterBloc>(
      create: (_) =>
          ItemMasterBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<ItemMaster>()),
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
                    onPressed: () => context.openItemMasterForm(),
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
      onEditTap: (row) async => await _onEditTap(masters, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(masters, row.first),
      onAllChecked:
          (
            bool isChecked,
            List<bool> isAllChecked,
            List<List<String>> checkedRows,
          ) {
            setState(() {
              _selectedIds.clear();
              if (isChecked) {
                _selectedIds.addAll(checkedRows.map((e) => e.first));
              }
            });
          },
    );
  }

  Widget _buildToolbar(List<ItemMaster> masters) {
    return ListToolbarButtons(
      dataLength: masters.length,
      createLabel: 'Create Item Master',
      deleteLabel: 'Delete Item Master',
      refreshLabel: 'Refresh Master Data',
      onCreate: () => context.openItemMasterForm(),
      onRefresh: () => _bloc.add(RefreshInventories<ItemMaster>()),
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
}
