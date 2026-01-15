import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/files/file_doc_manager.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DynamicDataTable extends StatefulWidget {
  /// [omitAtIndex] The index of the column to exclude or hide from the DataTable.
  ///
  /// This value specifies the position of the column to be excluded from the UI,
  /// while still retaining the data in the underlying business logic. For instance,
  /// if `omitAtIndex` is set to `1`, the second column (index 1) in each row will be
  /// hidden from the table, but the data will remain accessible for any operations or
  /// further processing.
  final int? omitAtIndex;

  /// [maskAtIndex] The index of the column to mask sensitive data in the DataTable.
  ///
  /// This value specifies the position of the column to apply masking (e.g., showing
  /// asterisks or hiding sensitive values). When set, the data in that column will be
  /// masked or obfuscated in the table view, while still being available in the underlying
  /// data model for business logic.
  ///
  /// For example, if `maskAtIndex` is set to `2`, the third column (index 2) will display
  /// a masked version of its data in the table (e.g., "***" instead of a sensitive value).
  final int? maskAtIndex;

  /// Add any Widget to DataTable Top [toolbar]
  final Widget? toolbar;

  /// Any Widget Alignment [toolbarAlignment]
  final WrapAlignment toolbarAlignment;

  /// Edit / Update button icon [editIcon]
  final IconData? editIcon;

  /// Delete button icon [deleteIcon]
  final IconData? deleteIcon;

  /// Optional button icon [optButtonIcon]
  final IconData? optButtonIcon;

  /// Edit / Update button label [editLabel]
  final String? editLabel;

  /// Optional Button [optButtonLabel]
  final String? optButtonLabel;

  /// Delete button label [deleteLabel]
  final String? deleteLabel;

  /// DataTable header [headers]
  final List<String> headers;

  /// Main LIST of rows in the DataTable [rows]
  final List<List<String>> rows;

  /// Add LIST of children below the DataTable [childrenRow]
  final List<List<String>>? childrenRow;
  final Function(String, List<String>)? onCellTap;

  /// Optional Button onClick Action [onOptButtonTap]
  final Function(List<String>)? onOptButtonTap;

  /// If single CheckBox is selected Action [onChecked]
  final Function(bool?, List<String>)? onChecked;

  /// If All CheckBoxes are selected Action [onAllChecked]
  final Function(bool, List<bool>, List<List<String>>)? onAllChecked;

  /// Edit button onClick Action [onEditTap]
  final Function(List<String>)? onEditTap;

  /// Delete button onClick Action [onDeleteTap]
  final Function(List<String>)? onDeleteTap;

  /// View details via Link onClick Action [onViewDetailsTap]
  final Function(List<String>)? onViewDetailsTap;

  /// [selectedRowKeyIndex] OPTIONAL: The index of the column used to uniquely identify each row for selection tracking.
  ///
  /// This value is used to extract a "key" from each row in the table, typically used to
  /// determine which rows are selected or checked. The value at this column index in each row
  /// must be **unique and consistent**, but it doesn't have to be a database ID —
  /// it could be a name, email, or any other unique value.
  ///
  /// For example, if `selectedKeyIndex = 1`, and a row is `['1', 'john@example.com', 'John']`,
  /// then `'john@example.com'` is considered the row key.
  final int? selectedRowKeyIndex;

  /// [selectedRowKeys] OPTIONAL: A list of keys representing the rows that are currently selected (checked).
  ///
  /// Each key in this list is compared against the value found at `selectedRowKeyIndex`
  /// in each row. If there's a match, that row is considered "selected" and its checkbox
  /// will be checked.
  ///
  /// This allows external state to control row selection from outside the widget.
  ///
  /// For example:
  /// - If `selectedRowKeyIndex = 1`, and a row is `['1', 'john@example.com', 'John']`,
  ///   and `'john@example.com'` is in `selectedRowKeys`, then that checkbox is checked.
  final List<String>? selectedRowKeys;

  const DynamicDataTable({
    super.key,
    required this.headers,
    required this.rows,
    this.childrenRow,
    this.omitAtIndex,
    this.maskAtIndex,
    this.toolbar,
    this.editIcon,
    this.deleteIcon,
    this.optButtonIcon,
    this.editLabel,
    this.deleteLabel,
    this.optButtonLabel,
    this.onCellTap,
    this.onEditTap,
    this.onDeleteTap,
    this.onViewDetailsTap,
    this.onOptButtonTap,
    this.onChecked,
    this.onAllChecked,
    this.selectedRowKeyIndex,
    this.selectedRowKeys,
    this.toolbarAlignment = WrapAlignment.start,
  });

  @override
  State<DynamicDataTable> createState() => _DynamicDataTableState();
}

