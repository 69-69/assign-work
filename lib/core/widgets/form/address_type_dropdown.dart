import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// Address Type [AddressTypeDropdown]
class AddressTypeDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const AddressTypeDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      label: 'Address Type',
      initialValue: initialValue,
      items: AddressInfo.toStringList(),
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}
