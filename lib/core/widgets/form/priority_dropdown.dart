import 'package:assign_erp/core/util/extensions/erp_priority_enum.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

class PriorityDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const PriorityDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final strList = PriorityUtil.toStringList();

    return StaticDropdown<String>(
      key: key,
      label: 'priority',
      initialValue: initialValue,
      items: strList,
      getDisplayText: (priority) => priority,
      onChanged: onChanged,
    );
  }
}
