import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_location_model.dart';
import 'package:flutter/material.dart';

/// Zone-Type [ZoneTypeDropdown]
class ZoneTypeDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(String?) onChanged;

  const ZoneTypeDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      label: 'Zone Type',
      initialValue: initialValue,
      items: ZoneTypeUtil.toStringList(),
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}
