import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_category.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/category_model.dart';
import 'package:flutter/material.dart';

/// Remote Categories [RemoteCategoryDropdown]
class RemoteCategoryDropdown extends StatefulWidget {
  final bool isMultiSelect;

  final String? label;
  final String? helperText;

  final String? initialValue;
  final List<Category>? initialValues;

  final Function(String, String)? onChanged;
  final ValueChanged<List<Category>>? onMultiChanged;

  const RemoteCategoryDropdown({
    super.key,
    this.isMultiSelect = false,
    this.label,
    this.helperText,
    this.initialValue,
    this.initialValues,
    this.onChanged,
    this.onMultiChanged,
  });

  @override
  State<RemoteCategoryDropdown> createState() => _RemoteCategoryDropdownState();
}

class _RemoteCategoryDropdownState extends State<RemoteCategoryDropdown> {
  Category? _selectedCategory;
  List<Category>? _selectedCategories;

  String get _initialFilter => widget.initialValue ?? '';

  @override
  void initState() {
    super.initState();

    _selectedCategories = widget.initialValues;

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialCategory());
  }

  /// ---------------------------------------------------------------------------
  /// INITIAL LOAD
  /// ---------------------------------------------------------------------------

  Future<void> _loadInitialCategory() async {
    if (widget.isMultiSelect) return;

    final filter = _initialFilter;

    if (filter.isEmpty) return;

    final categories = await _fetchCategories(filter);

    if (mounted && categories.hasValue) {
      setState(() {
        _selectedCategory = categories.first;
      });
    }
  }

  /// ---------------------------------------------------------------------------
  /// REMOTE FETCH
  /// ---------------------------------------------------------------------------

  Future<List<Category>> _fetchCategories(String filter) async {
    if (filter.contains('*')) {
      return await GetProductCategory.load();
    }

    return await GetProductCategory.byAnyTerm(filter);
  }

  /// ---------------------------------------------------------------------------
  /// BUILD
  /// ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AsyncDropdown<Category>(
      isMultiSelect: widget.isMultiSelect,

      labelText: widget.label ?? 'Select Category...',

      helperText:
          widget.helperText ?? 'Enter * for all Categories, or type to search',

      selectedItem: !widget.isMultiSelect ? _selectedCategory : null,

      selectedMultiItems: widget.isMultiSelect ? _selectedCategories : null,

      asyncItems: (filter, loadProps) async {
        return await _fetchCategories(filter);
      },

      filterFn: _filterCategory,

      getDisplayText: (category) {
        return category.itemAsString;
      },

      /// SINGLE
      onChanged: (category) {
        widget.onChanged?.call(category!.id, category.name);
      },

      /// MULTI
      onMultiChanged: (categories) {
        setState(() => _selectedCategories = List<Category>.from(categories));

        widget.onMultiChanged?.call(categories);
      },

      validator: !widget.isMultiSelect
          ? (category) {
              return category == null ? 'Category is required' : null;
            }
          : null,

      validatorMulti: widget.isMultiSelect
          ? (categories) {
              return categories.isNullOrEmpty
                  ? 'Select at least one category'
                  : null;
            }
          : null,
    );
  }

  /// ---------------------------------------------------------------------------
  /// FILTER
  /// ---------------------------------------------------------------------------

  bool _filterCategory(Category category, String filter) {
    if (filter == '*') return true;

    final term = filter.isEmpty ? _initialFilter : filter;

    return category.filterByAny(term);
  }
}

/*class SearchCategory extends StatefulWidget {
  final String? initialValue;
  final Function(String, String) onChanged;

  const SearchCategory({super.key, this.initialValue, required this.onChanged});

  @override
  State<SearchCategory> createState() => _SearchCategoryState();
}

class _SearchCategoryState extends State<SearchCategory> {
  String? _initialValue;
  Category? _category;

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  Future _loadCategories() async {
    final filterBy = widget.initialValue ?? '';
    // If filter contains wildCard/asterisk '*', load all warehouses
    // Else load warehouses that match the filter
    final categories = await (filterBy.contains('*')
        ? GetProductCategory.load()
        : GetProductCategory.byAnyTerm(filterBy));
    if (filterBy.hasValue && categories.hasValue) {
      setState(() => _category = categories.first);
    }
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncDropdown<Category>(
      selectedItem: _category,
      labelText: 'Select Category...',
      helperText: 'Enter * for all Categories, or type to search',
      asyncItems: (String filter, loadProps) async => await _loadCategories(),
      filterFn: (category, filter) =>
          _filterCategory(filter, category, context),
      getDisplayText: (category) => category.itemAsString,
      onChanged: (category) => widget.onChanged(category!.id, category.name),
      validator: (category) => category == null ? 'Category is required' : null,
    );
  }

  bool _filterCategory(String filter, Category category, BuildContext context) {
    // If filter contains wildCard/asterisk '*', load all,
    // else load filtered if (filter == '*') return true;
    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = category.filterByAny(term);
    return matches;
  }
}*/
