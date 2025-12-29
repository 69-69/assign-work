import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/item_category.dart';
import 'package:assign_erp/core/constants/line_item_type.dart';
import 'package:assign_erp/core/constants/unit_of_measure.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/form/address_type_dropdown.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_link_model.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/widget/po_form_inputs.dart';
import 'package:flutter/material.dart';

class SalesDistFormFields {
  static Widget buildNumber(
    BuildContext context, {
    String count = '',
    String what = 'Quote',
    void Function()? onPressed,
  }) => Align(
    alignment: Alignment.topLeft,
    child: FittedBox(
      child: context.actionInfoButton(
        'Refresh $what Number',
        count: count,
        isTotal: false,
        onPressed: onPressed,
        bgColor: kPrimaryColor,
      ),
    ),
  );

  /// Line Item Fields
  static List<FieldGroupConfig> fields(
    // Line item type
    String type, {
    bool isDisabled = false, // Should certain fields be disabled?
    List<String>? keysToExclude, // Should certain fields be excluded?
  }) {
    final match = LineItemTypeHelper.isMaterial(type);

    List<FieldGroupConfig> list = match
        ? _productLineItemsFields(isDisabled)
        : _servicesLineItemsFields(isDisabled);

    // Filter out the fields whose key is in the 'keysToExclude' list
    final fields = (keysToExclude == null)
        ? list
        : list.where((field) => !keysToExclude.contains(field.key)).toList();

    return fields;
  }

