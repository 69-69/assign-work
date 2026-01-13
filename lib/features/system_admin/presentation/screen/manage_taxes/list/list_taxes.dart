import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/nav/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/taxes/tax_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_taxes/create/create_tax.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListTaxes extends StatefulWidget {
  const ListTaxes({super.key});

  @override
  State<ListTaxes> createState() => _ListTaxesState();
}

class _ListTaxesState extends State<ListTaxes> {
  TaxBloc get _bloc => context.read<TaxBloc>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaxBloc, SetupState<Tax>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Tax>() => context.loader,
          SetupsLoaded<Tax>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Taxes',
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
    return DynamicDataTable(
      omitAtIndex: 0,
      headers: Tax.dataTableHeader,
      toolbar: _buildToolbar(taxes),
      rows: taxes.map((d) => d.itemAsList).toList(),
      onEditTap: (row) async => await _onEditTap(taxes, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(taxes, row.first),
    );
  }

  _buildToolbar(List<Tax> taxes) {
    return ListToolbarButtons(
      createLabel: 'Add Taxes',
      refreshLabel: 'Refresh Taxes',
      dataLength: taxes.length,
      onCreate: () => context.openAddTax(),
      onRefresh: () => _bloc.add(RefreshSetups<Tax>()),
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
