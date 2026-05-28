import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_link_model.dart';
import 'package:flutter/material.dart';

/// Supplier Status [SupplierStatusDropdown]
class SupplierStatusDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const SupplierStatusDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      label: 'Supplier Status',
      invalidPrefixes: ['supplier status'],
      initialValue: initialValue,
      items: SupplierLink.toStringList(),
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}
