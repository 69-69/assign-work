import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/form/category_picker.dart';
import 'package:assign_erp/core/widgets/form/uom_dropdown.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/warehouse/widget/warehouse_type_dropdown.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/inventory_form_fields.dart';
import 'package:flutter/material.dart';

class WarehouseFormFields {
  static Widget buildWHNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => InventoryFormFields.buildNumber(
    context,
    count: count,
    what: 'Warehouse Code',
    onPressed: onPressed,
  );

  /// Warehouse Basic
  static List<FieldGroupConfig> wmsFields(Map<String, dynamic>? initial) => [
    FieldGroupConfig(
      key: 'description',
      label: 'Warehouse Name',
      type: TextInputType.text,
      widgetType: FieldWidgetType.textField,
      helperText:
          'Descriptive name for the warehouse (e.g., Main Warehouse, Store 01).',
    ),
    FieldGroupConfig(
      key: 'wareType',
      label: 'Warehouse s type',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      customBuilder: ({required initialData, required onChanged}) {
        return WarehouseTypeDropdown(
          initialValue: initialData,
          onChanged: onChanged,
        );
      },
    ),
    FieldGroupConfig(
      key: 'whOptions',
      label: 'Configuration Options',
      isNested: true,
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DynamicCheckboxList(
          title: 'Warehouse Options',
          initialData: CheckboxGroupConfig.mapCheckboxes(initialData),
          checkboxesConfig: [
            CheckboxGroupConfig(
              key: 'isActive',
              label: 'Active',
              selected: initial?['isActive'] ?? true,
              tooltip: 'Enable or disable this item',
              description: 'Turn this on if the warehouse is currently in use.',
            ),
            CheckboxGroupConfig(
              key: 'isDefault',
              label: 'Default Warehouse',
              selected: initial?['isDefault'] ?? false,
              tooltip: 'Set as default warehouse',
              description:
                  'If selected, this will be used as the default option when creating new transactions.',
            ),
            CheckboxGroupConfig(
              key: 'isBinManaged',
              label: 'Track Bins',
              selected: initial?['isBinManaged'] ?? false,
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
    ..._whCapacityFields,
    ..._addressFields,
  ];

  /// Warehouse Capacity
  static List<FieldGroupConfig> get _whCapacityFields => [
    FieldGroupConfig(
      key: 'cap-title',
      label: 'Warehouse Capacity',
      helperText:
          '\nMaximum items and weight this warehouse location can hold.',
      widgetType: FieldWidgetType.titleOnly,
    ),
    FieldGroupConfig(
      key: 'maxItems',
      label: 'Maximum Items',
      helperText: 'Maximum number of items this warehouse can store.',
      type: TextInputType.number,
      widgetType: FieldWidgetType.textField,
    ),
    FieldGroupConfig(
      key: 'maxVolume',
      label: 'Maximum Volume',
      helperText: 'Maximum total weight this warehouse can safely hold.',
      type: TextInputType.number,
    ),
    FieldGroupConfig(
      key: 'uomRestriction',
      label: 'UoM Restriction',
      helperText: 'Units of measure allowed in this warehouse',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return UOMMultiDropdown(
          label: 'UoM Restriction',
          initialValues: List.from(initialData ?? []),
          onMultiChanged: onChanged,
        );
      },
    ),
    /// @TODO - remove and replace with remote categories
    FieldGroupConfig(
      key: 'itemRestriction',
      label: 'Item Restriction',
      helperText: 'Items allowed in this warehouse.',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return CategoryPicker(
          isService: false,
          label: 'Item Restriction',
          initialValues: List.from(initialData ?? []),
          onMultiChanged: onChanged,
        );
      },
    ),
  ];

  /// Warehouse physical Address
  static List<FieldGroupConfig> get _addressFields => [
    FieldGroupConfig(
      key: 'ad-title',
      label: 'Warehouse Address',
      helperText:
          '\nStreet, city, postal code, and physical address for this warehouse location.',
      widgetType: FieldWidgetType.titleOnly,
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
      key: 'street',
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
