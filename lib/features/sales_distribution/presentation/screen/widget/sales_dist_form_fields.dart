import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/extensions/line_type.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/form/address_type_dropdown.dart';
import 'package:assign_erp/core/widgets/form/category_picker.dart';
import 'package:assign_erp/core/widgets/form/supplier_status_dropdown.dart';
import 'package:assign_erp/core/widgets/form/uom_dropdown.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
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
    final match = LineTypeUtil.isMaterial(type);

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
      key: 'discountPercent',
      label: 'Discount %',
      type: TextInputType.numberWithOptions(decimal: true),
      validator: (_) => null,
      isDisabled: isDisabled,
      inputDecoration: InputDecoration(
        // helperText: 'Optional',
        labelText: 'Discount % (if any)',
        // suffixText: '= $ghanaCedis $discountAmount',
        prefixIcon: const Icon(Icons.percent),
        prefixIconColor: kGrayColor,
      ),
    ),
    /// @TODO - remove and replace with remote categories
    FieldGroupConfig(
      key: 'category',
      label: 'Item Group (e.g. Office Supplies, IT)',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return CategoryPicker(
          isService: false,
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
        return UOMDropdown(
          enabled: isDisabled,
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'leadTimeDays',
      label: 'Lead time (days)',
      helperText: 'How long it takes to fulfill this item',
      type: TextInputType.number,
      isDisabled: isDisabled,
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'requiredDate',
      label: 'Required Date',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final msg = 'When a specific product is needed.';

        return DatePicker(
          inLabel: false,
          label: 'Required Date',
          initialDate: initialData,
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          restorationId: 'Required Date',
          helperText: msg,
          validator: (v) => v.isNullOrEmpty ? msg : null,
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
      key: 'discountPercent',
      label: 'Discount %',
      type: TextInputType.numberWithOptions(decimal: true),
      validator: (_) => null,
      isDisabled: isDisabled,
      inputDecoration: InputDecoration(
        // helperText: 'Optional',
        labelText: 'Discount % (if any)',
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
    /// @TODO - remove and replace with remote categories
    FieldGroupConfig(
      key: 'category',
      label: 'Service Group (e.g. labor, maintenance service)',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return CategoryPicker(
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
        return UOMDropdown(
          initialValue: initialData,
          enabled: isDisabled,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'leadTimeDays',
      label: 'Lead time (days)',
      helperText: 'How long it takes to fulfill this service',
      type: TextInputType.number,
      isDisabled: isDisabled,
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'requiredDate',
      label: 'Required Date',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final msg = 'When a specific service is needed.';

        return DatePicker(
          inLabel: false,
          label: 'Required Date',
          initialDate: initialData,
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          restorationId: 'Required Date',
          helperText: msg,
          validator: (v) => v.isNullOrEmpty ? msg : null,
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
  static List<FieldGroupConfig> addressFields({
    String? initialValue,
    int? maxItems,
  }) => [
    FieldGroupConfig(
      key: 'type',
      label: 'Address Type',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return AddressTypeDropdown(
          initialValue: initialData ?? initialValue,
          onChanged: onChanged,
          maxItems: maxItems,
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
      key: 'street',
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
        return SupplierStatusDropdown(
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
  }
}
