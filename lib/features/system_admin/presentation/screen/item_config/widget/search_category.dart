import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_category.dart';
import 'package:assign_erp/features/system_admin/data/models/category_model.dart';
import 'package:flutter/material.dart';

/// Search Item Categories [SearchCategory]
class SearchCategory extends StatefulWidget {
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
    final initial = widget.initialValue ?? '';
    final categories = await GetProductCategory.load();
    if (initial.hasValue && categories.hasValue) {
      setState(() => _category = categories.first);
    }
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Category>(
      selectedItem: _category,
      labelText: 'Select Category...',
      asyncItems: (String filter, loadProps) async => await _loadCategories(),
      filterFn: (category, filter) =>
          _filterCategory(filter, category, context),
      itemAsString: (category) => category.itemAsString,
      onChanged: (category) => widget.onChanged(category!.id, category.name),
      validator: (category) => category == null ? 'Category is required' : null,
    );
  }

  bool _filterCategory(String filter, Category category, BuildContext context) {
    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = category.filterByAny(term);
    return matches;
  }
}
