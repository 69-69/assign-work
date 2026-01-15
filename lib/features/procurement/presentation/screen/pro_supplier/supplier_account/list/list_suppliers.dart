import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_vendor/suppliers_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_supplier/supplier_account/create/create_suppliers.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_supplier/supplier_account/list/see_supplier_details.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_supplier/supplier_account/update/update_supplier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListSuppliers extends StatefulWidget {
  const ListSuppliers({super.key});

  @override
  State<ListSuppliers> createState() => _ListSuppliersState();
}

class _ListSuppliersState extends State<ListSuppliers> {
  // final storeBloc = SupplierBloc(firestore: FirebaseFirestore.instance);
  // List to group Requisitions for printout
  final List<String> _selectedIds = [];

  SupplierBloc get _bloc => context.read<SupplierBloc>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierBloc, ProcurementState<Supplier>>(
      builder: (context, state) {
        return switch (state) {
          LoadingProcurement<Supplier>() => context.loader,
          ProcurementsLoaded<Supplier>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Add Supplier',
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
      toolbarAlignment: WrapAlignment.spaceBetween,
      toolbar: _buildToolbar(suppliers),
      rows: suppliers.map((d) => d.itemAsList).toList(),
      onViewDetailsTap: (row) async => _onViewDetails(suppliers, row.first),
      onEditTap: (row) async => _onEditTap(suppliers, row.first),
      onDeleteTap: (row) async => _onDeleteTap(suppliers, row.first),
      selectedRowKeyIndex: 0,
      selectedRowKeys: _selectedIds,
      onChecked: _onChecked,
      onAllChecked: _onAllChecked,
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

  _buildToolbar(List<Supplier> suppliers) {
    return ListToolbarButtons(
      refreshLabel: 'Refresh Suppliers',
      primaryLabel: 'Add Supplier',
      dangerLabel: 'Delete Supplier',
      secondaryLabel: 'Edit Supplier',
      secondaryIcon: Icons.edit,
      dataLength: suppliers.length,
      onPrimary: () => context.openAddSuppliers(),
      onRefresh: () => _bloc.add(RefreshProcurements<Supplier>()),
      onSecondary: _selectedIds.length == 1
          ? () async => _onEditTap(suppliers, _selectedIds.first)
          : null,
      onDanger: _selectedIds.isNotEmpty
          ? () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (mounted && isConfirmed) {
                _bloc.add(
                  DeleteProcurement<List<String>>(documentId: _selectedIds),
                );
                _selectedIds.clear();
              }
            }
          : null,
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
