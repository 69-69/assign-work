import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/history_view.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/attendance_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/attendance/attendance_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final List<String> _selectedIds = [];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AttendanceBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<Attendance>()),
      child: _buildBody(),
    );
  }

  BlocBuilder<AttendanceBloc, SetupState<Attendance>> _buildBody() {
    return BlocBuilder<AttendanceBloc, SetupState<Attendance>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Attendance>() => context.loader,
          SetupsLoaded<Attendance>(data: var results) =>
            results.isEmpty
                ? Center(
                    child: Text(
                      'No attendance found',
                      style: context.textTheme.bodyMedium,
                    ),
                  )
                : _buildCard(context, results),
          SetupError<Attendance>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  _buildCard(BuildContext cxt, List<Attendance> attendances) {
    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: Attendance.dataTableHeader,
      anyWidget: _anyWidget(cxt),
      rows: attendances.map((d) => d.itemAsList()).toList(),
      editLabel: 'View Areas',
      editIcon: Icons.explore_outlined,
      onEditTap: (row) async => _onViewAreasTap(cxt, attendances, row.first),
      onDeleteTap: (row) async => _onDeleteTap(cxt, attendances, row.first),
      onChecked: (bool? isChecked, row) {
        setState(() => _updateSelectedIds(isChecked, row.first));
      },
      onAllChecked:
          (
            bool isChecked,
            List<bool> isAllChecked,
            List<List<String>> checkedRows,
          ) {
            setState(() => _updateAllSelectedIds(isChecked, checkedRows));
          },
    );
  }

  // Add item to the selected list if checked, but only if not already in the list
  void _updateSelectedIds(bool? isChecked, String id) {
    if (isChecked == true) {
      if (!_selectedIds.contains(id)) {
        _selectedIds.add(id);
      }
    } else {
      // Remove item from the selected list if unchecked
      _selectedIds.removeWhere((selectedId) => selectedId == id);
    }
  }

  // Updates selected IDs for all checked rows
  void _updateAllSelectedIds(bool isChecked, List<List<String>> checkedRows) {
    _selectedIds.clear(); // Clear previous selections
    if (isChecked) {
      // Add all selected rows, ensuring uniqueness using a Set
      _selectedIds.addAll(checkedRows.map((e) => e.first).toSet());
    }
  }

  Widget _anyWidget(BuildContext cxt) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      runAlignment: WrapAlignment.spaceBetween,
      children: [
        if (_selectedIds.length > 1) ...[
          context.elevatedButton(
            'Delete',
            txtColor: kWhiteColor,
            bgColor: kDangerColor,
            tooltip: 'Delete selected attendance',
            onPressed: () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (cxt.mounted && isConfirmed) {
                /// Delete all selected Attendance
                cxt.read<AttendanceBloc>().add(
                  DeleteSetup<List<String>>(documentId: _selectedIds),
                );
              }
            },
          ),
        ],
      ],
    );
  }

  Attendance _findAttendance(List<Attendance> attendances, String userId) =>
      Attendance.findById(attendances, userId);

  Future<void> _onViewAreasTap(
    BuildContext cxt,
    List<Attendance> attendances,
    String userId,
  ) async {
    Attendance attendance = _findAttendance(attendances, userId);

    /// Show Areas viewed by employee
    await context.showInlineHistorySheet<String>(
      title: 'Areas Viewed by ${attendance.name.toTitle}',
      columnLabels: const ['Area', 'Time'],
      items: attendance.areasViewed,
      rowBuilder: (entry) {
        final parts = entry.split('@');
        final area = parts.first.trim();
        final time = parts.length > 1 ? parts.last : 'N/A';

        return DataRow(
          cells: [DataCell(Text(area.toTitle)), DataCell(Text(time.timeOnly))],
        );
      },
    );
  }

  /*Widget _dataTable(Attendance attendance) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        horizontalMargin: 8,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 32,
        headingRowHeight: 30,
        columns: [_dataColumn('Area'), _dataColumn('Time')],
        rows: attendance.areasViewed.map((entry) {
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

  Future<void> _onDeleteTap(
    BuildContext cxt,
    List<Attendance> attendances,
    String userId,
  ) async {
    Attendance attendance = _findAttendance(attendances, userId);
    // prettyPrint('attendance', attendance.id);

    final isConfirmed = await cxt.confirmUserActionDialog();
    if (cxt.mounted && isConfirmed) {
      /// Delete specific Attendance
      cxt.read<AttendanceBloc>().add(
        DeleteSetup<String>(documentId: attendance.id),
      );
    }
  }
}
