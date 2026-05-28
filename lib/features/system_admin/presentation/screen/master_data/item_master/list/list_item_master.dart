import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/material_or_service_choice.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/item_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/item_master_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/item_master/create/create_item_master.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListItemMaster extends StatefulWidget {
  const ListItemMaster({super.key});

  @override
  State<ListItemMaster> createState() => _ListItemMasterState();
}

class _ListItemMasterState extends State<ListItemMaster> {
  bool _inProgress = false;
   List<String> _selectedIds = [];

  ItemMasterBloc get _bloc => context.read<ItemMasterBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
  }

  void _handleBlocState(BuildContext cxt, SetupState<ItemMaster> state) {
    switch (state) {
      case SetupDeleted<ItemMaster>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case SetupError<ItemMaster>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ItemMasterBloc, SetupState<ItemMaster>>(
      listener: _handleBlocState,
      child: _buildBody(),
    );
  }

  BlocBuilder<ItemMasterBloc, SetupState<ItemMaster>> _buildBody() {
    return BlocBuilder<ItemMasterBloc, SetupState<ItemMaster>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<ItemMaster>() => context.loader,
          SetupsLoaded<ItemMaster>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'New Item Master',
                    onPressed: () => _openItemMasterForm(context),
                  )
                : _buildCard(context, results),
          SetupError<ItemMaster>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<ItemMaster> masters) {
    return DynamicDataTable2(
      omitAtIndex: 0,
      maskAtIndex: 1,
      toolbar: _buildToolbar(masters),
      headers: ItemMaster.dataTableHeader,
      rows: masters.map(_toTableRow).toList(),
      template: ItemMaster.templateHeader,
      selectedRowKeys: _selectedIds,
      onSelectionChanged: (ids, rows) {
        setState(() => _selectedIds = ids);
      },
      onEditTap: (row) async => await _onEditTap(masters, row.id),
      onDeleteTap: (row) async => await _onDeleteTap(masters, row.id),
    );
  }

  DataTableRow _toTableRow(ItemMaster e) =>
      DataTableRow.fromList(e.id, e.itemAsList);

  Widget _buildToolbar(List<ItemMaster> masters) {
    return ListToolbarButtons(
      dataLength: masters.length,
      primaryLabel: 'New Item Master',
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete',
      refreshLabel: 'Refresh',
      onPrimary: () => _openItemMasterForm(context),
      onRefresh: () => _bloc.add(RefreshSetups<ItemMaster>()),
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
      _bloc.add(DeleteSetup<String>(documentId: master.id));
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
}
