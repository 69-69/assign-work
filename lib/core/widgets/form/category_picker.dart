import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/extensions/item_category.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';

/// [CategoryPicker] Local enum-based category picker (static data source).
class CategoryPicker extends StatefulWidget {
  final bool isMultiSelect;
  final bool? isService;
  final bool isDisabled;
  final bool allowManualEntry;

  final String? label;

  final String? initialValue;
  final List<String>? initialValues;

  final ValueChanged<String?>? onChanged;
  final ValueChanged<List<String>>? onMultiChanged;

  const CategoryPicker({
    super.key,
    this.isMultiSelect = false,
    this.isDisabled = false,
    this.allowManualEntry = false,
    this.label,
    this.isService,
    this.initialValue,
    this.initialValues,
    this.onChanged,
    this.onMultiChanged,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  bool _isNotFound = false;
  late List<String>? _selectedCategories;

  bool get _isMulti => widget.isMultiSelect;

  String get _labelText => widget.label ?? 'Category';
  late final List<String> _allCategories = ItemCategoryUtil.toStringList(
    isService: widget.isService,
  );

  List<String> get _invalidPrefixes => ['Category name'];

  @override
  void initState() {
    super.initState();
    _selectedCategories = widget.initialValues;
  }

  @override
  Widget build(BuildContext context) {
    if (_isNotFound && _allowManualEntry) {
      return _buildManualEntryField(context);
    }

    return _isMulti ? _buildMultiDropdown(context) : _buildSingleDropdown();
  }

  bool get _allowManualEntry => widget.allowManualEntry;

  /// ---------------------------------------------------------------------------
  /// SINGLE SELECT
  /// ---------------------------------------------------------------------------
  Widget _buildSingleDropdown() {
    if (widget.label != null) {
      _allCategories[0] = widget.label!;
    }

    return IgnorePointer(
      ignoring: widget.isDisabled,
      child: StaticDropdown<String>(
        key: widget.key,
        label: _allCategories.first,
        invalidPrefixes: _invalidPrefixes,
        initialValue: widget.initialValue,
        items: _allCategories,
        getDisplayText: (cat) => cat.toTitle,
        onChanged: (v) {
          if (v.filterAny('unknown') || v.filterAny('category')) {
            _handleNoDataFound(context);
            return;
          }
          widget.onChanged?.call(v);
        },
      ),
    );
  }

  /// ---------------------------------------------------------------------------
  /// MULTI SELECT
  /// ---------------------------------------------------------------------------
  Widget _buildMultiDropdown(BuildContext context) {
    return AsyncDropdown<String>(
      isMultiSelect: true,
      labelText: _labelText,
      selectedMultiItems: _selectedCategories,
      invalidPrefixes: _invalidPrefixes,

      asyncItems: (filter, loadProps) async {
        return _loadCategories(filter);
      },

      filterFn: _filterCategories,

      getDisplayText: (cat) => cat.toTitle,

      onMultiChanged: (values) {
        if (values.filterAny('unknown') || values.filterAny('category')) {
          _handleNoDataFound(context);
          return;
        }
        setState(() => _selectedCategories = List.from(values));
        widget.onMultiChanged?.call(values);
      },

      validatorMulti: (values) {
        return values.isNullOrEmpty ? 'Select at least one Category' : null;
      },

      helperText: 'Enter to search, select one or more categories',

      onNoDataFound: () {
        if (_allowManualEntry) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _handleNoDataFound(context),
          );
        }
      },
    );
  }

  /// ---------------------------------------------------------------------------
  /// MANUAL ENTRY
  /// ---------------------------------------------------------------------------
  Widget _buildManualEntryField(BuildContext context) {
    return CustomTextField(
      onChanged: (value) {
        widget.onMultiChanged?.call([value]);
      },

      textInputType: TextInputType.text,

      inputDecoration: InputDecoration(
        labelText: 'Category name',

        suffixIcon: Padding(
          padding: const EdgeInsets.all(2),

          child: context.iconButton(
            Icons.arrow_back,
            tooltip: 'Back to Category search',

            onPressed: () => _toggleManualEntry(false),

            bgColor: kGrayColor,
          ),
        ),
      ),
    );
  }

  /// ---------------------------------------------------------------------------
  /// HELPERS
  /// ---------------------------------------------------------------------------
  List<String> _loadCategories(String filter) {
    if (filter.isEmpty) return _allCategories;

    return _allCategories.where((c) => c.filterAny(filter)).toList();
  }

  bool _filterCategories(String c, String term) => c.filterAny(term);

  void _toggleManualEntry([bool value = true]) {
    if (mounted) {
      setState(() => _isNotFound = value);
    }
  }

