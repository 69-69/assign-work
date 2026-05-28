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
   List<String> _selectedIds = [];

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
    return DynamicDataTable2(
      maskAtIndex: 0,
      toolbar: _buildToolbar(),
      headers: ErrorLog.dataTableHeader,
      rows: _logs.map(_toTableRow).toList(),
      selectedRowKeys: _selectedIds,
      onSelectionChanged: (ids, rows) {
        setState(() => _selectedIds = ids);
      },
      onDeleteTap: (row) async => await _onDeleteTap(row.id),
    );
  }

  DataTableRow _toTableRow(ErrorLog e) =>
      DataTableRow.fromList(e.id ??'', e.itemAsList);

  Widget _buildToolbar() {
    return ListToolbarButtons(
      refreshLabel: 'Refresh',
      dangerLabel: 'Delete',
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
}
