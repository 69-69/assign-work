import 'package:assign_erp/core/widgets/form/address_type_dropdown.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:flutter/material.dart';

class CompanyFormInputs {
  /// Company information (e.g., name, email, phone, fax)
  static List<FieldGroupConfig> get companyFields => [
    FieldGroupConfig(key: 'name', label: 'Name', type: TextInputType.text),
    FieldGroupConfig(
      key: 'email',
      label: 'Email',
      type: TextInputType.emailAddress,
    ),
    FieldGroupConfig(key: 'phone', label: 'Phone', type: TextInputType.phone),
    FieldGroupConfig(
      key: 'altPhone',
      label: 'Secondary phone',
      type: TextInputType.phone,
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'faxNumber',
      label: 'Fax Number',
      type: TextInputType.phone,
      validator: (_) => null,
    ),
  ];

  /// Addresses (e.g., Office, Warehouse, Billing, Shipping Address)
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
      label: 'Address...',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
    ),
  ];

  /// Add company's branches/stores
  static List<FieldGroupConfig> get addStoresFields => [
    FieldGroupConfig(
      key: 'name',
      label: 'Store Name',
      type: TextInputType.text,
      helperText: 'Store name',
    ),
    FieldGroupConfig(
      key: 'phone',
      label: 'Phone',
      type: TextInputType.number,
      helperText: 'Store\'s Phone number',
    ),
    FieldGroupConfig(
      key: 'location',
      label: 'Address',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      helperText: 'Address or Location of Store (Branch)',
    ),
    FieldGroupConfig(
      key: 'notes',
      label: 'Additional Notes (if any)',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
      helperText: 'Short description of Store (Branch)',
    ),
  ];

  /// Create Company's departments
  static List<FieldGroupConfig> get departmentsFields => [
    FieldGroupConfig(
      key: 'name',
      label: 'Department Name',
      type: TextInputType.text,
      helperText: 'Department name',
    ),
    FieldGroupConfig(
      key: 'lead',
      label: 'Department Lead',
      type: TextInputType.text,
      helperText: 'Department Lead name',
    ),
    FieldGroupConfig(
      key: 'description',
      label: 'Description',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      helperText: 'Short description of the department\'s role',
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