  /// Products / Services
  static List<FieldGroupConfig> _productLineItemsFields(bool isDisabled) => [
    FieldGroupConfig(
      key: 'description',
      label: 'Item name',
      type: TextInputType.text,
      isDisabled: isDisabled,
    ),
    FieldGroupConfig(
      key: 'quantity',
      label: 'Quantity',
      type: TextInputType.number,
      isDisabled: isDisabled,
    ),
    FieldGroupConfig(
      key: 'unitPrice',
      label: 'Unit Price',
      type: TextInputType.number,
      validator: (_) => null,
      isDisabled: isDisabled,
    ),
    FieldGroupConfig(
      key: 'discount',
      label: 'Discount',
      type: TextInputType.numberWithOptions(decimal: true),
      validator: (_) => null,
      isDisabled: isDisabled,
      inputDecoration: InputDecoration(
        // helperText: 'Optional',
        labelText: 'Discount % (Optional)',
        // suffixText: '= $ghanaCedis $discountAmount',
        prefixIcon: const Icon(Icons.percent),
        prefixIconColor: kGrayColor,
      ),
    ),
    FieldGroupConfig(
      key: 'category',
      label: 'Item Group (e.g. Office Supplies, IT)',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return _ItemCategoryDropdown(
          isDisabled: isDisabled,
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'unitOfMeasure',
      label: 'Unit of Measure (e.g. box, kg)',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return _UnitOfMeasureDropdown(
          isDisabled: isDisabled,
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'leadTimeDays',
      label: 'Lead time (days)',
      type: TextInputType.number,
      isDisabled: isDisabled,
    ),
    FieldGroupConfig(
      key: 'requiredDate',
      label: 'Required Date',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DatePicker(
          inLabel: false,
          label: 'Required Date',
          initialDate: initialData,
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          restorationId: 'Required Date',
          helperText: 'When a specific item is needed.',
        );
      },
    ),
    FieldGroupConfig(
      key: 'notes',
      label: 'Additional Notes (if any)...',
      type: TextInputType.multiline,
      isDisabled: isDisabled,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'type',
      label: 'type',
      type: TextInputType.text,
      isHidden: true,
    ),
  ];

  static List<FieldGroupConfig> _servicesLineItemsFields(bool isDisabled) => [
    FieldGroupConfig(
      key: 'description',
      label: 'Service Name',
      type: TextInputType.text,
      isDisabled: isDisabled,
    ),
    FieldGroupConfig(
      key: 'serviceRate',
      label: 'Service Rate',
      type: TextInputType.number,
      isDisabled: isDisabled,
      helperText: 'Rate per Unit of Measure (e.g. box, kg). E.g. 100',
    ),
    FieldGroupConfig(
      key: 'quantity',
      label: 'Number of Services',
      type: TextInputType.number,
      isDisabled: isDisabled,
      helperText: 'How many?. E.g. 10',
    ),
    FieldGroupConfig(
      key: 'discount',
      label: 'Discount',
      type: TextInputType.numberWithOptions(decimal: true),
      validator: (_) => null,
      isDisabled: isDisabled,
      inputDecoration: InputDecoration(
        // helperText: 'Optional',
        labelText: 'Discount Percent (Optional)',
        // suffixText: '= $ghanaCedis $discountAmount',
        prefixIcon: const Icon(Icons.percent),
        prefixIconColor: kGrayColor,
      ),
    ),
    FieldGroupConfig(
      key: 'limitAmount',
      label: 'Limit Amount',
      type: TextInputType.number,
      validator: (_) => null,
      isDisabled: isDisabled,
      helperText: 'Max allowed amount, e.g. 10000',
    ),
    FieldGroupConfig(
      key: 'limitQuantity',
      label: 'Limit Quantity',
      type: TextInputType.number,
      validator: (_) => null,
      isDisabled: isDisabled,
      helperText: 'Max allowed quantity, e.g. 100',
    ),
    FieldGroupConfig(
      key: 'category',
      label: 'Service Group (e.g. labor, maintenance service)',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return _ItemCategoryDropdown(
          isService: true,
          label: 'Service Category',
          initialValue: initialData,
          isDisabled: isDisabled,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'unitOfMeasure',
      label: 'Unit of Measure (e.g. box, kg)',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return _UnitOfMeasureDropdown(
          initialValue: initialData,
          isDisabled: isDisabled,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'leadTimeDays',
      label: 'Lead time (days)',
      type: TextInputType.number,
      isDisabled: isDisabled,
    ),
    FieldGroupConfig(
      key: 'requiredDate',
      label: 'Required Date',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DatePicker(
          inLabel: false,
          label: 'Required Date',
          initialDate: initialData,
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          restorationId: 'Required Date',
          helperText: 'When a specific service is needed.',
        );
      },
    ),
    FieldGroupConfig(
      key: 'notes',
      label: 'Additional Notes (if any)...',
      type: TextInputType.multiline,
      isDisabled: isDisabled,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'type',
      label: 'type',
      type: TextInputType.text,
      isHidden: true,
    ),
  ];

  /// Addresses (e.g., Billing, Shipping Address)
  static List<FieldGroupConfig> addressFields({String? initialValue}) => [
    FieldGroupConfig(
      key: 'type',
      label: 'Address Type',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return AddressTypeDropdown(
          initialValue: initialData ?? initialValue,
          onChanged: onChanged,
        );
      },
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
      // validator: (_) => null,
    ),
  ];

  /// Supplier Fields
  static List<FieldGroupConfig> suppliersFields({String? key}) => [
    FieldGroupConfig(
      key: key ?? 'supplierLinks',
      label: 'Select Suppliers',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final value = Map<String, dynamic>.from(initialData ?? {});

        return FindSuppliers(
          initialSupplier: value['supplierId'],
          initialSupplierRep: value['supplierRepId'],
          onSupplierChanged: (id, name) {
            value
              ..['supplierId'] = id
              ..['name'] = name; // Supplier Name is not required
            onChanged(Map<String, dynamic>.from(value));
          },
          onContactPersonChanged: (contactPersonId) {
            value['supplierRepId'] = contactPersonId;
            onChanged(Map<String, dynamic>.from(value));
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
  }
}

/// Supplier Status [_SupplierStatusDropdown]
class _SupplierStatusDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const _SupplierStatusDropdown({required this.onChanged, this.initialValue});

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      label: 'Supplier Status',
      initialValue: initialValue,
      items: SupplierLink.toStringList(),
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}

/// Purchase Requisition Item Category [ItemCategoryDropdown]
class _ItemCategoryDropdown extends StatelessWidget {
  final String? label;
  final bool isService;
  final bool isDisabled;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const _ItemCategoryDropdown({
    required this.onChanged,
    this.isDisabled = false,
    this.isService = false,
    this.initialValue,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = ItemCategoryHelper.toStringList(isService: isService);
    // If label is provided, replace it with the first in the list
    if (label != null) strList[0] = label!;

    return IgnorePointer(
      ignoring: isDisabled,
      child: StaticDropdown<String>(
        key: key,
        label: strList.first,
        initialValue: initialValue,
        items: strList,
        getDisplayText: (category) => category.toTitle,
        onChanged: onChanged,
      ),
    );
  }
}

/// PO unit of measure [UnitOfMeasureDropdown]
class _UnitOfMeasureDropdown extends StatelessWidget {
  // final String? label;
  final bool isDisabled;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const _UnitOfMeasureDropdown({
    required this.onChanged,
    this.isDisabled = false,
    this.initialValue,
    // this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = UOMHelper.toStringList();
    // If label is provided, replace it with the first in the list
    // if (label != null) strList[0] = label!;

    return IgnorePointer(
      ignoring: isDisabled,
      child: StaticDropdown<String>(
        key: key,
        label: strList.first,
        initialValue: initialValue,
        items: strList,
        getDisplayText: (uom) => uom.toTitle,
        onChanged: onChanged,
      ),
    );
  }
}