  Future<void> _handleNoDataFound(BuildContext context) async {
    final shouldEnterManually = await context.confirmAction<bool>(
      const Text('Do you want to enter it manually?'),
      title: 'Category not found',
    );

    if (context.mounted && shouldEnterManually) {
      _toggleManualEntry();
    }
  }
}

/*class NewCategoryDropdown extends StatelessWidget {
  final String? label;
  final bool isService;
  final bool isDisabled;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const NewCategoryDropdown({
    super.key,
    required this.onChanged,
    this.isDisabled = false,
    this.isService = false,
    this.initialValue,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = ItemCategoryUtil.toStringList(isService: isService);
    // If label is provided, replace it with the first in the list
    if (label != null) strList[0] = label!;

    return IgnorePointer(
      ignoring: isDisabled,
      child: StaticDropdown<String>(
        key: key,
        label: strList.first,
        invalidPrefixes: ['Service', 'Material', 'Category'],
        initialValue: initialValue,
        items: strList,
        getDisplayText: (category) => category.toTitle,
        onChanged: onChanged,
      ),
    );
  }
}

class NewCatMultiDropdown extends StatefulWidget {
  final Function(List<String>) onMultiChanged;
  final List<String>? initialValues;
  final bool allowManualEntry;
  final String? label;

  const NewCatMultiDropdown({
    super.key,
    required this.onMultiChanged,
    this.allowManualEntry=false,
    this.initialValues,
    this.label,
  });

  @override
  State<NewCatMultiDropdown> createState() => _NewCatMultiDropdownState();
}

class _NewCatMultiDropdownState extends State<NewCatMultiDropdown> {
  bool _isNotFound = false;
  late List<String>? _selectedCategories;
  Function get _onMultiChanged => widget.onMultiChanged;
  bool get _allowManualEntry => widget.allowManualEntry;
  String get _labelText => widget.label ?? 'New Category';
  final List<String> _allCategories = ItemCategoryUtil.toStringList();

  @override
  void initState() {
    super.initState();
    _selectedCategories = widget.initialValues;
  }

  @override
  Widget build(BuildContext context) {
    return _isNotFound && _allowManualEntry
        ? _buildManualEntryField(context)
        : _buildDropdown(context);
  }

  AsyncSearchDropdown<String> _buildDropdown(BuildContext context) {
    return AsyncSearchDropdown<String>(
    isMultiSelect: true,
    labelText: _labelText,
    selectedMultiItems: _selectedCategories,
    invalidPrefixes: ['New Category'],
    asyncItems: (String filter, loadProps) async => _loadCategories(filter),
    filterFn: _filterCategories,
    getDisplayText: (String cat) => cat.toTitle,
    onMultiChanged: (List<String> units) {
      setState(() => _selectedCategories = List.from(units));
      _onMultiChanged.call(units); // notify parent
    },
    validatorMulti: (units) =>
        units.isNullOrEmpty ? 'Select at least one Category' : null,
    helperText: 'Enter to search, select one or more categories',
    onNoDataFound: () {
      if (_allowManualEntry) {
        WidgetsBinding.instance.addPostFrameCallback(
              (_) => _handleNoDataFound(context),
        );
      }
    },
  );
  }

  /// Load Categories filtered by search string
  List<String> _loadCategories(String filter) {
    // If no filter, return full list
    if (filter.isEmpty) return _allCategories;

    // Filter using generic `filterAny` on the category label
    return _allCategories.where((c) => c.filterAny(filter)).toList();
  }

  /// Used by AsyncSearchDropdown for real-time filtering
  bool _filterCategories(String cat, String filter) => cat.filterAny(filter);

  Widget _buildManualEntryField(BuildContext context) {
    return CustomTextField(
      onChanged: (value) => _onMultiChanged.call([value]),
      keyboardType: TextInputType.text,
      inputDecoration: InputDecoration(
        labelText: 'Category name',
        suffixIcon: Padding(
          padding: const EdgeInsets.all(2.0),
          child: context.iconButton(
            Icons.arrow_back,
            tooltip: 'Back to Category search',
            onPressed: () => _toggleManualEntry(false),
            bgColor: kGrayColor,
          ),
        ),
      ),
    );
  }

  void _toggleManualEntry([bool value = true]) {
    if (mounted) setState(() => _isNotFound = value);
  }

  Future<void> _handleNoDataFound(BuildContext context) async {
    final shouldEnterManually = await context.confirmAction<bool>(
      const Text('Do you want to enter it manually?'),
      title: 'Category not found',
    );

    if (context.mounted && shouldEnterManually) {
      _toggleManualEntry();
    }
  }
}*/
