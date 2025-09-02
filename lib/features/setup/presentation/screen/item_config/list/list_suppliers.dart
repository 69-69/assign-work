import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/setup/data/models/supplier_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/product_config/suppliers_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/setup/presentation/screen/item_config/add/add_suppliers.dart';
import 'package:assign_erp/features/setup/presentation/screen/item_config/update/update_supplier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListSuppliers extends StatefulWidget {
  const ListSuppliers({super.key});

  @override
  State<ListSuppliers> createState() => _ListSuppliersState();
}

class _ListSuppliersState extends State<ListSuppliers> {
  final storeBloc = SupplierBloc(firestore: FirebaseFirestore.instance);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SupplierBloc>(
      create: (context) =>
          SupplierBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<Supplier>()),
      child: _buildBody(),
    );
  }

  BlocBuilder<SupplierBloc, SetupState<Supplier>> _buildBody() {
    return BlocBuilder<SupplierBloc, SetupState<Supplier>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Supplier>() => context.loader,
          SetupsLoaded<Supplier>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Add Suppliers',
                    onPressed: () => context.openAddSuppliers(),
                  )
                : _buildCard(context, results),
          SetupError<Supplier>(error: final error) => context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<Supplier> suppliers) {
    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 2,
      headers: Supplier.dataHeader,
      anyWidgetAlignment: WrapAlignment.spaceBetween,
      anyWidget: _buildAnyWidget(suppliers),
      rows: suppliers.map((d) => d.toListL()).toList(),
      onEditTap: (row) async => _onEditTap(suppliers, row.first),
      onDeleteTap: (row) async => _onDeleteTap(suppliers, row.first),
    );
  }

  _buildAnyWidget(List<Supplier> sales) {
    return Wrap(
      spacing: 10.0,
      alignment: WrapAlignment.spaceBetween,
      children: [
        context.actionInfoButton(
          'Refresh Suppliers',
          label: 'Suppliers',
          count: sales.length,
          onPressed: () =>
              context.read<SupplierBloc>().add(RefreshSetups<Supplier>()),
        ),
        context.elevatedIconBtn(
          Icon(Icons.add, color: kWhiteColor),
          label: 'Add Suppliers',
          onPressed: () => context.openAddSuppliers(),
          bgColor: kDangerColor,
          txtColor: kWhiteColor,
        ),
      ],
    );
  }

  Future<void> _onEditTap(List<Supplier> suppliers, String id) async {
    final supplier = Supplier.findCategoriesById(suppliers, id).first;
    await context.openUpdateSupplier(supplier: supplier);
  }

  Future<void> _onDeleteTap(List<Supplier> suppliers, String id) async {
    final supplier = Supplier.findCategoriesById(suppliers, id).first;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Delete specific Supplier
      context.read<SupplierBloc>().add(
        DeleteSetup<String>(documentId: supplier.id),
      );
    }
  }
}
