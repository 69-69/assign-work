import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/error_logs_model.dart';
import 'package:flutter/material.dart';

class ErrorLogs extends StatefulWidget {
  const ErrorLogs({super.key});

  @override
  State<ErrorLogs> createState() => _ErrorLogsState();
}

class _ErrorLogsState extends State<ErrorLogs> {
  List<ErrorLog> _logs = [];
  final List<String> _selectedIds = [];

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _logs = ErrorLogCache().getLogs(); // ✅ Expecting List<ErrorLog>
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildCard(context);
  }

  Widget _buildCard(BuildContext context) {
    return DynamicDataTable(
      maskAtIndex: 0,
      toolbar: _buildToolbar(),
      headers: ErrorLog.dataTableHeader,
      rows: _logs.map((l) => l.toListL()).toList(),
      onDeleteTap: (row) async => await _onDeleteTap(row.first),
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

  Widget _buildToolbar() {
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
              if (!isConfirmed) return;

              for (final id in _selectedIds) {
                await ErrorLogCache().clearById(id);
              }

              _selectedIds.clear();
              _refreshLogs();
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

  Future<void> _onDeleteTap(String id) async {
    if (id.isEmpty) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (isConfirmed) {
      await ErrorLogCache().clearById(id);
      _refreshLogs();
    }
  }
}
