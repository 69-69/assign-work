import 'package:assign_erp/core/util/extensions/discount_type.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// Discount types [PricingTypeDropdown]
class DiscountTypeDropdown extends StatelessWidget {
  final String? label;
  final bool isService;
  final bool isDisabled;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const DiscountTypeDropdown({
    super.key,
    required this.onChanged,
    this.isDisabled = false,
    this.isService = false,
    this.initialValue,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = DiscountTypeUtil.toStringList();
    // If label is provided, replace it with the first in the list
    if (label != null) strList[0] = label!;

    return IgnorePointer(
      ignoring: isDisabled,
      child: StaticDropdown<String>(
        key: key,
        label: strList.first,
        initialValue: initialValue,
        items: strList,
        getDisplayText: (type) => type.toTitle,
        onChanged: onChanged,
      ),
    );
  }
}
