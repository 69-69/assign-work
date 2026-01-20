import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// Address Type [AddressTypeDropdown]
class AddressTypeDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(String?) onChanged;
  final int? maxItems;

  const AddressTypeDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
    this.maxItems,
  });

  get _allItems => AddressTypeUtil.toStringList();

  @override
  Widget build(BuildContext context) {
    // Get the first 'maxItems' items from the list, else return all items
    final items = maxItems != null
        ? _allItems.take(maxItems! + 1).toList()
        : _allItems;

    return StaticDropdown<String>(
      label: 'Address Type',
      initialValue: initialValue,
      items: items,
      getDisplayText: (type) => type,
      onChanged: (type) => onChanged(type ?? ''),
    );
  }
}