class _DynamicDataTableState extends State<DynamicDataTable> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horScrollController = ScrollController();
  final ScrollController _verScrollController = ScrollController();
  late List<bool> _selectedRowsStatus;
  bool _allSelectedStatus = false;
  bool _allVisibleRowIds = false;

  // state to track current sort column
  String? _currentSortColumn;

  // Track the index of the row with visible ID
  int? _visibleRowIdIndex;
  String _searchQuery = '';

  Function(bool, List<bool>, List<List<String>>)? get _onAllChecked =>
      widget.onAllChecked;

  int get totalRows => widget.rows.length + (widget.childrenRow?.length ?? 0);

  Function(bool?, List<String>)? get _onChecked => widget.onChecked;

  int? get _skipAtIndex => widget.omitAtIndex;

  int? get _maskAtIndex => widget.maskAtIndex;

  List<String> get _tableHeaders => widget.headers;

  // Toggle Specific Row Id
  void _toggleMask(int index) {
    setState(() {
      if (_visibleRowIdIndex == index) {
        _visibleRowIdIndex = null; // Hide if the same row is tapped again
      } else {
        _visibleRowIdIndex = index; // Show specific row ID
      }
    });
  }

  // Toggle All Row IDs
  void _toggleMaskAll() =>
      setState(() => _allVisibleRowIds = !_allVisibleRowIds);

  void _initializeSelectedRows() =>
      _selectedRowsStatus = List<bool>.filled(totalRows, false);

  void _toggleAllSelection(bool? value) {
    setState(() {
      _allSelectedStatus = value ?? false;
      for (int i = 0; i < _selectedRowsStatus.length; i++) {
        _selectedRowsStatus[i] = _allSelectedStatus;
      }

      // Notify if a callback is provided
      if (_onAllChecked != null && _selectedRowsStatus.hasValue) {
        _onAllChecked!(
          _allSelectedStatus,
          _selectedRowsStatus,
          _getSelectedRows(),
        );
      }
    });
  }

  // Update Search query/term
  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
  }

  // Get all checked or selected rows by _buildParentCheckbox()
  List<List<String>> _getSelectedRows() {
    final selectedRows = <List<String>>[];

    // Ensure the list sizes match
    if (_selectedRowsStatus.isEmpty) return selectedRows;

    int index = 0;

    // Iterate over regular rows
    for (int i = 0; i < widget.rows.length; i++) {
      if (index < _selectedRowsStatus.length && _selectedRowsStatus[index]) {
        selectedRows.add(widget.rows[i]);
      }
      index++;
    }

    // Iterate over child rows
    for (int j = 0; j < (widget.childrenRow?.length ?? 0); j++) {
      if (index < _selectedRowsStatus.length && _selectedRowsStatus[index]) {
        selectedRows.add(widget.childrenRow![j]);
      }
      index++;
    }

    // debugPrint('data-steve: $selectedRows');
    return selectedRows;
  }

  void _updateSelectedRowsForNewRowCount() {
    if (_selectedRowsStatus.length != totalRows) {
      // Adjust the size of _selectedRows to match the number of rows
      _initializeSelectedRows();
    }
  }

  // Search Func. for ChildRows [_filteredChildRows]
  List<List<String>> get _filteredChildRows {
    return _DataTableHelper.filterOnly(
      rows: widget.childrenRow ?? [],
      query: _searchQuery,
    );
  }

  List<List<String>> get _finalFilteredAndSortedRows {
    return _DataTableHelper.filterAndSort(
      rows: widget.rows,
      query: _searchQuery,
      headers: _tableHeaders,
      sortBy: _currentSortColumn,
    );
  }

  // Calculates rows per page based on available height [_rowsPerPageHeight]
  int get _rowsPerPageHeight {
    final maxVisible = context
        .getMaxVisibleHeight(itemCount: totalRows + 1, isRow: true)
        .toInt();
    return maxVisible;
    /* // Measure available height to determine rows per page
    const rowHeight = 56.0; // default DataRow height
    final availableHeight = context.screenHeight * 0.5;
    return (availableHeight ~/ rowHeight).clamp(1, totalRows + 1);*/
  }

  @override
  void initState() {
    super.initState();
    _initializeSelectedRows();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant DynamicDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If using external selection, sync internal state with selectedRowKeys
    if (widget.selectedRowKeys != null && widget.selectedRowKeyIndex != null) {
      final keyIndex = widget.selectedRowKeyIndex!;
      final newStatus = List<bool>.filled(totalRows, false);

      int i = 0;
      for (final row in [...widget.rows, ...(widget.childrenRow ?? [])]) {
        final key = (keyIndex >= 0 && keyIndex < row.length)
            ? row[keyIndex]
            : '';
        newStatus[i] = widget.selectedRowKeys!.contains(key);
        i++;
      }

      setState(() {
        _selectedRowsStatus = newStatus;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horScrollController.dispose();
    _verScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure _selectedRows list is correctly sized
    _updateSelectedRowsForNewRowCount();

    // Get the filtered & sorted rows
    final filteredAndSortedRows = _finalFilteredAndSortedRows;
    return SingleChildScrollView(
      child: _buildDataTableBody(filteredAndSortedRows, _filteredChildRows),
    );
  }

  Widget _buildDataTableBody(
    List<List<String>> filteredRows,
    List<List<String>> filteredChildRows,
  ) {
    final allRows = [...filteredRows, ...filteredChildRows];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20.0),
        _DataTableToolbar(
          headers: _tableHeaders,
          toolbar: widget.toolbar,
          toolbarAlignment: widget.toolbarAlignment,
          searchController: _searchController,
          currentSort: _currentSortColumn,
          onSortChanged: (column) {
            setState(() => _currentSortColumn = column);
          },
          onSelectedRows: _getSelectedRows,
        ),

        _buildPaginatedDataTable(context, allRows),
      ],
    );
  }

  Widget _buildPaginatedDataTable(
    BuildContext cxt,
    List<List<String>> allRows,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: cxt.screenWidth),
      child: IntrinsicWidth(
        // IntrinsicWidth: DataTable grow naturally
        child: PaginatedDataTable(
          showCheckboxColumn: false,
          rowsPerPage: _rowsPerPageHeight,
          showFirstLastButtons: true,
          headingRowColor: const WidgetStatePropertyAll(kGrayBlueColor),
          columns: _tableColumns(),
          source: _DataTableSource(
            parent: this,
            context: cxt,
            allRows: allRows,
            notifyParent: () => setState(() {}),
          ),
          onPageChanged: (firstRowIndex) {
            final pageNumber = (firstRowIndex ~/ _rowsPerPageHeight) + 1;
            final totalPages = (totalRows / _rowsPerPageHeight).ceil();

            final start = firstRowIndex + 1;
            final end = (start + _rowsPerPageHeight - 1).clamp(1, totalRows);

            context.showCustomSnackBar(
              bgColor: kBgLightColor,
              textAlign: TextAlign.center,
              'Page $pageNumber of $totalPages • Showing $start–$end of $totalRows Records',
            );
          },
        ),
      ),
    );
  }

  List<DataColumn> _tableColumns() {
    return _DataTableHeader(
      context: context,
      maskAtIndex: _maskAtIndex,
      skipAtIndex: _skipAtIndex,
      tableHeaders: _tableHeaders,
      allVisibleRowIds: _allVisibleRowIds,
      allSelectedStatus: _allSelectedStatus,
      editLabel: widget.editLabel,
      deleteLabel: widget.deleteLabel,
      optButtonLabel: widget.optButtonLabel,
      onEditTap: widget.onEditTap,
      onDeleteTap: widget.onDeleteTap,
      onOptButtonTap: widget.onOptButtonTap,
      toggleMaskAll: _toggleMaskAll,
      toggleAllSelection: _toggleAllSelection,
      totalChecked: _getSelectedRows().length,
    ).dataColumns();
  }

  /*
  Iterable<String> _excludeAtIndex(List<String> list) {
    final indicesToExclude = <int>{
      if (_maskAtIndex != null) _maskAtIndex!,
      if (_skipAtIndex != null) _skipAtIndex!,
    };

    return list
        .asMap()
        .entries
        .where((entry) => !indicesToExclude.contains(entry.key))
        .map((entry) => entry.value);
  }
  // Build DataTable Header
  List<DataColumn> _buildColumnHeaders(BuildContext context) {
    final columns = [
      // Toggle All CheckBoxes
      DataColumn(tooltip: 'Select all', label: _buildParentCheckbox()),

      // Toggle Multiple (mask/unmask) secrets in a  (e.g., IDs, any sensitive data)
      if (_maskAtIndex.isNotNullNorEmpty) ...{
        DataColumn(
          tooltip: 'Show ${_tableHeaders[_maskAtIndex!]}',
          label: _MaskButton(
            isHeader: true,
            value: _tableHeaders[_maskAtIndex!],
            isToggle: _allVisibleRowIds,
            onPressed: () => _toggleMaskAll(),
          ),
        ),
      },

      // Skip the first header
      ..._excludeAtIndex(
        _tableHeaders,
      ).map((header) => _buildDataColumn(header)),

      if (widget.onOptButtonTap != null) ...{
        _buildDataColumn(widget.optButtonLabel ?? 'Other'),
      },

      if (widget.onEditTap != null) ...{
        _buildDataColumn(widget.editLabel ?? 'Edit'),
      },

      if (widget.onDeleteTap != null) ...{
        _buildDataColumn(widget.deleteLabel ?? 'Delete'),
      },
    ];
    return columns;
  }
  Parent checkbox (Multiple check)
  Checkbox _buildParentCheckbox() {
    return Checkbox.adaptive(
      value: _allSelectedStatus,
      side: const BorderSide(width: 3.0, color: kWhiteColor),
      onChanged: _toggleAllSelection,
    );
  }

  /// Build Header Card
  DataColumn _buildDataColumn(String title) => DataColumn(
    tooltip: title,
    label: Text(
      title.toUpperAll,
      style: context.textTheme.titleMedium?.copyWith(color: kWhiteColor),
    ),
  );*/

  /// Build DataRow
  DataRow _buildDataRow({
    bool selected = false,
    required List<DataCell> cells,
    void Function(bool?)? onSelectChanged,
    WidgetStateProperty<Color?>? color,
  }) => DataRow(
    cells: cells,
    color: color,
    selected: selected,
    onSelectChanged: onSelectChanged,
  );

  /// Placeholder for empty cell
  _buildPlaceholder(BuildContext context) {
    final pColor = context.errorColor;
    return Tooltip(
      message: "Your update will replace this information.",
      decoration: const BoxDecoration(color: kDangerColor),
      child: Placeholder(
        strokeWidth: 0.2,
        fallbackHeight: 0.0,
        color: pColor,
        child: Text('Awaiting Update', style: TextStyle(color: pColor)),
      ),
    );
  }

  /// Determines if a row is selected based on external keys or internal state.
  bool _isRowChecked(int index, List<String> row) {
    final keyIndex = widget.selectedRowKeyIndex ?? 0;

    // Defensive fallback if index is out of range
    final rowKey = (keyIndex >= 0 && keyIndex < row.length)
        ? row[keyIndex]
        : '';

    // Use external selection if available, else fallback to internal state
    return widget.selectedRowKeys?.contains(rowKey) ??
        _selectedRowsStatus[index];
  }

  /// Build individual checkboxes
  DataCell _buildEachCheckBox(int index, List<String> row) {
    final isChecked = _isRowChecked(index, row);

    return DataCell(
      Checkbox.adaptive(
        value: isChecked,
        side: BorderSide(width: 1.0, color: context.onSurfaceColor),
        onChanged: (bool? selected) {
          // Update the selection status of the individual checkbox
          setState(() => _selectedRowsStatus[index] = selected ?? false);

          // Count how many checkboxes are selected
          int selectedCount = _selectedRowsStatus
              .where((status) => status)
              .length;

          // If two or more checkboxes are selected, call the `onAllChecked` callback
          if (selectedCount >= 2 && _onAllChecked != null) {
            _onAllChecked!(
              true, // or pass the actual "Select All" status if needed
              _selectedRowsStatus,
              _getSelectedRows(),
            );
          }

          // Notify the individual checkbox selection change if the callback is provided
          if (_onChecked != null) {
            _onChecked!(selected, row);
          }
        },
      ),
    );
  }

  List<DataCell> _buildRowCells(int index, List<String> row) {
    final cells = <DataCell>[];

    // Checkbox
    cells.add(_buildEachCheckBox(index, row));

    // Mask column
    if (_maskAtIndex != null) {
      cells.add(
        DataCell(
          _MaskToggleButton(
            value: row[_maskAtIndex!],
            isToggle: (_visibleRowIdIndex == index || _allVisibleRowIds),
            onPressed: () => _toggleMask(index),
          ),
        ),
      );
    }

    // Main data cells
    final indicesToExclude = <int>{
      if (_maskAtIndex != null) _maskAtIndex!,
      if (_skipAtIndex != null) _skipAtIndex!,
    };
    final entries = _DataTableHeader.excludeAtIndex(row, indicesToExclude);

    for (final entry in entries.toList().asMap().entries) {
      final colIndex = entry.key;
      final cellValue = entry.value;

      cells.add(
        widget.onViewDetailsTap != null && colIndex == 0
            ? _CellActionButton(
                tooltip: cellValue,
                color: context.onSurfaceColor,
                onTap: () => widget.onViewDetailsTap?.call(row),
              ).expand
            : DataCell(
                cellValue.isEmpty
                    ? _buildPlaceholder(context)
                    : context.copyPasteText(str: cellValue),
                onTap: () {
                  widget.onCellTap?.call(cellValue, row);
                },
              ),
      );
    }

    // Optional button
    if (widget.onOptButtonTap != null) {
      cells.add(
        _CellActionButton(
          icon: widget.optButtonIcon,
          tooltip: widget.optButtonLabel,
          onTap: () => widget.onOptButtonTap!(row),
          color: kWarningColor,
        ).option,
      );
    }

    // Edit button
    if (widget.onEditTap != null) {
      cells.add(
        _CellActionButton(
          tooltip: widget.editLabel,
          onTap: () => widget.onEditTap!(row),
        ).edit,
      );
    }

    // Delete button
    if (widget.onDeleteTap != null) {
      cells.add(
        _CellActionButton(
          tooltip: widget.deleteLabel,
          onTap: () => widget.onDeleteTap!(row),
        ).delete,
      );
    }

    return cells;
  }
}

