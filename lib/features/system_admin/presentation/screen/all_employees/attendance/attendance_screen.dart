import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_table.dart';
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
      onEditTap: (row) async => _onViewTap(cxt, attendances, row.first),
      onDeleteTap: (row) async => _onDeleteTap(cxt, attendances, row.first),
      onAllChecked:
          (
            bool isChecked,
            List<bool> isAllChecked,
            List<List<String>> checkedRows,
          ) {
            setState(() {
              _selectedIds.clear();
              if (isChecked) {
                _selectedIds.addAll(checkedRows.map((e) => e.first));
              }
            });
          },
    );
  }

  Widget _anyWidget(BuildContext cxt) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      runAlignment: WrapAlignment.spaceBetween,
      children: [
        if (_selectedIds.isNotEmpty) ...[
          context.elevatedIconBtn(
            Icon(Icons.delete, color: kWhiteColor),
            style: OutlinedButton.styleFrom(
              backgroundColor: context.errorColor,
            ),
            onPressed: () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (cxt.mounted && isConfirmed) {
                /// Delete all selected Attendance
                cxt.read<AttendanceBloc>().add(
                  DeleteSetup<List<String>>(documentId: _selectedIds),
                );
                // _selectedIds.clear();
                // setState(() {});
              }
            },
            label: const Text(
              'Delete all',
              style: TextStyle(color: kWhiteColor),
            ),
          ),
        ],
      ],
    );
  }

  Attendance _findAttendance(List<Attendance> attendances, String userId) =>
      Attendance.findById(attendances, userId);

  Future<void> _onViewTap(
    BuildContext cxt,
    List<Attendance> attendances,
    String userId,
  ) async {
    Attendance attendance = _findAttendance(attendances, userId);

    /// Show Areas viewed by employee
    await cxt.confirmDone(
      attendance.areasViewed.isEmpty
          ? Text('No areas viewed yet!')
          : _dataTable(attendance),
      title: 'Areas Viewed by ${attendance.name.toTitle}',
      onDone: 'Done',
    );
  }

  Widget _dataTable(Attendance attendance) {
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
  }

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
