import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/company_stores_model.dart';
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
  final List<String> _selectedIds = [];
  CompanyStoresBloc get _bloc => context.read<CompanyStoresBloc>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CompanyStoresBloc>(
      create: (context) =>
          CompanyStoresBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<CompanyStores>()),
      child: CustomScaffold(
        noAppBar: true,
        body: _buildBody(),
        bottomNavigationBar: const SizedBox.shrink(),
      ),
    );
  }

  BlocBuilder<CompanyStoresBloc, SetupState<CompanyStores>> _buildBody() {
    return BlocBuilder<CompanyStoresBloc, SetupState<CompanyStores>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<CompanyStores>() => context.loader,
          SetupsLoaded<CompanyStores>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Add Stores',
                    onPressed: () => context.openAddStoreLocations(),
                  )
                : _buildCard(results),
          SetupError<CompanyStores>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(List<CompanyStores> stores) {
    return DynamicDataTable(
      omitAtIndex: 0,
      headers: CompanyStores.dataTableHeader,
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

  _buildToolbar(List<CompanyStores> stores) {
    return ListToolbarButtons(
      primaryLabel: 'Add Stores',
      refreshLabel: 'Refresh Stores',
      secondaryLabel: 'Edit Store',
      secondaryIcon: Icons.edit,
      dataLength: stores.length,
      onPrimary: () => context.openAddStoreLocations(),
      onRefresh: () => _bloc.add(RefreshSetups<CompanyStores>()),
      onSecondary: _selectedIds.length == 1
          ? () async => _onEditTap(stores, _selectedIds.first)
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

  CompanyStores? _findStoresById(List<CompanyStores> stores, String id) =>
      CompanyStores.findById(stores, id);

  Future<void> _onEditTap(List<CompanyStores> stores, String id) async {
    final store = _findStoresById(stores, id);
    if (store == null) return;

    await context.openAddStoreLocations(serverStore: store);
  }

  Future<void> _onDeleteTap(List<CompanyStores> stores, String id) async {
    final store = _findStoresById(stores, id);
    if (store == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Delete specific Store
      _bloc.add(DeleteSetup<String>(documentId: store.id));
    }
  }
}
