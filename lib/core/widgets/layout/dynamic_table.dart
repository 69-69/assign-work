import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/file_doc_manager.dart';
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

  /// Add any Widget to DataTable Top [anyWidget]
  final Widget? anyWidget;

  /// Any Widget Alignment [anyWidgetAlignment]
  final WrapAlignment anyWidgetAlignment;

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
  final Function(List<String>)? onEditTap;
  final Function(List<String>)? onDeleteTap;

  const DynamicDataTable({
    super.key,
    required this.headers,
    required this.rows,
    this.childrenRow,
    this.omitAtIndex,
    this.maskAtIndex,
    this.anyWidget,
    this.editIcon,
    this.deleteIcon,
    this.optButtonIcon,
    this.editLabel,
    this.deleteLabel,
    this.optButtonLabel,
    this.onCellTap,
    this.onEditTap,
    this.onDeleteTap,
    this.onOptButtonTap,
    this.onChecked,
    this.onAllChecked,
    this.anyWidgetAlignment = WrapAlignment.start,
  });

  @override
  State<DynamicDataTable> createState() => _DynamicDataTableState();
}

class _DynamicDataTableState extends State<DynamicDataTable> {
  bool _allSelectedStatus = false;
  late List<bool> _selectedRowsStatus;
  bool _allVisibleRowIds = false;
  // Local variable to store the sorted rows
  // List<List<String>> _sortedRows = [];

  // Track the index of the row with visible ID
  int? _visibleRowIdIndex;
  String _searchQuery = '';
  // state to track current sort column
  String? _currentSortColumn;

  int get totalRows => widget.rows.length + (widget.childrenRow?.length ?? 0);
  int? get _skipAtIndex => widget.omitAtIndex;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horScrollController = ScrollController();
  final ScrollController _verScrollController = ScrollController();

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

  @override
  void initState() {
    super.initState();
    _initializeSelectedRows();
    _searchController.addListener(_onSearchChanged);
    // Initialize _sortedRows with the initial rows from widget
    // _sortedRows = [...widget.rows];
  }

  void _initializeSelectedRows() =>
      _selectedRowsStatus = List<bool>.filled(totalRows, false);

