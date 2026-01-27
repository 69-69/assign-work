import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/warehouse_model.dart';
import 'package:flutter/material.dart';

/// Warehouse Type [WarehouseTypeDropdown]
class WarehouseTypeDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(String?) onChanged;

  const WarehouseTypeDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    var label = 'Warehouse Type';
    return StaticDropdown<String>(
      key: key,
      label: label,
      initialValue: initialValue,
      items: WarehouseTypeUtil.toStringList(),
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}
