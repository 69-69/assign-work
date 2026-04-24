import 'package:assign_erp/core/widgets/form/variant_attributes_dropdown.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:flutter/material.dart';

class VariantsMasterFormInputs {
  static List<FieldGroupConfig> get attributeFields => [
    FieldGroupConfig(
      key: 'type',
      label: 'Variant Attributes',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return VariantAttributesDropdown(
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'value',
      label: 'Value',
      type: TextInputType.text,
      helperText: 'Separate multiple values with comma (e.g.: Extra large, red, blue)',
    ),
    FieldGroupConfig(
      key: 'code',
      label: 'Code',
      type: TextInputType.none,
      validator: (_)=> null,
      helperText: 'E.g.: XL, RED, BLU)',
    ),
  ];
}
