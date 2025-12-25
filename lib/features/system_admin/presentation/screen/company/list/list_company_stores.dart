import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
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
      onEditTap: (row) async => _onEditTap(stores, row.first),
      onDeleteTap: (row) async => _onDeleteTap(stores, row.first),
      optButtonIcon: Icons.store,
      optButtonLabel: 'Switch',
      onOptButtonTap: (row) async {
        final store = _findStoresById(stores, row.first);
        await context.onSwitchStore(
          store.storeNumber,
          location: store.location,
        );
      },
    );
  }

  _buildToolbar(List<CompanyStores> sales) {
    return Wrap(
      spacing: 10.0,
      alignment: WrapAlignment.spaceBetween,
      children: [
        context.actionInfoButton(
          'Refresh Stores',
          label: 'Stores',
          count: sales.length,
          onPressed: () => context.read<CompanyStoresBloc>().add(
            RefreshSetups<CompanyStores>(),
          ),
        ),
        context.elevatedIconBtn(
          Icon(Icons.store, color: kWhiteColor),
          label: 'Add Stores',
          tooltip: 'Company\'s Stores or Branches',
          onPressed: () => context.openAddStoreLocations(),
          bgColor: kDangerColor,
          txtColor: kWhiteColor,
        ),
      ],
    );
  }

  CompanyStores _findStoresById(List<CompanyStores> stores, String id) =>
      CompanyStores.findStoresById(stores, id).first;

  Future<void> _onEditTap(List<CompanyStores> stores, String id) async {
    final store = _findStoresById(stores, id);
    await context.openAddStoreLocations(serverStore: store);
  }

  Future<void> _onDeleteTap(List<CompanyStores> stores, String id) async {
    {
      final store = _findStoresById(stores, id);

      final isConfirmed = await context.confirmUserActionDialog();
      if (mounted && isConfirmed) {
        /// Delete specific Store
        context.read<CompanyStoresBloc>().add(
          DeleteSetup<String>(documentId: store.id),
        );
      }
    }
  }
}
