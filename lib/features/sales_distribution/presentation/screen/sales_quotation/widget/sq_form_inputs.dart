import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/constants/workflow_status.dart';
import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/form/currency_selection.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:assign_erp/core/widgets/form/sales_channel_dropdown.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/customer_crm/data/data_sources/remote/get_customers.dart';
import 'package:assign_erp/features/customer_crm/presentation/screen/customers/widget/search_customer.dart';
import 'package:assign_erp/features/procurement/data/model/workflow_converter_model.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_requisition/widget/search_purchase_requisitions.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_supplier/supplier_account/widget/search_suppliers.dart';
import 'package:assign_erp/features/sales_distribution/data/model/sales_quotation_model.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_distribution_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/screen/widget/sales_dist_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_company.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_taxes.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/staff_account/widget/search_employees.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/search_departments.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_taxes/widget/search_taxes.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class SQFormInputs {
  static updateListFromData<T>(
    List<T> list, {
    required List<Map<String, dynamic>> map,
    required T Function(Map<String, dynamic>, String) fromMap,
  }) => SalesDistFormFields.updateListFromData<T>(
    list,
    map: map,
    fromMap: fromMap,
  );

  /// Apply taxes to RFQ
  static Future<SalesQuotation> applyTaxesToQuote(SalesQuotation rfq) async {
    final taxMap = await GetTaxes.loadAllTaxRates();
    return rfq.computeTaxAmounts(taxMap);
  }

  /// Get Customer by ID
  static Future getCustomer(String custId) async {
    final customer = await GetAllCustomers.byCustomerId(custId);
    return customer.isEmpty ? null : customer;
  }

  /// Get Company Info and Addresses
  static Future<AddressInfo?> getCompanyAddress({
    String type = 'shipping',
  }) async {
    final company = await GetCompany.load();
    return company.isNullOrEmpty ? null : company?.getByType(type);
  }

  /// Build RFQ Number (using the parent method)
  static Widget buildSQNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => SalesDistFormFields.buildNumber(
    context,
    what: 'quote',
    count: count,
    onPressed: onPressed,
  );

  static List<FieldGroupConfig> fields(
    String type, {
    bool isDisabled = false,
    bool isHidden = false,
    List<String> keysToExclude = const [],
  }) {
    final fields = SalesDistFormFields.fields(
      type,
      isDisabled: isDisabled,
      keysToExclude: keysToExclude,
    );
    return [
      ...fields,

      if (keysToExclude.contains('taxCodes') == false) ...{
        // Tax Rate % (Per item)
        FieldGroupConfig(
          key: 'taxCodes',
          label: 'Tax Rate % (Per item)',
          type: TextInputType.text,
          widgetType: FieldWidgetType.custom,
          isHidden: isHidden,
          customBuilder: ({required initialData, required onChanged}) {
            return TaxMultiSelectDropdown(
              initialValues: initialData,
              onMultiChanged: (List<Tax> selected) {
                final taxCodes = selected.map((e) => e.code).toList();
                onChanged(taxCodes);
              },
            );
          },
        ),
      },
    ];
  }

  /// Currency & Pricing Fields
  static List<FieldGroupConfig> get currencyPricingFields => [
    FieldGroupConfig(
      key: 'exchangeRate',
      label: 'Exchange Rate',
      type: TextInputType.number,
      widgetType: FieldWidgetType.textField,
    ),
    FieldGroupConfig(
      key: 'shippingAmount',
      label: 'Shipping Amount',
      type: TextInputType.number,
      widgetType: FieldWidgetType.textField,
    ),
    FieldGroupConfig(
      key: 'currencyCode',
      label: 'Currency',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return CurrencySelection(
          initialCurrency: initialData,
          onChanged: (({String code, String symbol})? s) => onChanged(s!.code),
        );
      },
    ),
  ];

  /// Dates & Validity
  static List<FieldGroupConfig> get validityDateFields => [
    FieldGroupConfig(
      key: 'validFrom',
      label: 'Valid from',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DatePicker(
          inLabel: false,
          initialDate: initialData,
          label: 'Valid from',
          restorationId: 'Valid from',
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          helperText: 'Start date of the sales quotation',
        );
      },
    ),
    FieldGroupConfig(
      key: 'validUntil',
      label: 'Valid until',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DatePicker(
          inLabel: false,
          initialDate: initialData,
          label: 'Valid until',
          restorationId: 'Valid until',
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          helperText: 'Expiry date of the sales quotation',
        );
      },
    ),
    FieldGroupConfig(
      key: 'expectedDate',
      label: 'Expected date',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DatePicker(
          inLabel: false,
          initialDate: initialData,
          label: 'Expected date',
          restorationId: 'Expected date',
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          helperText: 'Earliest delivery date for the entire order.',
        );
      },
    ),
  ];

  /// Terms & Conditions
  static List<FieldGroupConfig> get supplierTermsFields => [
    FieldGroupConfig(
      key: 'paymentTerms',
      label: 'Payment terms (if any)...',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'warrantyTerms',
      label: 'Warranty Terms (if any)...',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'returnPolicy',
      label: 'Return Policy (if any)...',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'notes',
      label: 'Additional Notes (if any)...',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
  ];

  /// Suppliers Fields
  static List<FieldGroupConfig> get suppliersFields =>
      SalesDistFormFields.suppliersFields();

  /// Addresses (e.g., Buyer Shipping Address)
  static List<FieldGroupConfig> get addressesFields =>
      SalesDistFormFields.addressFields();

  static AuditSalesDistribution<SalesQuotation> updateHistory({
    required String empId,
    required AuditAction action,
    required SalesQuotation quote,
  }) {
    final up = AuditSalesDistribution<SalesQuotation>(
      documentId: quote.id,
      log: AuditLog.logScaffold(
        oldLogs: quote.history,
        newLog: AuditLog(
          action: action,
          actionBy: empId,
          statusAfterAction: quote.getSQStatus,
        ),
      ),
    );
    return up;
  }
}

