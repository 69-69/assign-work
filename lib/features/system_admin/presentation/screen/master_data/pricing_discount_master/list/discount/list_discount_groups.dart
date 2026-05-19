import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/discount_group_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/discount_group_master_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/pricing_discount_master/create/create_discount_group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListDiscountGroups extends StatefulWidget {
  const ListDiscountGroups({super.key});

  @override
  State<ListDiscountGroups> createState() => _ListDiscountGroupsState();
}

class _ListDiscountGroupsState extends State<ListDiscountGroups> {
  bool _inProgress = false;
  final List<String> _selectedIds = [];

  late final DiscountGroupMasterBloc _bloc;

  // DiscountGroupMasterBloc get _bloc => context.read<DiscountGroupMasterBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) => context.showAlertOverlay(msg);

  void _handleBlocState(BuildContext cxt, SetupState<DiscountGroup> state) {
    switch (state) {
      case SetupDeleted<DiscountGroup>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case SetupError<DiscountGroup>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _bloc = DiscountGroupMasterBloc(firestore: FirebaseFirestore.instance)
      ..add(GetSetups<DiscountGroup>());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<DiscountGroupMasterBloc, SetupState<DiscountGroup>>(
        listener: _handleBlocState,
        child: _buildBody(),
      ),
    );
  }

  BlocBuilder<DiscountGroupMasterBloc, SetupState<DiscountGroup>> _buildBody() {
    return BlocBuilder<DiscountGroupMasterBloc, SetupState<DiscountGroup>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<DiscountGroup>() => context.loader,
          SetupsLoaded<DiscountGroup>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Discount Group',
                    onPressed: () => _openDiscountGroupForm(context),
                  )
                : _buildCard(context, results),
          SetupError<DiscountGroup>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<DiscountGroup> masters) {
    return DynamicDataTable(
      omitAtIndex: 0,
      // maskAtIndex: 1,
      toolbar: _buildToolbar(masters),
      headers: DiscountGroup.dataTableHeader,
      rows: masters.map((d) => d.itemAsList).toList(),
      template: DiscountGroup.templateHeader,
      selectedRowKeys: _selectedIds,
      onChecked: _onChecked,
      onAllChecked: _onAllChecked,
      onEditTap: (row) async => await _onEditTap(masters, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(masters, row.first),
    );
  }

  Widget _buildToolbar(List<DiscountGroup> masters) {
    return ListToolbarButtons(
      dataLength: masters.length,
      primaryLabel: 'Create Discount Group',
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete',
      refreshLabel: 'Refresh Discount Groups',
      onPrimary: () => _openDiscountGroupForm(context),
      onRefresh: () => _bloc.add(RefreshSetups<DiscountGroup>()),
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

  Future<void> _onEditTap(List<DiscountGroup> masters, String id) async {
    final master = DiscountGroup.findById(masters, id);
    if (master == null) return;

    await _openDiscountGroupForm(context, serverItem: master);
  }

  Future<void> _onDeleteTap(List<DiscountGroup> masters, String id) async {
    final master = DiscountGroup.findById(masters, id);
    if (master == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      _bloc.add(DeleteSetup<String>(documentId: master.id));
    }
  }

  Future<void> _openDiscountGroupForm(
    BuildContext cxt, {
    DiscountGroup? serverItem,
  }) async => await cxt.openAddDiscountGroup(serverDiscountGroup: serverItem);

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
