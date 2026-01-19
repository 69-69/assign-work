import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/warehouse/widget/search_warehouse.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/widget/location_type_dropdown.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/inventory_form_fields.dart';
import 'package:flutter/material.dart';

class WhLocationFormFields {
  static Widget buildLocNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => InventoryFormFields.buildNumber(
    context,
    count: count,
    what: 'Location',
    onPressed: onPressed,
  );

  static List<FieldGroupConfig> whLocFields({
    Map<String, dynamic>? initial,
  }) => [
    FieldGroupConfig(
      key: 'description',
      label: 'Location Name',
      type: TextInputType.text,
      widgetType: FieldWidgetType.textField,
      helperText:
          'Enter the name of the location within the warehouse (e.g., Aisle 1, Rack B, Zone C).',
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'type',
      label: 'Location type',
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
      key: 'warehouseId',
      label: 'Parent Warehouse',
      helperText: 'Select the warehouse this location belongs to.',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return SearchWarehouses(
          initialValue: initialData,
          onChanged: (id, code, description) => onChanged(code),
        );
      },
    ),
    FieldGroupConfig(
      key: 'maxItems',
      label: 'Maximum Items',
      helperText: 'Maximum number of items this warehouse location can store.',
      type: TextInputType.number,
    ),
    FieldGroupConfig(
      key: 'maxWeight',
      label: 'Maximum Weight',
      helperText:
          'Maximum total weight this warehouse location can safely store.',
      type: TextInputType.number,
    ),
    FieldGroupConfig(
      key: 'isActive',
      label: 'Configuration Options',
      isNested: true,
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DynamicCheckboxList(
          title: 'Location Options',
          showButton: false,
          initialData: CheckboxGroupConfig.mapCheckboxes(initialData),
          checkboxesConfig: [
            CheckboxGroupConfig(
              key: 'isActive',
              label: 'Active',
              selected: initial?['isActive'] ?? true,
              tooltip: 'Enable or disable this item',
              description: 'Turn this on if the location is currently in use.',
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