/// [FindApprovedPR] Search RFQ to create PO
/// For Converting [Purchase Requisition] to [Request For Quote]: PR to RFQ
class FindApprovedPR extends StatelessWidget {
  final void Function() onCreateNewRFQ;
  final void Function(WorkflowConverter) onValueChanged;

  const FindApprovedPR({
    super.key,
    required this.onCreateNewRFQ,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffold(
      title: 'Create Request for Quote',
      body: FormGroupCard(
        title: '[Purchase Requisition] → RFQ',
        subTitle: '\nSearch & then select a PR to create a new RFQ.\n',
        children: [
          SearchPRs(
            actionButtonText: 'Create New RFQ',
            onActionPressed: onCreateNewRFQ,
            onValueChanged: (map) =>
                onValueChanged.call(WorkflowConverter.fromMap(map)),
          ),
        ],
      ),
    );
  }
}

/// Find Suppliers Dropdown [FindSuppliers]
class FindSuppliers extends StatelessWidget {
  const FindSuppliers({
    super.key,
    this.initialSupplier,
    this.onContactPersonChanged,
    this.initialSupplierRep,
    required this.onSupplierChanged,
  });

  final String? initialSupplier;
  final void Function(String, String) onSupplierChanged;
  final String? initialSupplierRep;
  final void Function(String)? onContactPersonChanged;

  @override
  Widget build(BuildContext context) {
    return SearchSuppliers(
      initialSupplier: initialSupplier,
      initialContactPerson: initialSupplierRep,
      onSupplierChanged: onSupplierChanged,
      onContactPersonChanged: onContactPersonChanged,
    );
  }
}

/// [CurrencyAndCostCenterDepartment]
/// Currency and cost center Department (Who pays for the Supplier)
class CurrencyAndCostCenterDepartment extends StatelessWidget {
  final String? initialCurrency;
  final void Function(String) onCurrencyChanged;
  final String? initialCostCenter;
  final void Function(String, String, String) onCostCenterChange;

  const CurrencyAndCostCenterDepartment({
    super.key,
    this.initialCurrency,
    required this.onCurrencyChanged,
    this.initialCostCenter,
    required this.onCostCenterChange,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      children: [
        CurrencySelection(
          initialCurrency: initialCurrency,
          onChanged: (({String code, String symbol})? s) =>
              onCurrencyChanged(s!.code),
        ),
        SearchDepartments(
          label: 'Cost Center...',
          initialValue: initialCostCenter,
          onChanged: (id, code, name) => onCostCenterChange(id, code, name),
        ),
      ],
    );
  }
}

/// Auto Convert PO & RFQStatus Dropdown TextField [AutoCreateAndSQStatus]
class AutoCreateAndSQStatus extends StatelessWidget {
  const AutoCreateAndSQStatus({
    super.key,
    this.initialStatus,
    required this.onStatusChanged,
    required this.isSelected,
    required this.onAutoConvertChanged,
  });

