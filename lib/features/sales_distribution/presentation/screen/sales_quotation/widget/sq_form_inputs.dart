import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/form/auto_convert_workflow.dart';
import 'package:assign_erp/core/widgets/form/currency_dropdown.dart';
import 'package:assign_erp/core/widgets/form/sales_channel_dropdown.dart';
import 'package:assign_erp/core/widgets/form/workflow_status_dropdown.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/customer_crm/data/data_sources/remote/get_customers.dart';
import 'package:assign_erp/features/customer_crm/presentation/screen/customers/widget/search_customer.dart';
import 'package:assign_erp/features/sales_distribution/data/model/sales_quotation_model.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_distribution_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/screen/widget/sales_dist_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_taxes.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/employee_account/widget/search_employees.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/tax_master/widget/search_taxes.dart';
import 'package:flutter/material.dart';

class SQFormInputs {
  static Widget buildTaxModeSelector({
    TaxMode? defaultTaxMode,
    List<String>? initialValues,
    required List<String> selectedTaxCodes,
    required Function(TaxMode?) selectedTaxMode,
  }) => TaxModeSelectorFactory.create(
    initialValues: initialValues,
    defaultTaxMode: defaultTaxMode,
    selectedTaxMode: selectedTaxMode,
    selectedTaxCodes: selectedTaxCodes,
  );

  static updateListFromData<T>(
    List<T> list, {
    required List<Map<String, dynamic>> map,
    required T Function(Map<String, dynamic>, String) fromMap,
  }) => SalesDistFormFields.updateListFromData<T>(
    list,
    map: map,
    fromMap: fromMap,
  );

  /// Apply taxes to Sales Quote
  static Future<SalesQuotation> applyTaxesToQuote(SalesQuotation quote) async {
    final taxMap = await GetTaxes.loadAllTaxRates();
    return quote.calculateTaxes(taxMap);
  }

  /// Get Customer by ID
  static Future getCustomer(String customerId) async {
    final customer = await GetAllCustomers.byCustomerId(customerId);
    return customer.isEmpty ? null : customer;
  }

  /// Build Sales Quote Number (using the parent method)
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
    List<String> keysToExclude = const ['limitAmount', 'limitQuantity'],
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
        return CurrencyDropdown(
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
        final msg = 'Start date of the sales quotation';

        return DatePicker(
          inLabel: false,
          key: Key('validFrom'),
          initialDate: initialData,
          label: 'Valid from',
          restorationId: 'Valid from',
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          helperText: msg,
          validator: (v) => v.isNullOrEmpty ? msg : null,
        );
      },
    ),
    FieldGroupConfig(
      key: 'validUntil',
      label: 'Valid until',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final msg = 'Expiry date of the sales quotation';

        return DatePicker(
          inLabel: false,
          key: Key('validUntil'),
          initialDate: initialData,
          label: 'Valid until',
          restorationId: 'Valid until',
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          helperText: msg,
          validator: (v) => v.isNullOrEmpty ? msg : null,
        );
      },
    ),
    FieldGroupConfig(
      key: 'expectedDate',
      label: 'Expected date',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final msg = 'Earliest delivery date for the entire order.';

        return DatePicker(
          inLabel: false,
          key: Key('expectedDate'),
          initialDate: initialData,
          label: 'Expected date',
          restorationId: 'Expected date',
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          helperText: msg,
          validator: (v) => v.isNullOrEmpty ? msg : null,
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

/// Auto Convert Sales Quote & SQStatus Dropdown TextField [AutoCreateAndSQStatus]
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
        // Auto-Convert Sales Quote to 'Sales Order' when after Acceptance
        AutoConvertWorkflow(
          from: 'Quote',
          to: 'Sales Order',
          action: 'customer acceptance',
          isSelected: isSelected,
          onChanged: onAutoConvertChanged,
        ),
        WorkflowStatusDropdown(
          initialValue: initialStatus,
          onChanged: onStatusChanged,
          workflowType: WorkflowType.sq,
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