class _DataTableHeader {
  final BuildContext context;
  final int? skipAtIndex;
  final int? maskAtIndex;
  final int? totalChecked;
  final bool allVisibleRowIds;
  final bool allSelectedStatus;
  final List<String> tableHeaders;
  final VoidCallback toggleMaskAll;
  final String? editLabel;
  final String? deleteLabel;
  final String? optButtonLabel;
  final Function(List<String>)? onEditTap;
  final Function(List<String>)? onDeleteTap;
  final Function(List<String>)? onOptButtonTap;
  final Function(bool?)? toggleAllSelection;

  const _DataTableHeader({
    this.maskAtIndex,
    this.skipAtIndex,
    this.totalChecked,
    required this.context,
    required this.tableHeaders,
    required this.allVisibleRowIds,
    required this.optButtonLabel,
    required this.editLabel,
    required this.deleteLabel,
    required this.onOptButtonTap,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.toggleMaskAll,
    required this.toggleAllSelection,
    required this.allSelectedStatus,
  });

  String get _totalChecked => (totalChecked ?? 0) > 0 ? '$totalChecked' : '';

  /// Build DataTable Header
  List<DataColumn> dataColumns() {
    final indicesToExclude = <int>{
      if (maskAtIndex != null) maskAtIndex!,
      if (skipAtIndex != null) skipAtIndex!,
    };

    final columns = [
      // Toggle All CheckBoxes
      DataColumn(
        tooltip: 'Select all',
        label: Row(
          children: [
            _buildParentCheckbox(),
            Text(_totalChecked, style: TextStyle(color: kWhiteColor)),
          ],
        ),
      ),

      if (maskAtIndex.hasValue) ...{_toggleMaskAll()},

      // Skip the first header
      ...excludeAtIndex(
        tableHeaders,
        indicesToExclude,
      ).map((header) => _buildDataColumn(header)),

      if (onOptButtonTap != null) ...{
        _buildDataColumn(optButtonLabel ?? 'Other'),
      },

      if (onEditTap != null) ...{_buildDataColumn(editLabel ?? 'Edit')},

      if (onDeleteTap != null) ...{_buildDataColumn(deleteLabel ?? 'Delete')},
    ];
    return columns;
  }