  final bool isSelected;
  final void Function(bool) onAutoConvertChanged;
  final String? initialStatus;
  final void Function(dynamic) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Auto-Convert Sales Quote to Sales Order when RFQ is Accepted
        _AutoCreateSO(isChecked: isSelected, onChanged: onAutoConvertChanged),
        _SQStatusDropdown(
          initialValue: initialStatus,
          onChange: onStatusChanged,
        ),
      ],
    );
  }
}

/// Validity & Payment Terms Dropdown TextField [ValidityAndPayTermsDropdown]
class ValidityAndPayTermsDropdown extends StatelessWidget {
  const ValidityAndPayTermsDropdown({
    super.key,
    this.initialPayTerms,
    required this.onPayTermsChanged,
    this.initialValidity,
    this.labelValidity,
    required this.onValidityChanged,
  });

  final String? initialPayTerms;
  final void Function(dynamic) onPayTermsChanged;
  final String? initialValidity;
  final String? labelValidity;
  final Function(DateTime) onValidityChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DatePicker(
          inLabel: false,
          initialDate: initialValidity,
          label: labelValidity ?? 'Validity date',
          restorationId: 'Validity date',
          selectedDate: onValidityChanged,
          helperText: 'How long the quote remains valid',
        ),
        _PayTermsDropdown(
          initialValue: initialPayTerms,
          onChange: onPayTermsChanged,
        ),
      ],
    );
  }
}

/// Deadline & Delivery Date TextField [DeadlineAndExpectedDateInput]
class DeadlineAndExpectedDateInput extends StatelessWidget {
  const DeadlineAndExpectedDateInput({
    super.key,
    this.labelExpected,
    this.labelDeadline,
    required this.onExpectedChanged,
    required this.onDeadlineChanged,
    this.initialExpectedDate,
    this.initialDeadlineDate,
    this.lineItemType,
  });

  final String? lineItemType;
  final String? initialExpectedDate;
  final String? initialDeadlineDate;
  final String? labelExpected;
  final String? labelDeadline;
  final Function(DateTime) onExpectedChanged;
  final Function(DateTime) onDeadlineChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DatePicker(
          inLabel: false,
          initialDate: initialExpectedDate,
          label: labelExpected,
          restorationId: 'Expected date',
          selectedDate: onExpectedChanged,
          helperText:
              'Expected delivery date for the $lineItemType after order confirmation',
        ),
        DatePicker(
          inLabel: false,
          initialDate: initialDeadlineDate,
          label: labelDeadline,
          restorationId: 'Deadline date',
          selectedDate: onDeadlineChanged,
          helperText: 'Final date for supplier to submit quote.',
        ),
      ],
    );
  }
}

/// Currency Selection Dropdown [CurrencySelection]
class CurrencyDropdown extends StatelessWidget {
  final String? initialCurrency;
  final void Function(dynamic s) onCurrencyChanged;

  const CurrencyDropdown({
    super.key,
    this.initialCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CurrencySelection(
      initialCurrency: initialCurrency,
      onChanged: (({String code, String symbol})? s) =>
          onCurrencyChanged(s!.code),
    );
  }
}

/// [DeliveryAddressTextField]
class DeliveryAddressAndNotes extends StatelessWidget {
  final TextEditingController? notesController;
  final ValueChanged? onNotesChanged;
  final TextEditingController? addressController;
  final ValueChanged? onAddressChanged;

  const DeliveryAddressAndNotes({
    super.key,
    this.addressController,
    this.onAddressChanged,
    this.notesController,
    this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextField(
          label: 'Delivery address (if any)...',
          controller: addressController,
          onChanged: onAddressChanged,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
          validator: (s) => null,
        ),
        CustomTextField(
          label: 'Additional Notes (if any)...',
          controller: notesController,
          onChanged: onNotesChanged,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
          validator: (s) => null,
        ),
      ],
    );
  }
}

