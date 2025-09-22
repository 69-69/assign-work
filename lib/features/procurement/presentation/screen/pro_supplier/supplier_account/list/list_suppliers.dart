import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_vendor/suppliers_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_supplier/supplier_account/add/add_suppliers.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_supplier/supplier_account/list/see_supplier_details.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_supplier/supplier_account/update/update_supplier.dart';
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
    return BlocBuilder<SupplierBloc, ProcurementState<Supplier>>(
      builder: (context, state) {
        return switch (state) {
          LoadingProcurement<Supplier>() => context.loader,
          ProcurementsLoaded<Supplier>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Add Suppliers',
                    onPressed: () => context.openAddSuppliers(),
                  )
                : _buildBody(context, results),
          ProcurementError<Supplier>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildBody(BuildContext c, List<Supplier> suppliers) {
    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 2,
      headers: Supplier.dataHeader,
      anyWidgetAlignment: WrapAlignment.spaceBetween,
      anyWidget: _buildAnyWidget(suppliers),
      rows: suppliers.map((d) => d.toListL()).toList(),
      onViewDetailsTap: (row) async => _onViewDetails(suppliers, row.first),
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
              context.read<SupplierBloc>().add(RefreshProcurements<Supplier>()),
        ),
        context.elevatedButton(
          'Add Suppliers',
          onPressed: () => context.openAddSuppliers(),
          bgColor: kDangerColor,
          txtColor: kWhiteColor,
        ),
      ],
    );
  }

  Future<void> _onEditTap(List<Supplier> suppliers, String id) async {
    Supplier? supplier = _getSupplierById(suppliers, id);
    if (supplier == null) return;

    await context.openUpdateSupplier(supplier: supplier);
  }

  Future<void> _onViewDetails(List<Supplier> suppliers, String id) async {
    Supplier? supplier = _getSupplierById(suppliers, id);
    if (supplier == null) return;

    if (mounted) {
      await context.openSupplierDetails(supplier: supplier);
    }
  }

  Supplier? _getSupplierById(List<Supplier> suppliers, String id) {
    final supplier = Supplier.findById(suppliers, id);
    return supplier.isEmpty ? null : supplier;
  }

  Future<void> _onDeleteTap(List<Supplier> suppliers, String id) async {
    Supplier? supplier = _getSupplierById(suppliers, id);
    if (supplier == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Delete specific Supplier
      context.read<SupplierBloc>().add(
        DeleteProcurement<String>(documentId: supplier.id),
      );
    }
  }
}