  // Toggle Multiple (mask/unmask) secrets in a  (e.g., IDs, any sensitive data)
  DataColumn _toggleMaskAll() {
    return DataColumn(
      tooltip: 'Show ${tableHeaders[maskAtIndex!]}',
      label: _MaskToggleButton(
        isHeader: true,
        value: tableHeaders[maskAtIndex!],
        isToggle: allVisibleRowIds,
        onPressed: toggleMaskAll,
      ),
    );
  }

  /// Excludes/Hides a value at a specific position from the UI but keeps it in the data layer or code.
  static Iterable<String> excludeAtIndex(
    List<String> list,
    Set<int> indicesToExclude,
  ) {
    return list
        .asMap()
        .entries
        .where((entry) => !indicesToExclude.contains(entry.key))
        .map((entry) => entry.value);
  }

  /// Parent checkbox (Multiple check)
  Checkbox _buildParentCheckbox() {
    return Checkbox.adaptive(
      value: allSelectedStatus,
      side: const BorderSide(width: 3.0, color: kWhiteColor),
      onChanged: toggleAllSelection,
      semanticLabel: 'Check all rows',
    );
  }

  /// Build Header Card
  DataColumn _buildDataColumn(String title) => DataColumn(
    tooltip: title,
    label: Text(
      title.toUpperAll,
      style: context.textTheme.titleMedium?.copyWith(color: kWhiteColor),
    ),
  );
}

