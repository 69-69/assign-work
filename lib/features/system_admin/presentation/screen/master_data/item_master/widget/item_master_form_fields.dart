import 'package:assign_erp/core/util/extensions/line_item_type.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/form/costing_method_dropdown.dart';
import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/form/all_category_dropdown.dart';
import 'package:assign_erp/core/widgets/form/uom_dropdown.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/inventory_form_fields.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/tax_master/widget/search_taxes.dart';
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

  static Widget buildTaxModeSelector({
    TaxMode? defaultTaxMode,
    bool? isEnabled,
    List<String>? initialValues,
    required List<String> selectedTaxCodes,
    required Function(TaxMode?) selectedTaxMode,
  }) => TaxModeSelectorFactory.create(
    isEnabled: isEnabled,
    initialValues: initialValues,
    defaultTaxMode: defaultTaxMode,
    selectedTaxMode: selectedTaxMode,
    selectedTaxCodes: selectedTaxCodes,
  );

  static List<FieldGroupConfig> nameAndDescFields({LineItemType? itemType}) => [
    /// 1. Identification
    FieldGroupConfig(key: 'name', label: 'Name', type: TextInputType.text),

    /// 2. Classification
    /// @TODO - remove and replace with remote categories
    FieldGroupConfig(
      key: 'category',
      label: '${itemType?.getLabel ?? 'Item'} Category',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return CategoryDropdown(
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
      // validator: (_) => null,
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

  static List<FieldGroupConfig> get baseUomFields => [
    /// 3. Units of Measure
    FieldGroupConfig(
      key: 'baseUom',
      label: 'Base Unit of Measure',
      helperText:
          'Primary unit used for purchasing, stocking, & selling this item',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return UOMDropdown(
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
  ];

  static List<FieldGroupConfig> unitRuleFields({
    Map<String, dynamic>? initial,
    bool isService = false,
  }) => [
    /// 3. Master Rules
    FieldGroupConfig(
      key: 'itemRules',
      label: 'Usage & Availability',
      type: TextInputType.text,
      isNested: true,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DynamicCheckboxList(
          showButton: false,
          initialData: CheckboxGroupConfig.mapCheckboxes(initialData),
          blockKey: 'isStockItem',
          onBlocked: isService
              ? (cxt, blockKey) async {
                  if (blockKey.filterAny('isStockItem')) {
                    await cxt.confirmDone(
                      Text(
                        'Inventory tracking is only available for material items. Services and non-material items cannot be tracked.',
                      ),
                      title: 'Inventory Tracking Disabled',
                    );
                  }
                }
              : null,
          checkboxesConfig: [
            CheckboxGroupConfig(
              key: 'isActive',
              label: 'Active',
              selected: initial?['isActive'] ?? true,
              tooltip: 'Existing transactions are not affected',
              description:
                  'When disabled, this item cannot be selected in new purchase, sales, or inventory transactions.',
            ),
            CheckboxGroupConfig(
              key: 'isStockItem',
              label: 'Track inventory',
              selected: initial?['isStockItem'] ?? false,
              tooltip: 'Enable if this item is physically stored',
              description:
                  'Enable if this item is physically stored and its quantity should be tracked in inventory.',
            ),
            CheckboxGroupConfig(
              key: 'isPurchasable',
              label: 'Available for purchasing',
              selected: initial?['isPurchasable'] ?? false,
              tooltip: 'Required for procurement documents',
              description:
                  'Allows this item to be requested, quoted, and ordered from suppliers.',
            ),
            CheckboxGroupConfig(
              key: 'isSellable',
              label: 'Available for sales',
              selected: initial?['isSellable'] ?? false,
              tooltip: 'Required for customer-facing transactions',
              description:
                  'Allows this item to be offered and sold to customers in sales and POS transactions.',
            ),
          ],
          onCheckChanged: (List<CheckboxGroupConfig> selected) async {
            final mapList = CheckboxGroupConfig.mapCheckboxes(selected);
            onChanged(mapList);
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
      // validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'reorderQty',
      label: 'Reorder Quantity',
      helperText: 'Quantity to order when stock reaches the reorder point',
      type: TextInputType.number,
      // validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'leadTimeDays',
      label: 'Lead time (days)',
      helperText: 'How long it takes to fulfill this item',
      type: TextInputType.number,
      // validator: (_) => null,
    ),
  ];

  static List<FieldGroupConfig> get costingFields => [
    /// 5. Costing (stock items only)
    FieldGroupConfig(
      key: 'standardCost',
      label: 'Standard Cost',
      helperText: 'Cost per unit of measure (base price)',
      type: TextInputType.number,
      // validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'costingMethod',
      label: 'How cost is calculated when items are issued or sold',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return CostingMethodDropdown(
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
  ];
}
