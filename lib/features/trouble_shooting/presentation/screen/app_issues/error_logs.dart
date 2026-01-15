import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
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
    setState(() => _logs = ErrorLogCache().getLogs());
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
      rows: _logs.map((log) => log.itemAsList).toList(),
      selectedRowKeys: _selectedIds,
      onChecked: _onChecked,
      onAllChecked: _onAllChecked,
      onDeleteTap: (row) async => await _onDeleteTap(row.first),
    );
  }

  Widget _buildToolbar() {
    return ListToolbarButtons(
      refreshLabel: 'Refresh Logs',
      dangerLabel: 'Delete Log',
      dataLength: _logs.length,
      onRefresh: _refreshLogs,
      onDanger: _selectedIds.isNotEmpty
          ? () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (!isConfirmed) return;

              await ErrorLogCache().clearById(_selectedIds);

              _selectedIds.clear();
              _refreshLogs();
            }
          : null,
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
