import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/wh_location_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/wh_location_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/wh_location/create/create_wh_location.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/wh_location/generate_codes/generate_wh_location_codes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListWHLocations extends StatefulWidget {
  const ListWHLocations({super.key});

  @override
  State<ListWHLocations> createState() => _ListWHLocationsState();
}

class _ListWHLocationsState extends State<ListWHLocations> {
  bool _inProgress = false;
  List<String> _selectedIds = [];

  WHLocationBloc get _bloc => context.read<WHLocationBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
  }

  void _handleBlocState(BuildContext cxt, SetupState<WHLocation> state) {
    switch (state) {
      case SetupDeleted<WHLocation>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case SetupError<WHLocation>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WHLocationBloc, SetupState<WHLocation>>(
      listener: _handleBlocState,
      child: _buildBody(),
    );
  }

  BlocBuilder<WHLocationBloc, SetupState<WHLocation>> _buildBody() {
    return BlocBuilder<WHLocationBloc, SetupState<WHLocation>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<WHLocation>() => context.loader,
          SetupsLoaded<WHLocation>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Location',
                    onPressed: () => _openWarehouseForm(),
                  )
                : _buildCard(context, results),
          SetupError<WHLocation>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<WHLocation> locations) {
    return DynamicDataTable2(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: WHLocation.dataTableHeader,
      toolbar: _buildToolbar(locations),
      rows: locations.map(_toTableRow).toList(),
      selectedRowKeys: _selectedIds,
      onSelectionChanged: (ids, rows) {
        setState(() => _selectedIds = ids);
      },
      onEditTap: (row) async => await _onEditTap(locations, row.id),
      onDeleteTap: (row) async => await _onDeleteTap(locations, row.id),
    );
  }

  DataTableRow _toTableRow(WHLocation e) =>
      DataTableRow.fromList(e.id, e.itemAsList);

  Widget _buildToolbar(List<WHLocation> locations) {
    return ListToolbarButtons(
      dataLength: locations.length,
      primaryLabel: 'New Location',
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete',
      refreshLabel: 'Refresh',
      secondaryIcon: Icons.generating_tokens,
      secondaryLabel: 'Manage Sub-Locations',
      onPrimary: () => _openWarehouseForm(),
      onRefresh: () => _bloc.add(RefreshSetups<WHLocation>()),
      onSecondary: _selectedIds.length == 1
          ? () async {
              final loc = WHLocation.findById(locations, _selectedIds.first);
              if (loc == null) return;

              await context.openGenerateWHLocCodesForm(serverItem: loc);
            }
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

  Future<void> _onEditTap(List<WHLocation> locations, String id) async {
    final loc = WHLocation.findById(locations, id);
    if (loc == null) return;

    await _openWarehouseForm(serverLoc: loc);
  }

  Future<void> _onDeleteTap(List<WHLocation> locations, String id) async {
    final loc = WHLocation.findById(locations, id);
    if (loc == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      _bloc.add(DeleteSetup<String>(documentId: loc.id));
    }
  }

  Future<void> _openWarehouseForm({WHLocation? serverLoc}) async {
    await context.openWHLocationForm(serverItem: serverLoc);
  }
}
