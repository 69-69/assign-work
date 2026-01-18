import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/widget/location_type_dropdown.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/inventory_form_fields.dart';
import 'package:flutter/material.dart';

class WHBinFormFields {
  static Widget buildIMNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => InventoryFormFields.buildNumber(
    context,
    count: count,
    what: 'Bin',
    onPressed: onPressed,
  );

  static List<FieldGroupConfig> whBinFields(Map<String, dynamic>? initial) => [
    FieldGroupConfig(
      key: 'name',
      label: 'Bin Name',
      type: TextInputType.text,
      widgetType: FieldWidgetType.textField,
      helperText: 'Name for this bin (e.g., Shelf A01, Slot B03).',
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'capacity',
      label: 'Capacity',
      type: TextInputType.text,
      widgetType: FieldWidgetType.textField,
      helperText: 'Maximum number of items this bin can hold (optional)',
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'sequence',
      label: 'Display Order',
      type: TextInputType.number,
      widgetType: FieldWidgetType.textField,
      helperText:
          'The order this bin appears in lists or pick routes (optional)',
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'locationId',
      label: 'Location',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return LocationTypeDropdown(
          initialValue: initialData,
          onChanged: onChanged,
        );
      },
    ),
    FieldGroupConfig(
      key: 'isActive',
      label: 'Configuration Options',
      isNested: true,
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DynamicCheckboxList(
          title: 'Bin Options',
          showButton: false,
          initialData: CheckboxGroupConfig.mapCheckboxes(initialData),
          checkboxesConfig: [
            CheckboxGroupConfig(
              key: 'isActive',
              label: 'Active',
              selected: initialData?['isActive'] ?? true,
              tooltip: 'Enable or disable this bin',
              description:
                  'Turn this on if the bin is currently in use for storing items.',
            ),
          ],
          onCheckChanged: (List<CheckboxGroupConfig> selected) {
            final mapList = CheckboxGroupConfig.mapCheckboxes(selected);
            onChanged(mapList);
          },
        );
      },
    ),
  ];

  /// Updates the [list] with objects of type [T] from a list of maps.
  /// Clears the list first to prevent duplication, then adds new objects.
  /// [fromMap] converts each map entry into an object with the index as the ID.
  static updateListFromData<T>(
    List<T> list, {
    required List<Map<String, dynamic>> map,
    required T Function(Map<String, dynamic>, String) fromMap,
  }) =>
      InventoryFormFields.updateListFromData(list, map: map, fromMap: fromMap);
}
