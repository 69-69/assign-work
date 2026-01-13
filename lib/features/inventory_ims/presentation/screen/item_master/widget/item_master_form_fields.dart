import 'package:assign_erp/core/util/extensions/item_category.dart';
import 'package:assign_erp/core/util/extensions/line_item_type.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_master_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/inventory_form_fields.dart';
import 'package:flutter/material.dart';

class ItemMasterFormFields {
  static Widget buildIMNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => InventoryFormFields.buildNumber(
    context,
    count: count,
    what: 'Item Master',
    onPressed: onPressed,
  );

  static List<FieldGroupConfig> nameAndDescFields({LineItemType? itemType}) => [
    /// 1. Identification
    FieldGroupConfig(key: 'name', label: 'Name', type: TextInputType.text),

    /// 2. Classification
    FieldGroupConfig(
      key: 'category',
      label: '${itemType?.getLabel ?? 'Item'} Category',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return _ItemCategoryDropdown(
          isService: itemType?.isService ?? false,
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'description',
      label: 'Description (if any)...',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
    /* FieldGroupConfig(
      key: 'itemType',
      label: 'Item Type',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DynamicRadioList(
          title: 'How is this item used?',
          initialData: RadioGroupConfig.mapRadios(initialData),
          radiosConfig: [
            RadioGroupConfig(
              key: LineItemType.material.getName,
              label: 'Product / Material',
              tooltip: 'Stock quantities and inventory valuation apply',
              description:
                  'Use for physical items that are purchased, stored, produced, or sold.',
            ),
            RadioGroupConfig(
              key: LineItemType.service.getName,
              label: 'Service',
              tooltip: 'No inventory tracking or stock valuation',
              description:
                  'Use for labor, consulting, maintenance, or other non-physical items.',
            ),
          ],
          onChanged: (List<RadioGroupConfig> data) {
            // RadioGroupConfig? selected = RadioGroupConfig.selected(data);

            onChanged(data);
          },
        );
      },
    ),*/
  ];

  static List<FieldGroupConfig> unitRuleFields({
    Map<String, dynamic>? initial,
  }) => [
    /// 3. Units & Rules
    FieldGroupConfig(
      key: 'baseUom',
      label: 'Base Unit of Measure',
      helperText:
          'Primary unit used for purchasing, stocking, & selling this item',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return _UnitOfMeasureDropdown(
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),

    // If Item Type = Service and Track inventory = ON
    // ⚠ Services cannot be inventory-tracked

    // If Track inventory = OFF
    // ℹ Inventory planning and reorder settings are ignored
    FieldGroupConfig(
      key: 'itemRules',
      label: 'Usage & Availability',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DynamicCheckboxList(
          showButton: false,
          initialData: CheckboxGroupConfig.mapCheckboxes(initialData),
          checkboxesConfig: [
            CheckboxGroupConfig(
              key: 'isActive',
              label: 'Active',
              tooltip: 'Existing transactions are not affected',
              description:
                  'When disabled, this item cannot be selected in new purchase, sales, or inventory transactions.',
            ),
            CheckboxGroupConfig(
              key: 'isStockItem',
              label: 'Track inventory',
              tooltip: 'Disable for services and non-physical items',
              description:
                  'Enable if this item is physically stored and its quantity should be tracked in inventory.',
            ),
            CheckboxGroupConfig(
              key: 'isPurchasable',
              label: 'Available for purchasing',
              tooltip: 'Required for procurement documents',
              description:
                  'Allows this item to be requested, quoted, and ordered from suppliers.',
            ),
            CheckboxGroupConfig(
              key: 'isSellable',
              label: 'Available for sales',
              tooltip: 'Required for customer-facing transactions',
              description:
                  'Allows this item to be offered and sold to customers in sales and POS transactions.',
            ),
          ],
          onCheckChanged: (List<CheckboxGroupConfig> selected) {
            final selectedMap = CheckboxGroupConfig.mapCheckboxes(selected);
            onChanged(selectedMap);
          },
        );
      },
    ),
  ];

  static List<FieldGroupConfig> get planningFields => [
    /// 4. Planning (stock items only)
    FieldGroupConfig(
      key: 'reorderPoint',
      label: 'Reorder Point',
      helperText: 'Minimum stock level that triggers a reorder suggestion',
      type: TextInputType.number,
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'reorderQty',
      label: 'Reorder Quantity',
      helperText:
          'Default quantity to reorder when the stock reaches the reorder point',
      type: TextInputType.number,
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'leadTimeDays',
      label: 'Lead time (days)',
      helperText: 'How long it takes to fulfill this item',
      type: TextInputType.number,
      validator: (_) => null,
    ),
  ];

  static List<FieldGroupConfig> get costingFields => [
    /// 5. Costing (stock items only)
    FieldGroupConfig(
      key: 'standardCost',
      label: 'Standard Cost',
      helperText: 'Cost per unit of measure',
      type: TextInputType.number,
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'costingMethod',
      label: 'How cost is calculated when items are issued or sold',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return _CostingMethodDropdown(
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
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
  }) {
    return list
      ..clear() // Clear previous entries to prevent duplication
      ..addAll(
        map
            .asMap()
            .entries
            .map((e) => fromMap(e.value, '${e.key + 1}'))
            .toList(),
      );
  }
}

/// Item Category [ItemCategoryDropdown]
class _ItemCategoryDropdown extends StatelessWidget {
  final String? label;
  final bool isService;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const _ItemCategoryDropdown({
    required this.onChanged,
    this.isService = false,
    this.initialValue,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = ItemCategoryUtil.toStringList(isService: isService);
    // If label is provided, replace it with the first in the list
    if (label != null) strList[0] = label!;

    return StaticDropdown<String>(
      key: key,
      label: strList.first,
      initialValue: initialValue,
      items: strList,
      getDisplayText: (category) => category.toTitle,
      onChanged: onChanged,
    );
  }
}

/// Costing Method Category [ItemCategoryDropdown]
class _CostingMethodDropdown extends StatelessWidget {
  final String? label;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const _CostingMethodDropdown({
    required this.onChanged,
    this.initialValue,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = CostingMethodUtil.toStringList();
    // If label is provided, replace it with the first in the list
    if (label != null) strList[0] = label!;

    return StaticDropdown<String>(
      key: key,
      label: strList.first,
      initialValue: initialValue,
      items: strList,
      getDisplayText: (method) => method.toTitle,
      onChanged: onChanged,
    );
  }
}

/// PO unit of measure [UnitOfMeasureDropdown]
class _UnitOfMeasureDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(String? s) onChanged;

  const _UnitOfMeasureDropdown({required this.onChanged, this.initialValue});

  @override
  Widget build(BuildContext context) {
    final strList = UOMUtil.toStringList();
    // If label is provided, replace it with the first in the list
    // if (label != null) strList[0] = label!;

    return StaticDropdown<String>(
      key: key,
      label: strList.first,
      initialValue: initialValue,
      items: strList,
      getDisplayText: (uom) => uom.toTitle,
      onChanged: onChanged,
    );
  }
}

/*// backup
  static List<FieldGroupConfig> suppliersFields2({String? key}) => [
    FieldGroupConfig(
      key: key ?? 'supplierLinks',
      label: 'Select Suppliers',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        prettyPrint('initial-Data', initialData);
        final initial = Map<String, dynamic>.from(initialData ?? {});
        return FindSuppliers(
          initialSupplier: initial['supplierId'],
          initialSupplierRep: initial['supplierRepId'],
          onSupplierChanged: (id, name) {
            prettyPrint('supplier-Id--$id', initial['supplierId']);
            initial
              ..['supplierId'] = id
              ..['name'] = name; // Supplier Name is not required
            onChanged(Map<String, dynamic>.from(initial));
          },
          onContactPersonChanged: (contactPersonId) {
            initial['supplierRepId'] = contactPersonId;
            onChanged(Map<String, dynamic>.from(initial));
          },
        );
      },
    ),
    FieldGroupConfig(
      key: 'status',
      label: 'Supplier Status',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return _SupplierStatusDropdown(
          initialValue: initialData,
          onChanged: onChanged,
        );
      },
    ),
  ];*/
/* // Alternative-1 approach (now commented out)
    _lineItems
      ..clear() // Clear previous entries to prevent duplication
      ..addAll(data.map((e) => ProLineItem.fromMap(e)));
   // Alternative-1
    _lineItems
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(
            data
                .asMap()
                .entries
                .map((e) => ProLineItem.fromMap(e.value, id: '${e.key + 1}'))
                .toList(),
          );*/
