import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/price_list_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/price_list_master_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/pricing_discount_master/create/create_price_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PriceLists extends StatefulWidget {
  const PriceLists({super.key});

  @override
  State<PriceLists> createState() => _PriceListsState();
}

class _PriceListsState extends State<PriceLists> {
  bool _inProgress = false;
  final List<String> _selectedIds = [];

  late final PriceListMasterBloc _bloc;
  // PriceListMasterBloc get _bloc => context.read<PriceListMasterBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) => context.showAlertOverlay(msg);

  void _handleBlocState(BuildContext cxt, SetupState<PriceListMaster> state) {
    switch (state) {
      case SetupDeleted<PriceListMaster>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case SetupError<PriceListMaster>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _bloc = PriceListMasterBloc(firestore: FirebaseFirestore.instance)
      ..add(GetSetups<PriceListMaster>());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<PriceListMasterBloc, SetupState<PriceListMaster>>(
        listener: _handleBlocState,
        child: _buildBody(),
      ),
    );
  }

  BlocBuilder<PriceListMasterBloc, SetupState<PriceListMaster>> _buildBody() {
    return BlocBuilder<PriceListMasterBloc, SetupState<PriceListMaster>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<PriceListMaster>() => context.loader,
          SetupsLoaded<PriceListMaster>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Price List',
                    onPressed: () => _openPriceMasterForm(context),
                  )
                : _buildCard(context, results),
          SetupError<PriceListMaster>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<PriceListMaster> masters) {
    return DynamicDataTable(
      omitAtIndex: 0,
      // maskAtIndex: 1,
      toolbar: _buildToolbar(masters),
      headers: PriceListMaster.dataTableHeader,
      rows: masters.map((d) => d.itemAsList).toList(),
      template: PriceListMaster.templateHeader,
      selectedRowKeys: _selectedIds,
      onChecked: _onChecked,
      onAllChecked: _onAllChecked,
      onEditTap: (row) async => await _onEditTap(masters, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(masters, row.first),
    );
  }

  Widget _buildToolbar(List<PriceListMaster> masters) {
    return ListToolbarButtons(
      dataLength: masters.length,
      primaryLabel: 'Create Price List',
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete',
      refreshLabel: 'Refresh Price List',
      onPrimary: () => _openPriceMasterForm(context),
      onRefresh: () => _bloc.add(RefreshSetups<PriceListMaster>()),
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

  Future<void> _onEditTap(List<PriceListMaster> masters, String id) async {
    final master = PriceListMaster.findById(masters, id);
    if (master == null) return;

    await _openPriceMasterForm(context, serverItem: master);
  }

  Future<void> _onDeleteTap(List<PriceListMaster> masters, String id) async {
    final master = PriceListMaster.findById(masters, id);
    if (master == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      _bloc.add(DeleteSetup<String>(documentId: master.id));
    }
  }

  Future<void> _openPriceMasterForm(
    BuildContext cxt, {
    PriceListMaster? serverItem,
  }) async => await cxt.openAddPriceList(serverPriceList: serverItem);

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
