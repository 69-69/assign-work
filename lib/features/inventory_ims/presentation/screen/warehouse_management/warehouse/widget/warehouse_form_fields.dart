import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/warehouse/widget/warehouse_type_dropdown.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/inventory_form_fields.dart';
import 'package:flutter/material.dart';

class WarehouseFormFields {
  static Widget buildIMNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => InventoryFormFields.buildNumber(
    context,
    count: count,
    what: 'Warehouse',
    onPressed: onPressed,
  );

  /// Warehouse physical Address
  static List<FieldGroupConfig> wmsFields(Map<String, dynamic>? initial) => [
    FieldGroupConfig(
      key: 'name',
      label: 'Warehouse Name',
      type: TextInputType.text,
      widgetType: FieldWidgetType.textField,
      helperText:
          'Enter a descriptive name for the warehouse (e.g., Main Warehouse, Store 01).',
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'type',
      label: 'Warehouse type',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return WarehouseTypeDropdown(
          initialValue: initialData,
          onChanged: onChanged,
        );
      },
    ),
    FieldGroupConfig(
      key: 'options',
      label: 'Configuration Options',
      isNested: true,
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DynamicCheckboxList(
          title: 'Warehouse Options',
          showButton: false,
          initialData: CheckboxGroupConfig.mapCheckboxes(initialData),
          checkboxesConfig: [
            CheckboxGroupConfig(
              key: 'isActive',
              label: 'Active',
              selected: initialData?['isActive'] ?? true,
              tooltip: 'Enable or disable this item',
              description: 'Turn this on if the warehouse is currently in use.',
            ),
            CheckboxGroupConfig(
              key: 'isDefault',
              label: 'Default Warehouse',
              selected: initialData?['isDefault'] ?? false,
              tooltip: 'Set as default warehouse',
              description:
                  'If selected, this will be used as the default option when creating new transactions.',
            ),
            CheckboxGroupConfig(
              key: 'isBinManaged',
              label: 'Track Bins',
              selected: initialData?['isBinManaged'] ?? false,
              tooltip: 'Enable bin tracking',
              description:
                  'Turn on to manage individual bins for this location (e.g., BIN-01, BIN-02).',
            ),
          ],
          onCheckChanged: (List<CheckboxGroupConfig> selected) {
            final mapList = CheckboxGroupConfig.mapCheckboxes(selected);
            onChanged(mapList);
          },
        );
      },
    ),
    FieldGroupConfig(
      key: 'type',
      label: 'Address Type',
      type: TextInputType.text,
      widgetType: FieldWidgetType.textField,
      isHidden: true,
    ),
    FieldGroupConfig(
      key: 'postalCode',
      label: 'postal Code',
      type: TextInputType.text,
    ),
    FieldGroupConfig(key: 'city', label: 'city', type: TextInputType.text),
    FieldGroupConfig(
      key: 'state',
      label: 'state / region',
      type: TextInputType.text,
    ),
    FieldGroupConfig(
      key: 'address',
      label: 'Street Address...',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
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
