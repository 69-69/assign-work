import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/setup/data/data_sources/remote/get_category.dart';
import 'package:assign_erp/features/setup/data/models/category_model.dart';
import 'package:flutter/material.dart';

/// Search Item Categories [SearchCategory]
class SearchCategory extends StatelessWidget {
  final String? initialValue;
  final Function(String, String) onChanged;

  const SearchCategory({super.key, this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Category>(
      labelText: (initialValue ?? 'Select Category...').toTitleCase,
      asyncItems: (String filter, loadProps) async =>
          await GetProductCategory.load(),
      filterFn: (category, filter) {
        var f = filter.isEmpty ? (initialValue ?? '') : filter;
        return category.filterByAny(f);
      },
      itemAsString: (category) => category.itemAsString,
      onChanged: (category) => onChanged(category!.id, category.name),
      validator: (category) => category == null ? 'Category is required' : null,
    );
  }
}
