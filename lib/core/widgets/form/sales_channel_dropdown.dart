import 'package:assign_erp/core/constants/sales_channel.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// Sales Channel [SalesChannelDropdown]
class SalesChannelDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const SalesChannelDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      label: 'Sales Channel',
      initialValue: initialValue,
      items: SalesChannelHelper.toStringList(),
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}
