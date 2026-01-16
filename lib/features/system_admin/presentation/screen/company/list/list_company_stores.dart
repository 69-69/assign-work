import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/company_store_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_stores_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/create/create_store_locations.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/can_add_more_stores.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListCompanyStores extends StatefulWidget {
  const ListCompanyStores({super.key});

  @override
  State<ListCompanyStores> createState() => _ListCompanyStoresState();
}

class _ListCompanyStoresState extends State<ListCompanyStores> {
  bool _inProgress = false;
  final List<String> _selectedIds = [];
  late final CompanyStoresBloc _bloc;
  // CompanyStoresBloc get _bloc => context.read<CompanyStoresBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _handleBlocState(BuildContext cxt, SetupState<CompanyStore> state) {
    switch (state) {
      case SetupDeleted<CompanyStore>(message: var msg):
        cxt.showAlertOverlay(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case SetupError<CompanyStore>():
        cxt.showAlertOverlay('Error saving changes');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _bloc = CompanyStoresBloc(firestore: FirebaseFirestore.instance)
      ..add(GetSetups<CompanyStore>());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<CompanyStoresBloc, SetupState<CompanyStore>>(
        listener: _handleBlocState,
        child: _buildBody(),
      ),
    );
  }

  /*@override
  Widget build2(BuildContext context) {
    return BlocProvider<CompanyStoresBloc>(
      create: (context) =>
          CompanyStoresBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<CompanyStore>()),
      child: CustomScaffold(
        noAppBar: true,
        body: _buildBody(),
        bottomNavigationBar: const SizedBox.shrink(),
      ),
    );
  }*/

  BlocBuilder<CompanyStoresBloc, SetupState<CompanyStore>> _buildBody() {
    return BlocBuilder<CompanyStoresBloc, SetupState<CompanyStore>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<CompanyStore>() => context.loader,
          SetupsLoaded<CompanyStore>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Add Stores',
                    onPressed: () => context.openAddStoreLocations(),
                  )
                : _buildCard(results),
          SetupError<CompanyStore>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(List<CompanyStore> stores) {
    return DynamicDataTable(
      omitAtIndex: 0,
      headers: CompanyStore.dataTableHeader,
      toolbar: _buildToolbar(stores),
      rows: stores.map((d) => d.itemAsList).toList(),
      selectedRowKeys: _selectedIds,
      onChecked: _onChecked,
      onAllChecked: _onAllChecked,
      onEditTap: (row) async => _onEditTap(stores, row.first),
      onDeleteTap: (row) async => _onDeleteTap(stores, row.first),
      optButtonIcon: Icons.store,
      optButtonLabel: 'Switch',
      onOptButtonTap: (row) async {
        final store = _findStoresById(stores, row.first);
        if (store == null) return;

        await context.onSwitchStore(
          store.storeNumber,
          location: store.location,
        );
      },
    );
  }

  _buildToolbar(List<CompanyStore> stores) {
    return ListToolbarButtons(
      primaryLabel: 'Add Stores',
      refreshLabel: 'Refresh Stores',
      secondaryLabel: 'Edit Store',
      secondaryIcon: Icons.edit,
      dataLength: stores.length,
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete Store',
      onPrimary: () => context.openAddStoreLocations(),
      onRefresh: () => _bloc.add(RefreshSetups<CompanyStore>()),
      onSecondary: _selectedIds.length == 1
          ? () async => _onEditTap(stores, _selectedIds.first)
          : null,
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

  CompanyStore? _findStoresById(List<CompanyStore> stores, String id) =>
      CompanyStore.findById(stores, id);

  Future<void> _onEditTap(List<CompanyStore> stores, String id) async {
    final store = _findStoresById(stores, id);
    if (store == null) return;

    await context.openAddStoreLocations(serverStore: store);
  }

  Future<void> _onDeleteTap(List<CompanyStore> stores, String id) async {
    final store = _findStoresById(stores, id);
    if (store == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Delete specific Store
      _bloc.add(DeleteSetup<String>(documentId: store.id));
    }
  }
}
