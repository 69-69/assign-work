import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/form/uom_dropdown.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_bin/widget/location_type_dropdown.dart';
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

  static Widget stackTextField(
    BuildContext context, {
    Key? key,
    String? label,
    String? helperText,
    bool enable = false,
    bool showProgress = false,
    void Function()? onPressed,
    InputDecoration? decoration,
    void Function(String)? onChanged,
    TextEditingController? controller,
  }) => Stack(
    alignment: Alignment.topRight,
    children: <Widget>[
      CustomTextField(
        key: key,
        label: label,
        enable: enable,
        autofocus: enable,
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.text,
        inputDecoration:
            decoration ??
            InputDecoration(helperText: helperText, labelText: label),
      ),

      Padding(
        padding: EdgeInsets.all(3),
        child: FittedBox(
          child: context.toolbarButton(
            label: showProgress ? 'Saving' : (enable ? 'Done' : 'Edit'),
            icon: showProgress
                ? _progressIcon
                : (enable ? Icons.done : Icons.edit),
            bgColor: kPrimaryColor.toAlpha(enable ? 1 : 0.3),
            onPressed: onPressed,
          ),
        ),
      ),
    ],
  );

  static Widget get _progressIcon => SizedBox(
    width: 10,
    height: 10,
    child: AsyncProgressBarDialog(size: 10, isDialog: false, strokeWidth: 2),
  );

  static List<FieldGroupConfig> whLocFields({
    Map<String, dynamic>? initial,
    bool isCustom = false,
    bool isZone = false,
  }) => [
    FieldGroupConfig(
      key: 'type',
      label: 'Sub-Location Type',
      helperText:
          'Physical location hierarchy(sub-locations) used to track where inventory is stored.',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return LocationTypeDropdown(
          initialValue: '$initialData'.separateWord,
          onChanged: onChanged,
        );
      },
    ),
    if (isZone) ...{
      FieldGroupConfig(
        key: 'zoneType',
        label: 'Zone type',
        type: TextInputType.text,
        widgetType: FieldWidgetType.custom,
        customBuilder: ({required initialData, required onChanged}) {
          return ZoneTypeDropdown(
            initialValue: initialData,
            onChanged: onChanged,
          );
        },
      ),
    },
    FieldGroupConfig(
      key: 'description',
      isHidden: !isCustom,
      label: 'New description',
      type: TextInputType.text,
      validator: (_) => null,
      helperText: 'Storage location within the warehouse (e.g., Shelf).',
    ),
    FieldGroupConfig(
      key: 'uomRestriction',
      label: 'UoM Restriction',
      helperText: 'Units of measure allowed in this sub-location.',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return UOMMultiDropdown(
          initialValues: List.from(initialData ?? []),
          onMultiChanged: onChanged,
        );
      },
    ),
    FieldGroupConfig(
      key: 'maxQuantity',
      label: 'Maximum Quantity',
      helperText: 'Maximum number of units allowed in this sub-location.',
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
          initialData: [
            {'isActive': initialData},
          ],
          checkboxesConfig: [
            CheckboxGroupConfig(
              key: 'isActive',
              label: 'Active',
              // selected: initial?['isActive'] ?? true,
              tooltip: 'Enable or disable this item',
              description:
                  'Turn this on if the sub-location is currently in use.',
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
      key: 'maxVolume',
      label: 'Maximum Volume',
      helperText: 'Maximum total volume this sub-location can store.',
      type: TextInputType.number,
    ),
  ];

  static List<FieldGroupConfig> whGenerateCodesFields() => [
    FieldGroupConfig(
      key: 'from',
      label: 'From (Start)',
      type: TextInputType.number,
      widgetType: FieldWidgetType.textField,
      helperText: 'Starting number for code generation (e.g., 1).',
    ),
    FieldGroupConfig(
      key: 'to',
      label: 'To (End)',
      type: TextInputType.number,
      widgetType: FieldWidgetType.textField,
      helperText: 'Ending number for code generation (e.g., 20).',
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

class CodeRange {
  final int from;
  final int to;

  CodeRange({required this.from, required this.to});

  factory CodeRange.fromMap(Map<String, dynamic> map) =>
      CodeRange(from: '${map["from"]}'.asInt, to: '${map["to"]}'.asInt);

  // Is empty
  bool get isEmpty => from == 0 || to <= 1;
}
