import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:flutter/material.dart';

extension HistoryViewExtensions on BuildContext {
  Future showHistoryDialog<T>({
    required String title,
    required List<String> columnLabels,
    required List<T> items,
    required DataRow Function(T) rowBuilder,
  }) async => await confirmDone(
    items.isEmpty
        ? const Text('No data available yet!')
        : HistoryDataTable<T>(
            columnLabels: columnLabels,
            items: items,
            rowBuilder: rowBuilder,
          ),
    title: title,
    onDone: 'Done',
  );

  Future showInlineHistorySheet<T>({
    required String title,
    required List<String> columnLabels,
    required List<T> items,
    required DataRow Function(T) rowBuilder,
  }) async => await openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    constraints: BoxConstraints(maxWidth: dynamicWidth(0.5)),
    child: FormBottomSheet(
      title: title,
      isDetails: true,
      initialSize: 0.6,
      body: InlineHistoryTable<T>(
        items: items,
        columnLabels: columnLabels,
        rowBuilder: rowBuilder,
      ),
    ),
  );
}

class HistoryDataTable<T> extends StatelessWidget {
  final List<String> columnLabels;
  final List<T> items;
  final DataRow Function(T) rowBuilder;

  const HistoryDataTable({
    super.key,
    required this.columnLabels,
    required this.items,
    required this.rowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        horizontalMargin: 8,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 32,
        headingRowHeight: 30,
        columns: columnLabels
            .map(
              (label) => DataColumn(
                label: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(),
        rows: items.map(rowBuilder).toList(),
      ),
    );
  }
}

/*
USAGE:
InlineHistoryTable(
  columnLabels: ["Area", "Time"],
  items: attendance.areasViewed,
  rowBuilder: (entry) {
    final parts = entry.split("@");
    return DataRow(cells: [
      DataCell(Text(parts[0].trim())),
      DataCell(Text(parts[1])),
    ]);
  },
  sortAccessors: [
    (entry) => entry.split("@")[0].trim(),   // Area sort
    (entry) => entry.split("@")[1],          // Time sort
  ],
  rowStyle: (entry) {
  if (entry.contains("alert")) {
    return DataRow(
      color: WidgetStateProperty.all(Colors.red.withOpacity(0.1)),
      cells: [
        DataCell(Text("⚠ ${entry.split('@')[0].trim()}",
            style: const TextStyle(color: Colors.red))),
        DataCell(Text(entry.split('@')[1])),
      ],
    );
  }
  return null; // fallback to default
},

);*/

/// [InlineHistoryTable] A widget that displays a list of items in a paginated, sortable table
/// suitable for showing history or audit data inline in a modal bottom sheet.
class InlineHistoryTable<T> extends StatefulWidget {
  /// [title] Optional title for the table (not currently used in PaginatedDataTable header)
  final String? title;

  /// [items] The data items to display in the table
  final List<T> items;

  /// [headingRowColor] Optional color for the heading row
  final Color? headingRowColor;

  /// [columnLabels] The column labels to display
  final List<String> columnLabels;

  /// [rowBuilder] Builds a DataRow from a single item
  final DataRow Function(T) rowBuilder;

  /// [rowStyle] Optional function to provide row-level styles or overrides
  final DataRow? Function(T)? rowStyle;

  /// [sortAccessors] Optional list of accessors used for sorting each column
  final List<Comparable Function(T)>? sortAccessors;

  const InlineHistoryTable({
    super.key,
    required this.items,
    required this.rowBuilder,
    required this.columnLabels,
    this.title,
    this.rowStyle,
    this.sortAccessors,
    this.headingRowColor,
  });

  @override
  State<InlineHistoryTable<T>> createState() => _InlineHistoryTableState<T>();
}

class _InlineHistoryTableState<T> extends State<InlineHistoryTable<T>> {
  /// Internal mutable copy of items to allow sorting
  late List<T> _items;

  /// Index of the currently sorted column
  int? _sortColumnIndex;

