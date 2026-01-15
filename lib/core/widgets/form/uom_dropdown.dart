import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// Unit of measure [UOMDropdown]
class UOMDropdown extends StatelessWidget {
  // final String? label;
  final bool isDisabled;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const UOMDropdown({
    super.key,
    required this.onChanged,
    this.isDisabled = false,
    this.initialValue,
    // this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = UOMUtil.toStringList();
    // If label is provided, replace it with the first in the list
    // if (label != null) strList[0] = label!;

    return IgnorePointer(
      ignoring: isDisabled,
      child: StaticDropdown<String>(
        key: key,
        label: strList.first,
        initialValue: initialValue,
        items: strList,
        getDisplayText: (uom) => uom.toTitle,
        onChanged: onChanged,
      ),
    );
  }
}
