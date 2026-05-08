import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/util/extensions/price_list_types.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// PriceList types [PriceListTypeDropdown]
class PriceListTypeDropdown extends StatelessWidget {
  final String? label;
  final bool isService;
  final bool isDisabled;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const PriceListTypeDropdown({
    super.key,
    required this.onChanged,
    this.isDisabled = false,
    this.isService = false,
    this.initialValue,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = PriceListUtil.toStringList();
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