  /// Whether the current sort is ascending
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    // Make a mutable copy of the input items
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant InlineHistoryTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _items = List.from(widget.items);
      if (_sortColumnIndex != null) {
        _sort(_sortColumnIndex!, _ascending);
      }
    }
  }

  /// Handles sorting of the table by a given column index
  void _sort(int index, bool ascending) {
    if (widget.sortAccessors == null || index >= widget.sortAccessors!.length) {
      // No sort accessor provided for this column
      return;
    }

    final accessor = widget.sortAccessors![index];

    setState(() {
      _sortColumnIndex = index;
      _ascending = ascending;

      // Sort the items in-place
      _items.sort((a, b) {
        final aVal = accessor(a);
        final bVal = accessor(b);

        return ascending
            ? Comparable.compare(aVal, bVal)
            : Comparable.compare(bVal, aVal);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      // If there is no data, display a placeholder message
      return _buildNoData();
    }

    // Otherwise display the paginated data table
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: context.screenWidth),
        child: IntrinsicWidth(
          // Lets the table grow naturally to fit content
          child: _buildPaginatedDataTable(),
        ),
      ),
    );
  }

  SizedBox _buildNoData() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'No data available!',
          style: TextStyle(fontSize: 16, color: kGrayColor),
        ),
      ),
    );
  }

  /// Builds the PaginatedDataTable widget
  PaginatedDataTable _buildPaginatedDataTable() {
    return PaginatedDataTable(
      header: _buildTitle(),
      rowsPerPage: _rowsPerPageHeight, // number of rows per page
      showCheckboxColumn: false,
      sortColumnIndex: _sortColumnIndex, // current sorted column
      sortAscending: _ascending, // current sort direction
      showFirstLastButtons: true, // show navigation buttons for pages
      columns: _buildColumnHeaders(), // build columns
      headingRowColor: WidgetStateProperty.all(
        widget.headingRowColor ?? context.secondaryContainerColor,
      ),
      source: _HistorySource<T>(
        items: _items,
        rowStyle: widget.rowStyle,
        rowBuilder: widget.rowBuilder,
      ),
    );
  }

  Text? _buildTitle() {
    return widget.title == null
        ? null
        : Text(
            widget.title ?? '',
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge,
          );
  }

  /// Calculates the number of rows per page based on available height [_rowsPerPageHeight]
  int get _rowsPerPageHeight {
    // Measure available height to determine rows per page
    const rowHeight = 56.0; // default DataRow height
    final totalRows = _items.length;
    final availableHeight = context.screenHeight * 0.5;
    return (availableHeight ~/ rowHeight).clamp(1, totalRows);
  }

  /// Builds the table columns with optional sorting
  List<DataColumn> _buildColumnHeaders() {
    return [
      for (int i = 0; i < widget.columnLabels.length; i++)
        DataColumn(
          label: Text(
            widget.columnLabels[i],
            style: TextStyle(color: context.onSurfaceColor),
          ),
          onSort:
              (widget.sortAccessors != null && i < widget.sortAccessors!.length)
              ? (colIndex, asc) => _sort(colIndex, asc)
              : null,
        ),
    ];
  }
}

/// [_HistorySource] Data source for the PaginatedDataTable
class _HistorySource<T> extends DataTableSource {
  /// [items] List of items to display
  final List<T> items;

  /// [rowBuilder] Function to build a DataRow from an item
  final DataRow Function(T) rowBuilder;

  /// [rowStyle] Optional function to override the row style
  final DataRow? Function(T)? rowStyle;

  _HistorySource({
    required this.items,
    required this.rowBuilder,
    this.rowStyle,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;

    final item = items[index];

    // Allow row-level style overrides
    final styled = rowStyle?.call(item);
    return styled ?? rowBuilder(item);
  }

  @override
  bool get isRowCountApproximate => false; // exact row count

  @override
  int get rowCount => items.length;

  @override
  int get selectedRowCount => 0; // no row selection
}
