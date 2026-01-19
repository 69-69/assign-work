import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_bin/widget/bin_type_dropdown.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/widget/search_wh_locations.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/inventory_form_fields.dart';
import 'package:flutter/material.dart';

class WHBinFormFields {
  static Widget buildBinNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => InventoryFormFields.buildNumber(
    context,
    count: count,
    what: 'Bin',
    onPressed: onPressed,
  );

  static List<FieldGroupConfig> whBinFields({
    Map<String, dynamic>? initial,
  }) => [
    FieldGroupConfig(
      key: 'description',
      label: 'Bin Name',
      type: TextInputType.text,
      widgetType: FieldWidgetType.textField,
      helperText: 'Name for this bin (e.g., Shelf A01, Slot B03).',
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'type',
      label: 'Bin type',
      helperText: 'Select the type of bin this is.',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return BinTypeDropdown(initialValue: initialData, onChanged: onChanged);
      },
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
      label: 'Parent Location',
      helperText: 'Select the location this bin belongs to.',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return SearchWHLocation(
          initialValue: initialData,
          onChanged: (id, code, description) => onChanged(code),
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
              selected: initial?['isActive'] ?? true,
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

  static List<FieldGroupConfig> get whStorageFields => [
    FieldGroupConfig(
      key: 'maxItems',
      label: 'Maximum Items',
      helperText: 'Maximum number of items this bin or shelf can store.',
      type: TextInputType.number,
      widgetType: FieldWidgetType.textField,
    ),
    FieldGroupConfig(
      key: 'maxWeight',
      label: 'Maximum Weight',
      helperText: 'Maximum total weight this bin or shelf can safely hold.',
      type: TextInputType.number,
    ),
    FieldGroupConfig(
      key: 'minQty',
      label: 'Minimum Quantity',
      helperText:
          'Min. quantity that trigger replenishment alert if below this.',
      type: TextInputType.number,
    ),
    FieldGroupConfig(
      key: 'uomRestriction',
      label: 'Unit of Measure Restriction',
      helperText: 'What units are allowed in the bin.',
      type: TextInputType.none,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return SearchWHLocation(
          initialValue: initialData,
          onChanged: (id, code, description) => onChanged(code),
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
