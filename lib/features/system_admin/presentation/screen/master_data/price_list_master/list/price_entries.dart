import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/prerequisite_view.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/price_list_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/price_list_entry_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/price_list_master/create/create_price_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PriceEntries extends StatefulWidget {
  const PriceEntries({super.key});

  @override
  State<PriceEntries> createState() => _PriceEntriesState();
}

class _PriceEntriesState extends State<PriceEntries> {
  bool _inProgress = false;
  final List<String> _selectedIds = [];

  PriceListEntryBloc get _bloc => context.read<PriceListEntryBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
  }

  void _handleBlocState(BuildContext cxt, SetupState<PriceListEntry> state) {
    switch (state) {
      case SetupDeleted<PriceListEntry>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case SetupError<PriceListEntry>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<PriceListEntryBloc, SetupState<PriceListEntry>>(
        listener: _handleBlocState,
        child: _buildBody(),
      ),
    );
  }

  BlocBuilder<PriceListEntryBloc, SetupState<PriceListEntry>> _buildBody() {
    return BlocBuilder<PriceListEntryBloc, SetupState<PriceListEntry>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<PriceListEntry>() => context.loader,
          SetupsLoaded<PriceListEntry>(data: var results) =>
            results.isEmpty
                ? PrerequisiteView(
                    title:
                        'Prerequisite setup incomplete!\nCreate price list and generate variants in item master before setting prices.',
                    actionLabel: 'Open Item Master',
                    onAction: () => context.goNamed(RouteNames.itemMaster),
                  )
                : _buildCard(context, results),
          SetupError<PriceListEntry>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<PriceListEntry> prices) {
    return DynamicDataTable(
      omitAtIndex: 0,
      // maskAtIndex: 1,
      toolbar: _buildToolbar(prices),
      headers: PriceListEntry.dataTableHeader,
      rows: prices.map((d) => d.itemAsList).toList(),
      template: PriceListEntry.templateHeader,
      selectedRowKeys: _selectedIds,
      onChecked: _onChecked,
      onAllChecked: _onAllChecked,
      onEditTap: (row) async => await _onEditTap(prices, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(prices, row.first),
    );
  }

  Widget _buildToolbar(List<PriceListEntry> prices) {
    return ListToolbarButtons(
      dataLength: prices.length,
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete',
      onRefresh: () => _bloc.add(RefreshSetups<PriceListEntry>()),
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

  Future<void> _onEditTap(List<PriceListEntry> prices, String id) async {
    final price = PriceListEntry.findById(prices, id);
    if (price == null || !mounted) return;

    await context.openAddPriceEntry(serverPriceEntry: price);
  }

  Future<void> _onDeleteTap(List<PriceListEntry> prices, String id) async {
    final price = PriceListEntry.findById(prices, id);
    if (price == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      _bloc.add(DeleteSetup<String>(documentId: price.id));
    }
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
}
