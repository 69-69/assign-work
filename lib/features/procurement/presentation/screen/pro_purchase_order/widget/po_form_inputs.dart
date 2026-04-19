import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/form/currency_dropdown.dart';
import 'package:assign_erp/core/widgets/form/pay_methods_dropdown.dart';
import 'package:assign_erp/core/widgets/form/pay_terms_dropdown.dart';
import 'package:assign_erp/core/widgets/form/workflow_status_dropdown.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/procurement/data/data_sources/remote/get_suppliers.dart';
import 'package:assign_erp/features/procurement/data/model/pro_purchase_order_model.dart';
import 'package:assign_erp/features/procurement/data/model/workflow_converter_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/widget/search_request_for_quotes.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_supplier/supplier_account/widget/search_suppliers.dart';
import 'package:assign_erp/features/procurement/presentation/screen/widget/procurement_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_company.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_taxes.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/employee_account/widget/search_employees.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/search_departments.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/tax_master/widget/search_taxes.dart';
import 'package:flutter/material.dart';

class POFormInputs {
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

  /// Get Company Info and Addresses
  static Future<AddressInfo?> getCompanyAddress({
    String type = 'shipping',
  }) async {
    final company = await GetCompany.load();
    return company.isNullOrEmpty ? null : company?.getByType(type);
  }

  static updateListFromData<T>(
    List<T> list, {
    required List<Map<String, dynamic>> map,
    required T Function(Map<String, dynamic>, String) fromMap,
  }) => ProcurementFormFields.updateListFromData<T>(
    list,
    map: map,
    fromMap: fromMap,
  );

  /// Apply taxes to PO
  static Future<ProPurchaseOrder> applyTaxesToQuote(
    ProPurchaseOrder order,
  ) async {
    final taxMap = await GetTaxes.loadAllTaxRates();
    return order.calculateTaxes(taxMap);
  }

  /// Get Supplier by ID
  static Future getSupplier(String supplierId) async {
    final supplier = await GetSuppliers.bySupplierId(supplierId);
    return supplier.isEmpty ? null : supplier;
  }

  /// Build PO Number (using the parent method)
  static Widget buildPONumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => ProcurementFormFields.buildNumber(
    context,
    what: 'PO',
    count: count,
    onPressed: onPressed,
  );

  static List<FieldGroupConfig> fields(
    String type, {
    bool isDisabled = false,
    bool isHidden = false,
    List<String> keysToExclude = const ['limitQuantity', 'limitAmount'],
  }) {
    final fields = ProcurementFormFields.fields(
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

  /// Additional Notes for PO
  static List<FieldGroupConfig> get deliveryFields => [
    FieldGroupConfig(
      key: 'notes',
      label: 'Additional Notes (if any)...',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'termsAndConditions',
      label: 'Terms & Conditions (if any)...',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
  ];

  /// Addresses (e.g., Billing, Shipping Address)
  static List<FieldGroupConfig> get addressFields =>
      ProcurementFormFields.addressFields();

  /// Suppliers Fields
  static List<FieldGroupConfig> get suppliersFields =>
      ProcurementFormFields.suppliersFields();

  static AuditProcurement<ProPurchaseOrder> updateHistory({
    required String empId,
    required AuditAction action,
    required ProPurchaseOrder order,
  }) {
    final up = AuditProcurement<ProPurchaseOrder>(
      documentId: order.id,
      log: AuditLog.logScaffold(
        oldLogs: order.history,
        newLog: AuditLog(
          action: action,
          actionBy: empId,
          statusAfterAction: order.getPOStatus,
        ),
      ),
    );
    return up;
  }
}

/// [FindApprovedRFQ] Search RFQ to create PO
/// For Converting [Request For Quote] to [Purchase Order]: RFQ to PO
class FindApprovedRFQ extends StatelessWidget {
  final void Function() onCreateNewPO;
  final void Function(WorkflowConverter) onValueChanged;

  const FindApprovedRFQ({
    super.key,
    required this.onCreateNewPO,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffold(
      title: 'Create Purchase Order',
      body: FormGroupCard(
        title: '[Request for Quote] → PO',
        subTitle: '\nSearch for and select a RFQ to convert into a new PO.\n',
        children: [
          SearchRFQs(
            actionButtonText: 'Create New PO',
            onActionPressed: onCreateNewPO,
            onValueChanged: (map) =>
                onValueChanged.call(WorkflowConverter.fromMap(map)),
          ),
        ],
      ),
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
        CurrencyDropdown(
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

/// RFQStatus & RequestedBy Dropdown [POStatusAndRequestedBy]
class POStatusAndRequestedBy extends StatelessWidget {
  const POStatusAndRequestedBy({
    super.key,
    this.initialStatus,
    required this.onStatusChanged,
    this.initialRequestedBy,
    required this.onRequestedChanged,
  });

  final String? initialStatus;
  final void Function(dynamic) onStatusChanged;
  final String? initialRequestedBy;
  final void Function(String, String, String) onRequestedChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        WorkflowStatusDropdown(
          initialValue: initialStatus,
          onChanged: onStatusChanged,
          workflowType: WorkflowType.po,
        ),
        SearchEmployees(
          labelText: 'Requested by',
          initialValue: initialRequestedBy,
          onChanged: onRequestedChanged,
        ),
      ],
    );
  }
}

/// Payment Method & Terms Dropdown [PayMethodAndTermsDropdown]
class PayMethodAndTermsDropdown extends StatelessWidget {
  const PayMethodAndTermsDropdown({
    super.key,
    this.initialPayTerms,
    required this.onPayTermsChanged,
    this.initialPayMethod,
    required this.onPayMethodChanged,
  });

  final String? initialPayTerms;
  final void Function(dynamic) onPayTermsChanged;
  final String? initialPayMethod;
  final void Function(dynamic) onPayMethodChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PayTermsDropdown(
          initialValue: initialPayTerms,
          onChange: onPayTermsChanged,
        ),
        PayMethodsDropdown(
          initialValue: initialPayMethod,
          onChanged: onPayMethodChanged,
        ),
      ],
    );
  }
}

/// Delivery Date picker [DeliveryDate]
class DeliveryDate extends StatelessWidget {
  const DeliveryDate({
    super.key,
    this.labelDelivery,
    this.initialDeliveryDate,
    required this.onDeliveryChanged,
    this.initialContact,
    required this.onContactChanged,
  });

  final String? initialDeliveryDate;
  final String? labelDelivery;
  final Function(DateTime) onDeliveryChanged;
  final String? initialContact;
  final void Function(String empId, String name, String role) onContactChanged;

  @override
  Widget build(BuildContext context) {
    final msg = 'Expected delivery date for the PO.';

    return AdaptiveLayout(
      children: [
        BuyerContactPerson(
          isDisabled: false,
          initialValue: initialContact,
          onChanged: onContactChanged,
        ),
        DatePicker(
          inLabel: false,
          initialDate: initialDeliveryDate,
          label: labelDelivery,
          restorationId: 'Delivery date',
          selectedDate: onDeliveryChanged,
          helperText: msg,
          validator: (v) => v.isNullOrEmpty ? msg : null,
        ),
      ],
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
