import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/activity_log_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/activity_log/activity_log_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  bool _inProgress = false;
  final List<String> _selectedIds = [];
  late final ActivityLogBloc _bloc;

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _handleBlocState(BuildContext cxt, SetupState<ActivityLog> state) {
    switch (state) {
      case SetupDeleted<ActivityLog>(message: var msg):
        cxt.showAlertOverlay(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case SetupError<ActivityLog>():
        cxt.showAlertOverlay('Error saving changes');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _bloc = ActivityLogBloc(firestore: FirebaseFirestore.instance)
      ..add(GetSetups<ActivityLog>());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<ActivityLogBloc, SetupState<ActivityLog>>(
        listener: _handleBlocState,
        child: _buildBody(),
      ),
    );
  }

  BlocBuilder<ActivityLogBloc, SetupState<ActivityLog>> _buildBody() {
    return BlocBuilder<ActivityLogBloc, SetupState<ActivityLog>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<ActivityLog>() => context.loader,
          SetupsLoaded<ActivityLog>(data: var results) =>
            results.isEmpty
                ? Center(
                    child: Text(
                      'No attendance found',
                      style: context.textTheme.bodyMedium,
                    ),
                  )
                : _buildCard(context, results),
          SetupError<ActivityLog>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext cxt, List<ActivityLog> activities) {
    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: ActivityLog.dataTableHeader,
      toolbar: _buildToolbar(context, activities),
      rows: activities.map((d) => d.itemAsList()).toList(),
      optButtonLabel: 'View',
      optButtonIcon: Icons.explore_outlined,
      onOptButtonTap: (row) async =>
          _onViewAreasTap(cxt, activities, row.first),
      onDeleteTap: (row) async => _onDeleteTap(cxt, activities, row.first),
      selectedRowKeys: _selectedIds,
      onChecked: _onChecked,
      onAllChecked: _onAllChecked,
    );
  }

  Widget _buildToolbar(BuildContext cxt, List<ActivityLog> activities) {
    final log = _selectedIds.length > 1 ? 'Activities' : 'Activity';

    return ListToolbarButtons(
      dataLength: activities.length,
      dangerTooltip: 'Delete Selected $log',
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete $log',
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

  ActivityLog _findActivity(List<ActivityLog> logs, String userId) =>
      ActivityLog.findById(logs, userId);

  Future<void> _onViewAreasTap(
    BuildContext cxt,
    List<ActivityLog> logs,
    String userId,
  ) async {
    ActivityLog log = _findActivity(logs, userId);

    /// Show Areas viewed by employee
    await context.showHistoryBottomSheet<String>(
      title: 'Areas Viewed by ${log.name.toTitle}',
      columnLabels: const ['Area', 'Time'],
      items: log.areasViewed,
      rowBuilder: (entry, index) {
        final parts = entry.split('@');
        final area = parts.first.trim();
        final time = parts.length > 1 ? parts.last : 'N/A';

        return DataRow(
          cells: [DataCell(Text(area.toTitle)), DataCell(Text(time.timeOnly))],
        );
      },
    );
  }

  Future<void> _onDeleteTap(
    BuildContext cxt,
    List<ActivityLog> logs,
    String userId,
  ) async {
    ActivityLog log = _findActivity(logs, userId);

    final isConfirmed = await cxt.confirmUserActionDialog();
    if (cxt.mounted && isConfirmed) {
      /// Delete specific activity_log
      cxt.read<ActivityLogBloc>().add(DeleteSetup<String>(documentId: log.id));
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

  /*Widget _dataTable(ActivityLog log) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        horizontalMargin: 8,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 32,
        headingRowHeight: 30,
        columns: [_dataColumn('Area'), _dataColumn('Time')],
        rows: log.areasViewed.map((entry) {
          final parts = entry.split('@');
          final area = parts.first.trim();
          final time = parts.length > 1 ? parts.last : 'N/A';

          return DataRow(
            cells: [
              DataCell(Text(area.toTitle)),
              DataCell(Text(time.timeOnly)),
            ],
          );
        }).toList(),
      ),
    );
  }

  DataColumn _dataColumn(String str) {
    return DataColumn(
      label: Text(str, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }*/
}
