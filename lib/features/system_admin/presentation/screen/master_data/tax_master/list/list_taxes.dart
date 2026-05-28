import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/taxes/tax_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/tax_master/create/create_tax.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListTaxes extends StatefulWidget {
  const ListTaxes({super.key});

  @override
  State<ListTaxes> createState() => _ListTaxesState();
}

class _ListTaxesState extends State<ListTaxes> {
  bool _inProgress = false;
  List<String> _selectedIds = [];

  TaxBloc get _bloc => context.read<TaxBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
  }

  void _handleBlocState(BuildContext cxt, SetupState<Tax> state) {
    switch (state) {
      case SetupDeleted<Tax>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case SetupError<Tax>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaxBloc, SetupState<Tax>>(
      listener: _handleBlocState,
      child: _buildBody(),
    );
  }

  BlocBuilder<TaxBloc, SetupState<Tax>> _buildBody() {
    return BlocBuilder<TaxBloc, SetupState<Tax>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Tax>() => context.loader,
          SetupsLoaded<Tax>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'New Tax',
                    onPressed: () => context.openAddTax(),
                  )
                : _buildCard(context, results),
          SetupError<Tax>(error: final error) => context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<Tax> taxes) {
    return DynamicDataTable2(
      omitAtIndex: 0,
      headers: Tax.dataTableHeader,
      template: Tax.templateHeader,
      toolbar: _buildToolbar(taxes),
      rows: taxes.map(_toTableRow).toList(),
      selectedRowKeys: _selectedIds,
      onSelectionChanged: (ids, rows) {
        setState(() => _selectedIds = ids);
      },
      onEditTap: (row) async => await _onEditTap(taxes, row.id),
      onDeleteTap: (row) async => await _onDeleteTap(taxes, row.id),
    );
  }

  DataTableRow _toTableRow(Tax e) => DataTableRow.fromList(e.id, e.itemAsList);

  _buildToolbar(List<Tax> taxes) {
    return ListToolbarButtons(
      dataLength: taxes.length,
      primaryLabel: 'New Tax',
      secondaryLabel: 'Edit',
      secondaryIcon: Icons.edit,
      refreshLabel: 'Refresh',
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete',
      onPrimary: () => context.openAddTax(),
      onRefresh: () => _bloc.add(RefreshSetups<Tax>()),
      onSecondary: _selectedIds.length == 1
          ? () async => _onEditTap(taxes, _selectedIds.first)
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

  Future<void> _onEditTap(List<Tax> taxes, String id) async {
    final tax = Tax.findById(taxes, id);
    if (tax == null) return;

    await context.openAddTax(serverTax: tax);
  }

  Future<void> _onDeleteTap(List<Tax> taxes, String id) async {
    final tax = Tax.findById(taxes, id);
    if (tax == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Delete specific Tax
      _bloc.add(DeleteSetup<String>(documentId: tax.id));
    }
  }
}