  void _toggleAllSelection(bool? value) {
    setState(() {
      _allSelectedStatus = value ?? false;
      for (int i = 0; i < _selectedRowsStatus.length; i++) {
        _selectedRowsStatus[i] = _allSelectedStatus;
      }

      // Notify if a callback is provided
      if (widget.onAllChecked != null &&
          _selectedRowsStatus.isNotNullNorEmpty) {
        widget.onAllChecked!(
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

  /// Search Func. for ChildRows [_filteredChildRows]
  List<List<String>> get _filteredChildRows {
    return DataTableHelper.filterOnly(
      rows: widget.childrenRow ?? [],
      query: _searchQuery,
    );
  }

  /// Get all checked or selected rows by _buildParentCheckbox()
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

  /*List<List<String>> _getSelectedRows2() {
    final selectedRows = <List<String>>[];

    // Ensure that the _selectedRows list is properly sized
    if (_selectedRowsStatus.isEmpty || widget.rows.isEmpty) {
      return selectedRows;
    }

    for (int i = 0; i < _selectedRowsStatus.length; i++) {
      if (i < widget.rows.length && _selectedRowsStatus[i]) {
        selectedRows.add(widget.rows[i]);
      }
    }

    return selectedRows;
  }*/

  void _updateSelectedRowsForNewRowCount() {
    if (_selectedRowsStatus.length != totalRows) {
      // Adjust the size of _selectedRows to match the number of rows
      _initializeSelectedRows();
    }
  }

  List<List<String>> get _finalFilteredAndSortedRows {
    return DataTableHelper.filterAndSort(
      rows: widget.rows,
      query: _searchQuery,
      headers: widget.headers,
      sortBy: _currentSortColumn,
    );
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
    return _buildBody(filteredAndSortedRows, _filteredChildRows);

    /*return CustomScrollBar(
      controller: _verScrollController,
      child: Wrap(
        alignment: widget.anyWidgetAlignment,
        children: [
          // Any custom widget above table (e.g., export buttons)
          _AnyWidget(
            headers: widget.headers,
            anyWidget: widget.anyWidget,
            selectedRows: _getSelectedRows,
          ),

          // Search TextField
          _SearchTextField(
            controller: _searchController,
            onPressed: () {
              _searchController.clear();
            },
          ),

          // Sort By Dropdown Button
          _SortByDropdown(
            headers: widget.headers,
            initialSelection: _currentSortColumn,
            onSortChanged: (column) {
              setState(() {
                _currentSortColumn = column;
              });
            },
          ),

          // Horizontal Scroll for DataTable
          CustomScrollBar(
            controller: _horScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 20.0),
            child: _buildDatatable(
              context,
              filteredAndSortedRows,
              _filteredChildRows,
            ),

            // _buildBody(context, _sortedRows, filteredChildRows),
          ),
        ],
      ),
    );*/
  }

  _buildBody(
    List<List<String>> filteredRows,
    List<List<String>> filteredChildRows,
  ) {
    return SizedBox(
      height: context.screenHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20.0),
          _headerWidgets(),

          // Horizontal Scroll for DataTable
          Expanded(
            child: SizedBox(
              width: context.screenWidth,
              child: CustomScrollBar(
                // Vertical Scroll for DataTable
                controller: _verScrollController,
                padding: EdgeInsets.only(
                  top: 5.0,
                  bottom: context.bottomInsetPadding,
                ),
                child: CustomScrollBar(
                  // Horizontal Scroll for DataTable
                  controller: _horScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: _buildDatatable(
                    context,
                    filteredRows,
                    _filteredChildRows,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Wrap _headerWidgets() {
    return Wrap(
      alignment: widget.anyWidgetAlignment,
      children: [
        // Any custom widget above table (e.g., export buttons)
        _AnyWidget(
          headers: widget.headers,
          anyWidget: widget.anyWidget,
          selectedRows: _getSelectedRows,
        ),

        // Search TextField
        _SearchTextField(
          controller: _searchController,
          onPressed: () => _searchController.clear(),
        ),

        // Sort By Dropdown Button
        _SortByDropdown(
          headers: widget.headers,
          initialSelection: _currentSortColumn,
          onSortChanged: (column) {
            setState(() => _currentSortColumn = column);
          },
        ),
      ],
    );
  }

  _buildDatatable(
    BuildContext context,
    List<List<String>> filteredRows,
    List<List<String>> filteredChildRows,
  ) {
    const textStyle = TextStyle(overflow: TextOverflow.ellipsis);

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: context.screenWidth),
      child: IntrinsicWidth(
        // Optional: lets DataTable grow naturally
        child: DataTable(
          // columnSpacing: context.screenWidth / widget.headers.length,
          showCheckboxColumn: false,
          border: const TableBorder(verticalInside: BorderSide(width: 0.1)),
          headingTextStyle: textStyle,
          dataTextStyle: textStyle,
          headingRowColor: const WidgetStatePropertyAll(kGrayBlueColor),
          columns: _buildColumns(context),
          rows: [
            ..._buildRows(context, rows: filteredRows),
            if (widget.childrenRow != null)
              ..._buildRows(
                context,
                rows: filteredChildRows,
                startIndex: filteredRows.length,
                color: WidgetStatePropertyAll(kDangerColor.toAlpha(0.1)),
              ),
          ],
        ),
      ),
    );
  }

  /// Excludes/Hides a value at a specific position from the UI but keeps it in the data layer or code.
  /*Iterable<String> _excludeTheFirstValue2(List<String> list) =>
      widget.skip ? list.skip(widget.skipAtIndex) : list;

     Iterable<String> _excludeAtIndex(List<String> list) =>
      _skipAtIndex.isNotNullNorEmpty
      ? List.generate(
          list.length,
          (i) => i,
        ).where((i) => i != _skipAtIndex).map((i) => list[i])
      : list;*/

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

  /// Build DataTable Header [_buildDataColumn]
  List<DataColumn> _buildColumns(BuildContext context) {
    final columns = [
      // Toggle All CheckBoxes
      DataColumn(tooltip: 'Select all', label: _buildParentCheckbox()),

      // Toggle Multiple (mask/unmask) secrets in a  (e.g., IDs, any sensitive data)
      if (_maskAtIndex.isNotNullNorEmpty) ...{
        DataColumn(
          tooltip: 'Show ${widget.headers[_maskAtIndex!]}',
          label: _ToggleMaskAllButton(
            headerValue: widget.headers[_maskAtIndex!],
            isToggle: _allVisibleRowIds,
            onPressed: () => _toggleMaskAll(),
          ),
        ),
      },

      // Skip the first header
      ..._excludeAtIndex(
        widget.headers,
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

  int? get _maskAtIndex => widget.maskAtIndex;

  /// Parent checkbox (Multiple check)
  Checkbox _buildParentCheckbox() {
    return Checkbox(
      value: _allSelectedStatus,
      side: const BorderSide(width: 3.0, color: kLightColor),
      onChanged: _toggleAllSelection,
    );
  }

  /// Build Header Card [_buildDataColumn]
  DataColumn _buildDataColumn(String title) => DataColumn(
    tooltip: title,
    label: Text(
      title.toUpperCaseAll,
      style: context.textTheme.titleMedium?.copyWith(color: kLightColor),
    ),
  );

  /// Build DataRow [_buildDataRow]
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

  /// Build DataTable Body [_buildRows]
  List<DataRow> _buildRows(
    BuildContext context, {
    int startIndex = 0,
    required List<List<String>> rows,
    WidgetStateProperty<Color?>? color,
  }) {
    return rows.asMap().entries.map((entry) {
      final index = startIndex + entry.key;
      final row = entry.value;

      // Return an empty DataRow if index is out of bounds
      if (index >= _selectedRowsStatus.length) {
        return _buildDataRow(cells: []);
      }

      return _buildDataRow(
        selected: _selectedRowsStatus[index],
        onSelectChanged: (bool? selected) {
          setState(() => _selectedRowsStatus[index] = selected ?? false);
        },
        cells: [
          // Individual Checkboxes
          _buildEachCheckBox(index, row),

          // Toggle Single (mask/unmask) secret (e.g., ID, any sensitive data)
          if (_maskAtIndex.isNotNullNorEmpty) ...{
            DataCell(
              _ToggleMaskButton(
                rowValue: row[_maskAtIndex!],
                isToggle: (_visibleRowIdIndex == index || _allVisibleRowIds),
                onPressed: () => _toggleMask(index),
              ),
            ),
          },

          // Data to display: Skip the first value in each row: ...row.skip(1)
          ..._excludeAtIndex(row).map((cell) {
            return DataCell(
              showEditIcon: false,
              cell.isNullOrEmpty
                  ? _buildPlaceholder(context)
                  : context.copyPasteText(str: cell),
              onTap: () {
                if (widget.onCellTap != null) {
                  widget.onCellTap!(cell, row);
                }
              },
            );
          }),
          // onOptButtonTap
          if (widget.onOptButtonTap != null) ...{
            DataCell(
              _OptButton(
                icon: widget.optButtonIcon,
                label: widget.optButtonLabel,
                onTap: () => widget.onOptButtonTap!(row),
              ),
            ),
          },
          // onEditTap
          if (widget.onEditTap != null) ...{
            DataCell(
              _EditButton(
                icon: widget.editIcon,
                label: widget.editLabel,
                onTap: () => widget.onEditTap!(row),
              ),
            ),
          },
          // onDeleteTap
          if (widget.onDeleteTap != null) ...{
            DataCell(
              _DeleteButton(
                icon: widget.deleteIcon,
                label: widget.deleteLabel,
                onTap: () => widget.onDeleteTap!(row),
              ),
            ),
          },
        ],
        color: color,
      );
    }).toList();
  }

  /// Placeholder for empty cell [_buildPlaceholder]
  _buildPlaceholder(BuildContext context) {
    final pColor = context.colorScheme.error;
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

  // Build individual checkboxes
  DataCell _buildEachCheckBox(int index, List<String> row) {
    return DataCell(
      Checkbox(
        value: _selectedRowsStatus[index],
        side: const BorderSide(width: 1.0),
        onChanged: (bool? selected) {
          // Update the selection status of the individual checkbox
          setState(() => _selectedRowsStatus[index] = selected ?? false);

          // Count how many checkboxes are selected
          int selectedCount = _selectedRowsStatus
              .where((status) => status)
              .length;

          // If two or more checkboxes are selected, call the `onAllChecked` callback
          if (selectedCount >= 2 && widget.onAllChecked != null) {
            widget.onAllChecked!(
              true, // or pass the actual "Select All" status if needed
              _selectedRowsStatus,
              _getSelectedRows(),
            );
          }

          // Notify the individual checkbox selection change if the callback is provided
          if (widget.onChecked != null) {
            widget.onChecked!(selected, row);
          }
        },
      ),
    );
  }

  /*DataCell _buildEachCheckBox2(int index, List<String> row) {
    return DataCell(
      Checkbox(
        value: _selectedRowsStatus[index],
        side: const BorderSide(width: 1.0),
        onChanged: (bool? selected) {
          /*setState(() {
            if (selected == true) {
              // Uncheck all except the currently selected
              for (int i = 0; i < _selectedRowsStatus.length; i++) {
                _selectedRowsStatus[i] = (i == index);
              }
            } else {
              // Allow unchecking the currently selected box
              _selectedRowsStatus[index] = false;
            }
          });*/
          // Notify if a callback is provided
          if (widget.onChecked != null) {
            widget.onChecked!(selected, row);
          }
          setState(() => _selectedRowsStatus[index] = selected ?? false);
        },
      ),
    );
  }*/
}

/// [_DataTableHelper] for filtering and sorting
class DataTableHelper {
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
          (row) => row.any(
            (cell) => cell.toLowercaseAll.contains(query.toLowercaseAll),
          ),
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

/// [_SearchTextField]
class _SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final void Function()? onPressed;

  const _SearchTextField({this.controller, this.onPressed});

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
          suffixIcon: Wrap(
            children: [
              if (controller!.text.isNotEmpty) ...{
                IconButton(
                  tooltip: 'Clear Search',
                  color: kGrayColor,
                  onPressed: onPressed,
                  icon: const Icon(Icons.clear),
                  style: IconButton.styleFrom(
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              },
              DatePicker(
                isButton: true,
                restorationId: 'filter by date',
                selectedDate: (DateTime d) => controller?.text = d.dateOnly,
              ),
            ],
          ),
        ),
      ),
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
        getValue: (header) => header,
        getDisplayText: (header) => header,
        onChanged: (value) {
          if (value != null) {
            onSortChanged(value);
          }
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

class _AnyWidget extends StatelessWidget {
  final Widget? anyWidget;
  final List<String> headers;
  final List<List<String>> Function() selectedRows;

  const _AnyWidget({
    required this.anyWidget,
    required this.headers,
    required this.selectedRows,
  });

  @override
  Widget build(BuildContext context) {
    return _body();
  }

  Widget _body() {
    final exportBtn = _ExportButton(
      headers: headers,
      selectedRowsFunc: selectedRows,
    );

    return anyWidget == null
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
              children: [?anyWidget, const SizedBox(width: 10.0), exportBtn],
            ),
          );
  }
}

/// Toggle a Single masked (e.g.: ID, ref) in a row [_ToggleMaskButton]
/// For security, secrets (e.g.: ID, ref) are masked/obscured, unless toggled
class _ToggleMaskButton extends StatelessWidget {
  final bool isToggle;
  final String rowValue;
  final void Function()? onPressed;

  const _ToggleMaskButton({
    required this.onPressed,
    required this.isToggle,
    required this.rowValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      iconAlignment: IconAlignment.end,
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      icon: Icon(
        isToggle ? Icons.visibility : Icons.visibility_off,
        color: isToggle ? kGrayBlueColor : kGrayColor,
      ),
      onPressed: onPressed,
      label: isToggle
          ? context.copyPasteText(str: rowValue)
          : const Text('***', overflow: TextOverflow.ellipsis),
    );
  }
}

/// Toggle All masked (e.g.: ID, ref) in a row [_ToggleMaskButton]
/// For security, secrets (e.g.: ID, ref) are masked/obscured, unless toggled
class _ToggleMaskAllButton extends StatelessWidget {
  final bool isToggle;
  final String headerValue;
  final void Function()? onPressed;

  const _ToggleMaskAllButton({
    required this.onPressed,
    required this.isToggle,
    required this.headerValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      iconAlignment: IconAlignment.end,
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      icon: Icon(
        isToggle ? Icons.visibility : Icons.visibility_off,
        color: isToggle ? kLightColor : kLightBlueColor,
      ),
      onPressed: onPressed,
      label: Text(
        headerValue.toUpperCaseAll,
        style: context.textTheme.titleMedium?.copyWith(
          color: kLightColor,
          overflow: TextOverflow.ellipsis,
        ),
        // textScaler: TextScaler.linear(context.textScaleFactor),
      ),
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
    return _buildEditBtn(context);
  }

  Widget _buildEditBtn(BuildContext context) {
    final List<List<String>> selectedRows = selectedRowsFunc();

    return selectedRows.isEmpty
        ? const SizedBox.shrink()
        : context.outlinedIconBtn(
            Icon(Icons.file_download, color: kPrimaryAccentColor),
            label: 'Export',
            borderColor: kPrimaryAccentColor,
            tooltip: 'Export Data to Excel or PDF',
            txtColor: kPrimaryAccentColor,
            onPressed: () async {
              final isExcel = await _buildPreference(context);
              prettyPrint('isExcel', isExcel);
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
      onAccept: 'Excel',
      onReject: 'PDF',
      anyAction: 'Cancel',
    );
  }
}

/// Optional-Action Button
class _OptButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final void Function() onTap;

  const _OptButton({required this.onTap, this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final text = label ?? 'Other';

    return context.outlinedIconBtn(
      Icon(icon ?? Icons.print, color: kWarningColor),
      borderColor: kWarningColor,
      onPressed: onTap,
      tooltip: text,
      label: Text(
        text,
        style: const TextStyle(
          color: kWarningColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Edit-Action Button
class _EditButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final void Function() onTap;

  const _EditButton({required this.onTap, this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return _buildEditBtn(context);
  }

  _buildEditBtn(BuildContext context) {
    final text = label ?? 'Edit';

    return context.outlinedIconBtn(
      Icon(icon ?? Icons.edit, color: kPrimaryAccentColor),
      borderColor: kPrimaryAccentColor,
      onPressed: onTap,
      tooltip: text,
      label: Text(
        text,
        style: const TextStyle(
          color: kPrimaryAccentColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Delete-Action Button
class _DeleteButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback onTap;

  const _DeleteButton({required this.onTap, this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return _buildDeleteBtn(context);
  }

  _buildDeleteBtn(BuildContext context) {
    final text = label ?? 'Delete';

    return context.elevatedIconBtn(
      Icon(icon ?? Icons.delete, color: kLightColor),
      bgColor: context.colorScheme.error,
      tooltip: text,
      onPressed: onTap,
      label: Text(
        text,
        style: const TextStyle(
          color: kLightColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
