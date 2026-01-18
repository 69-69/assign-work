import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/models/item_master_model.dart';
import 'package:flutter/material.dart';

/// Costing Method Category [ItemCategoryDropdown]
class CostingMethodDropdown extends StatelessWidget {
  final String? label;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const CostingMethodDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = CostingMethodUtil.toStringList();
    // If label is provided, replace it with the first in the list
    if (label != null) strList[0] = label!;

    return StaticDropdown<String>(
      key: key,
      label: strList.first,
      initialValue: initialValue,
      items: strList,
      getDisplayText: (method) => method.toTitle,
      onChanged: onChanged,
    );
  }
}
