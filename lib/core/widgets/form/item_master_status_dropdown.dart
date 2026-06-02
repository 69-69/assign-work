import 'package:assign_erp/core/util/extensions/item_master_status.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// Item Master Status [IMStatusDropdown]
class IMStatusDropdown extends StatelessWidget {
  final String? label;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const IMStatusDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = ItemMasterStatusUtil.toStringList();
    // If label is provided, replace it with the first in the list
    if (label != null) strList.first = label!;

    return StaticDropdown<String>(
      key: key,
      label: strList.first,
      initialValue: initialValue,
      items: strList,
      getDisplayText: (status) => status.toTitle,
      onChanged: onChanged,
    );
  }
}