class _DataTableToolbar extends StatelessWidget {
  final Widget? toolbar;
  final WrapAlignment toolbarAlignment;
  final TextEditingController searchController;
  final List<List<String>> Function() onSelectedRows;

  final List<String> headers;
  final String? currentSort;
  final Function(String? col) onSortChanged;

  const _DataTableToolbar({
    required this.toolbar,
    required this.toolbarAlignment,
    required this.searchController,
    required this.headers,
    required this.currentSort,
    required this.onSortChanged,
    required this.onSelectedRows,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: toolbarAlignment,
      children: [
        // Any custom widget above table (e.g., export buttons)
        _DataTableActionBar(
          headers: headers,
          toolbar: toolbar,
          selectedRows: onSelectedRows,
        ),

        // Search TextField
        _DataTableSearch(
          controller: searchController,
          onPressed: () => searchController.clear(),
        ),

        // Sort By Dropdown Button
        _SortByDropdown(
          headers: headers,
          initialSelection: currentSort,
          onSortChanged: onSortChanged,
        ),
      ],
    );
  }
}

/// [_DataTableSource] Data source for the PaginatedDataTable
class _DataTableSource extends DataTableSource {
  final BuildContext context;
  final VoidCallback notifyParent;
  final List<List<String>> allRows;
  final _DynamicDataTableState parent;

