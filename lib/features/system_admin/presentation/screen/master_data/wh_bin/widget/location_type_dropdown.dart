import 'package:assign_erp/core/util/extensions/wh_location_type.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// Location Type (Sub-areas) [LocationTypeDropdown]
class LocationTypeDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(String?) onChanged;

  const LocationTypeDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      label: 'Location Type',
      // helperText: 'Physical location hierarchy used to track where inventory is stored',
      initialValue: initialValue,
      items: LocationTypeUtil.toStringList(),
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}
