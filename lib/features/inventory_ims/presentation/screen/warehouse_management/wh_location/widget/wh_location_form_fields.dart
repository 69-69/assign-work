import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/warehouse/widget/search_warehouse.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_bin/widget/location_hierarchy_dropdown.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/widget/zone_type_dropdown.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/inventory_form_fields.dart';
import 'package:flutter/material.dart';

/*In a **Warehouse Management System (WMS)** within an **ERP**, these terms describe the **physical location hierarchy** used to track where inventory is stored. Think of it as going from **big area → exact spot**.

Here’s how they typically work:

---

### 1. **Zone**

* A **large warehouse area** grouped by purpose or product type
* Examples: *Receiving Zone, Picking Zone, Cold Storage Zone, Hazardous Zone*
* Used for **workflow control and storage rules**

---

### 2. **Aisle**

* A **path or row** within a zone where storage units are arranged
* Helps workers navigate the warehouse
* Example: *Aisle A1, A2*

---

### 3. **Rack**

* A **storage structure** located along an aisle
* Holds multiple shelves or levels
* Example: *Rack R05*

---

### 4. **Shelf**

* A **horizontal surface** on a rack where items are placed
* Often used for cartons or smaller items

---

### 5. **Level**

* A **vertical position** on a rack or shelf
* Important for multi-story racks
* Example: *Level 1 (floor), Level 2, Level 3*

---

### 6. **Cabinet**

* An **enclosed storage unit** (less common than racks)
* Used for **tools, documents, high-value, or controlled items**
* May contain shelves and levels inside

---

### Typical Location Structure in a WMS

```
Zone → Aisle → Rack → Level → Shelf → Bin
```

*(Some ERPs combine or rename levels/shelves depending on configuration.)*

---

### Example Location Code

**Z1-A03-R07-L02-S04**
= Zone 1, Aisle 3, Rack 7, Level 2, Shelf 4

---

### Why this matters in an ERP WMS

* Accurate **inventory tracking**
* Faster **picking and put-away**
* Better **space utilization**
* Supports **barcodes / RFID**

If you want, I can map this to a **specific ERP** (SAP, Oracle, Odoo, Dynamics, etc.) or help you design a clean location-coding scheme.
*/
class WhLocationFormFields {
  static Widget buildLocNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => InventoryFormFields.buildNumber(
    context,
    count: count,
    what: 'Location Code',
    onPressed: onPressed,
  );

  static List<FieldGroupConfig> whLocFields(Map<String, dynamic>? initial) => [
    FieldGroupConfig(
      key: 'subAreas',
      label: 'WH Sub Levels',
      helperText:
          'Physical location hierarchy used to track where inventory is stored.',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return LocationHierarchyDropdown(
          initialValue: initialData,
          onChanged: onChanged,
        );
      },
    ),
    FieldGroupConfig(
      key: 'description',
      label: 'Location Name',
      type: TextInputType.text,
      widgetType: FieldWidgetType.textField,
      helperText:
          'Storage location within the warehouse (e.g., Aisle 1, Rack B, Zone C).',
    ),
    FieldGroupConfig(
      key: 'type',
      label: 'Location type',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return ZoneTypeDropdown(
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
          showButton: false,
          initialData: [
            {'isActive': initialData},
          ],
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

  static List<FieldGroupConfig> whGenerateCodesFields(
    Map<String, dynamic>? initial,
  ) => [
    FieldGroupConfig(
      key: 'From',
      label: 'Start Number',
      type: TextInputType.number,
      widgetType: FieldWidgetType.textField,
      helperText: 'Starting value for code generation (e.g., 01).',
    ),
    FieldGroupConfig(
      key: 'To',
      label: 'End Number',
      type: TextInputType.number,
      widgetType: FieldWidgetType.textField,
      helperText: 'Ending value for code generation (e.g., 20).',
    ),
    FieldGroupConfig(
      key: 'generator',
      label: 'Generate Location Codes',
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return ElevatedButton(
          onPressed: () => onChanged(initialData),
          child: const Text('Generate'),
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