  _DataTableSource({
    required this.parent,
    required this.context,
    required this.allRows,
    required this.notifyParent,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= allRows.length) return null;

    final row = allRows[index];

    // This recreates EXACTLY the same DataRow your DataTable used.
    return parent._buildDataRow(
      selected: parent._selectedRowsStatus[index],
      onSelectChanged: (v) {
        /*parent.setState(() {
          parent._selectedRowsStatus[index] = v ?? false;
        });*/
        parent._selectedRowsStatus[index] = v ?? false;
        notifyParent(); // re-render parent widget safely

        // Same callback logic as inside your original code:
        if (parent.widget.onChecked != null) {
          parent.widget.onChecked!(v, row);
        }
      },
      cells: parent._buildRowCells(index, row),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => allRows.length;

  @override
  int get selectedRowCount => parent._selectedRowsStatus.where((e) => e).length;
}

/// [_DataTableHelper] for filtering and sorting
class _DataTableHelper {
  static List<List<String>> filterAndSort({
    required List<List<String>> rows,
    required String query,
    required List<String> headers,
    String? sortBy,
  }) {
    final filtered = _filterRows(rows, query);

    if (sortBy == null) return filtered;

    final columnIndex = headers.indexOf(sortBy);
    if (columnIndex == -1) return filtered;

    filtered.sort((a, b) {
      final valueA = a[columnIndex];
      final valueB = b[columnIndex];

      if (_isNumeric(valueA) && _isNumeric(valueB)) {
        return double.parse(valueA).compareTo(double.parse(valueB));
      } else if (_isValidDate(valueA) && _isValidDate(valueB)) {
        return _parseDate(valueA).compareTo(_parseDate(valueB));
      } else {
        return valueA.compareTo(valueB);
      }
    });

    return filtered;
  }

  static List<List<String>> filterOnly({
    required List<List<String>> rows,
    required String query,
  }) {
    return _filterRows(rows, query);
  }

  static List<List<String>> _filterRows(List<List<String>> rows, String query) {
    return rows
        .where(
          (row) =>
              row.any((cell) => cell.toLowerAll.contains(query.toLowerAll)),
        )
        .toList();
  }

  static bool _isNumeric(String value) => double.tryParse(value) != null;

  static bool _isValidDate(String value) {
    try {
      _parseDate(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  static DateTime _parseDate(String value) {
    final dateFormat = DateFormat("EEE, M/d/yyyy h:mm:ss a");
    return dateFormat.parse(value);
  }
}

/// [_DataTableSearch]
class _DataTableSearch extends StatelessWidget {
  final TextEditingController? controller;
  final void Function()? onPressed;

  const _DataTableSearch({this.controller, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.screenWidth,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: CustomTextField(
        controller: controller,
        keyboardType: TextInputType.text,
        inputDecoration: InputDecoration(
          labelText: 'Search...by date | any...',
          prefixIcon: const Icon(Icons.search, color: kGrayColor),
          suffixIcon: _buildSuffixIcon(),
        ),
      ),
    );
  }

  Wrap _buildSuffixIcon() {
    return Wrap(
      children: [
        if (controller!.text.isNotEmpty) ...{
          IconButton(
            tooltip: 'Clear Search',
            color: kGrayColor,
            onPressed: onPressed,
            icon: const Icon(Icons.clear),
            style: IconButton.styleFrom(shape: const RoundedRectangleBorder()),
          ),
        },
        DatePicker(
          isButton: true,
          restorationId: 'filter by date',
          selectedDate: (DateTime d) => controller?.text = d.dateOnly,
        ),
      ],
    );
  }
}

class _SortByDropdown extends StatelessWidget {
  final List<String> headers;
  final String? initialSelection;
  final ValueChanged<String> onSortChanged;

  const _SortByDropdown({
    required this.headers,
    this.initialSelection,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: StaticDropdown<String>(
        isMenu: true,
        label: 'Sort By...',
        icon: const Icon(Icons.sort),
        initialValue: initialSelection,
        items: ['Sort By...', ...headers],
        getDisplayText: (header) => header,
        onChanged: (v) {
          if (v != null) onSortChanged(v);
        },
        menuDecoration: InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        ),
      ),
    );
  }
}

class _DataTableActionBar extends StatelessWidget {
  final Widget? toolbar;
  final List<String> headers;
  final List<List<String>> Function() selectedRows;

  const _DataTableActionBar({
    required this.toolbar,
    required this.headers,
    required this.selectedRows,
  });

  @override
  Widget build(BuildContext context) {
    final exportBtn = _ExportButton(
      headers: headers,
      selectedRowsFunc: selectedRows,
    );

    return toolbar == null
        ? Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: exportBtn,
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [?toolbar, const SizedBox(width: 10.0), exportBtn],
            ),
          );
  }
}

/// Toggle a Single masked (e.g.: ID, ref) in a row [_MaskToggleButton]
/// For security, secrets (e.g.: ID, ref) are masked/obscured, unless toggled
class _MaskToggleButton extends StatelessWidget {
  final bool isToggle;
  final String value;
  final VoidCallback? onPressed;

  /// If true → acts like "Toggle All" header button.
  /// If false → acts like single row toggle.
  final bool isHeader;

  const _MaskToggleButton({
    required this.value,
    required this.isToggle,
    required this.onPressed,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      iconAlignment: IconAlignment.end,
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      icon: _buildIcon(),
      onPressed: onPressed,
      label: isHeader ? _buildHeaderLabel(context) : _buildRowLabel(context),
    );
  }

  Widget _buildRowLabel(BuildContext context) {
    return isToggle
        ? context.copyPasteText(str: value)
        : Text(
            '***',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.onSurfaceColor),
          );
  }

  Widget _buildHeaderLabel(BuildContext context) {
    return Text(
      value.toUpperAll,
      style: context.textTheme.titleMedium?.copyWith(
        color: kWhiteColor,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Icon _buildIcon() {
    final color = isHeader
        ? (isToggle ? kWhiteColor : kLightBlueColor)
        : (isToggle ? kGrayBlueColor : kGrayColor);

    return Icon(
      isToggle ? Icons.visibility : Icons.visibility_off,
      color: color,
    );
  }
}

/// Export data into Excel-sheet
class _ExportButton extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> Function() selectedRowsFunc;

  const _ExportButton({required this.headers, required this.selectedRowsFunc});

  @override
  Widget build(BuildContext context) {
    return _buildPrintBtn(context);
  }

  Widget _buildPrintBtn(BuildContext context) {
    final List<List<String>> selectedRows = selectedRowsFunc();

    return selectedRows.isEmpty
        ? const SizedBox.shrink()
        : context.toolbarButton(
            label: 'Export',
            icon: Icons.file_download,
            tooltip: 'Export Data to Excel or PDF',
            bgColor: kSuccessColor,
            onPressed: () async {
              final isExcel = await _buildPreference(context);
              prettyPrint('is-Excel', isExcel);
              if (isExcel == null) return;

              if (isExcel == true) {
                await FileDocManager.exportDataToExcel(
                  headers: headers,
                  data: selectedRows,
                );
              } else {
                await FileDocManager.exportDataToPdf(
                  headers: headers,
                  data: selectedRows,
                );
              }
            },
          );
  }

  // choice
  Future<dynamic> _buildPreference(BuildContext context) async {
    return await context.confirmAction<dynamic>(
      Text('Export data to Excel or PDF?'),
      title: 'Confirm Export',
      onAcceptLabel: 'Excel',
      onRejectLabel: 'PDF',
      anyAction: 'Cancel',
    );
  }
}

class _CellActionButton {
  final Color? color;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback onTap;

  const _CellActionButton({
    required this.onTap,
    this.tooltip,
    this.icon,
    this.color,
  });

  DataCell _dataCell(Widget child) => DataCell(child);

  IconButton _iconButton({Color? co, IconData? ic}) => IconButton(
    icon: Icon(icon ?? ic, color: co ?? color),
    onPressed: onTap,
    tooltip: tooltip,
    style: IconButton.styleFrom(
      padding: EdgeInsets.zero,
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      backgroundColor: (co ?? color)?.toAlpha(0.07),
    ),
  );

  get delete => _dataCell(_iconButton(ic: Icons.delete, co: kDangerColor));

  get edit => _dataCell(_iconButton(ic: Icons.edit, co: kPrimaryAccentColor));

  // get more => _dataCell(_iconButton(ic: Icons.more_horiz));
  // get export => _dataCell(_iconButton(ic: Icons.file_download));

  get expand => _dataCell(
    TextButton.icon(
      onPressed: onTap,
      label: Text(tooltip!, style: TextStyle(color: color)),
      iconAlignment: IconAlignment.end,
      icon: Icon(Icons.expand_more, color: color),
    ),
  );

  get viewDetails => _dataCell(_iconButton(ic: Icons.visibility));

  get option => _dataCell(_iconButton(ic: Icons.print));
}