/// [SalesRepAndCustomer]
class SalesRepAndCustomer extends StatelessWidget {
  final bool isDisabled;
  final String? initialCustomer;
  final String? initialSalesRep;
  final void Function(String, String, String) onSalesRepChanged;
  final void Function(String, String) onCustomerChange;

  const SalesRepAndCustomer({
    super.key,
    this.isDisabled = false,
    this.initialCustomer,
    this.initialSalesRep,
    required this.onSalesRepChanged,
    required this.onCustomerChange,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(ignoring: isDisabled, child: _buildBody());
  }

  AdaptiveLayout _buildBody() {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SearchEmployees(
          labelText: 'Sales Person',
          initialValue: initialSalesRep,
          onChanged: onSalesRepChanged,
        ),
        SearchCustomer(
          allowManualEntry: true,
          initialValue: initialCustomer,
          onChanged: (id, name) => onCustomerChange(id, name),
        ),
      ],
    );
  }
}

/// [SalesChannelChoice]
class SalesChannelChoice extends StatelessWidget {
  final bool isDisabled;
  final String? initialChannel;
  final void Function(String) onChannelChange;

  const SalesChannelChoice({
    super.key,
    this.isDisabled = false,
    this.initialChannel,
    required this.onChannelChange,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isDisabled,
      child: SalesChannelDropdown(
        initialValue: initialChannel,
        onChanged: (s) => onChannelChange.call(s),
      ),
    );
  }
}

/// [_BuyerContactPerson] Buyer Contact Person
class _BuyerContactPerson extends StatelessWidget {
  final bool isDisabled;
  final String? initialValue;
  final void Function(String, String, String) onChanged;

  const _BuyerContactPerson({
    this.isDisabled = false,
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isDisabled,
      child: SearchEmployees(
        labelText: 'Contact Person',
        initialValue: initialValue,
        onChanged: onChanged,
      ),
    );
  }
}

/// Sales Quotation Status [RFQStatusDropdown]
class _SQStatusDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChange;

  const _SQStatusDropdown({required this.onChange, this.initialValue});

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      label: 'Quote Status',
      initialValue: initialValue,
      items: WorkflowStatusHelper.toStringList(type: WorkflowType.sq),
      getDisplayText: (status) => status,
      onChanged: onChange,
    );
  }
}

/// Payment terms [_PayTermsDropdown]
class _PayTermsDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChange;

  const _PayTermsDropdown({required this.onChange, this.initialValue});

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<Map<String, String>>(
      key: key,
      items: paymentTerms,
      label: 'Payment terms',
      initialValue: paymentTerms.firstWhereOrNull(
        (term) => term['id'] == initialValue,
      ),
      getDisplayText: (term) => term['term']!,
      onChanged: (term) => onChange(term?['id']),
    );
  }
}

/// [_AutoCreateSO] Auto-Convert Sales Quote to Sales Order if SQ is Approved
class _AutoCreateSO extends StatelessWidget {
  final bool isChecked;
  final void Function(bool) onChanged;

  const _AutoCreateSO({required this.isChecked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Auto-Convert Sales Quote to Sales Order if SQ is Approved
    return CustomCheckboxTile(
      title: Text(
        'Auto Convert Quote?',
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text('Auto-convert Quote to Orders after approval'),
      contentPadding: EdgeInsets.symmetric(horizontal: 6.0),
      value: isChecked,
      onChanged: (v) => onChanged(v ?? false),
    );
    /*CustomSwitchTile(
      title: 'Auto Create PO',
      subtitle: 'Generate PO when RFQ is accepted',
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      isSelected: isSelected,
      onChanged: onChanged,
    );*/
  }
}

/// [UseDefaultAddress] Option to Use Default Address
class UseDefaultAddress extends StatelessWidget {
  final bool isChecked;
  final void Function(bool) onChanged;

  const UseDefaultAddress({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCheckboxTile(
      title: Text(
        'Use Default Address?',
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text('Use the company’s default address for shipping'),
      contentPadding: EdgeInsets.symmetric(horizontal: 6.0),
      value: isChecked,
      onChanged: (v) => onChanged(v ?? false),
    );
  }
}
