import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/form/auto_convert_workflow.dart';
import 'package:assign_erp/core/widgets/form/currency_dropdown.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:assign_erp/core/widgets/form/workflow_status_dropdown.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/procurement/data/data_sources/remote/get_suppliers.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/data/model/workflow_converter_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_requisition/widget/search_purchase_requisitions.dart';
import 'package:assign_erp/features/procurement/presentation/screen/widget/procurement_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_company.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_taxes.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/employee_account/widget/search_employees.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/department_dropdown.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/tax_master/widget/search_taxes.dart';
import 'package:flutter/material.dart';

class RFQFormInputs {
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
  }) => ProcurementFormFields.updateListFromData<T>(
    list,
    map: map,
    fromMap: fromMap,
  );

  /// Apply taxes to RFQ
  static Future<RequestForQuote> applyTaxesToRFQ(RequestForQuote rfq) async {
    final taxMap = await GetTaxes.loadAllTaxRates();
    return rfq.calculateTaxes(taxMap);
  }

  /// Get Supplier by ID
  static Future getSupplier(String supplierId) async {
    final supplier = await GetSuppliers.bySupplierId(supplierId);
    return supplier.isEmpty ? null : supplier;
  }

  /// Get Company Info and Addresses
  static Future<AddressInfo?> getCompanyAddress({
    String type = 'shipping',
  }) async {
    final company = await GetCompany.load();
    return company.isNullOrEmpty ? null : company?.getByType(type);
  }

  /// Build RFQ Number (using the parent method)
  static Widget buildRFQNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => ProcurementFormFields.buildNumber(
    context,
    what: 'RFQ',
    count: count,
    onPressed: onPressed,
  );

  static List<FieldGroupConfig> fields(
    String type, {
    bool isDisabled = false,
    bool isHidden = false,
    List<String> keysToExclude = const [
      'discount',
      'unitPrice',
      'netPrice',
      'serviceRate',
      'limitAmount',
      'limitQuantity',
      'leadTimeDays',
      'taxCodes',
    ],
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

  /// Buyer Terms and Conditions for RFQ
  static List<FieldGroupConfig> get buyerTermsFields => [
    FieldGroupConfig(
      key: 'buyerContactPerson',
      label: 'Contact Person',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return BuyerContactPerson(
          isDisabled: false,
          initialValue: initialData,
          onChanged: (id, firstName, lastName) => onChanged(id),
        );
      },
    ),
    FieldGroupConfig(
      key: 'expectedDate',
      label: 'Expected date',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final msg = 'Expected delivery date after order confirmation';

        return DatePicker(
          inLabel: false,
          initialDate: initialData,
          label: 'Expected date',
          restorationId: 'Expected date',
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          helperText: msg,
          validator: (s) => s.isNullOrEmpty ? msg : null,
        );
      },
    ),
    FieldGroupConfig(
      key: 'deadline',
      label: 'Quotation deadline',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final msg = 'Final date for supplier to submit quote.';

        return DatePicker(
          inLabel: false,
          initialDate: initialData,
          label: 'Quotation deadline',
          restorationId: 'Quotation deadline date',
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          helperText: msg,
          validator: (s) => s.isNullOrEmpty ? msg : null,
        );
      },
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

  /// NOT-Needed: Delivery Address and Notes for RFQ
  static List<FieldGroupConfig> get deliveryFields => [
    FieldGroupConfig(
      key: 'deliveryAddress',
      label: 'Delivery address (if any)...',
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

  /// Suppliers Fields
  static List<FieldGroupConfig> get suppliersFields =>
      ProcurementFormFields.suppliersFields();

  /// Addresses (e.g., Buyer Shipping Address)
  static List<FieldGroupConfig> get shippingAddressFields =>
      ProcurementFormFields.addressFields(initialValue: 'Shipping');

  static AuditProcurement<RequestForQuote> updateHistory({
    required String empId,
    required AuditAction action,
    required RequestForQuote rfq,
  }) {
    final up = AuditProcurement<RequestForQuote>(
      documentId: rfq.id,
      log: AuditLog.logScaffold(
        oldLogs: rfq.history,
        newLog: AuditLog(
          action: action,
          actionBy: empId,
          statusAfterAction: rfq.getRFQStatus,
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
        subTitle: '\nSearch for and select a PR to convert into a new RFQ.\n',
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
          onChanged: (({String code, String symbol, String country})? s) =>
              onCurrencyChanged(s!.code),
        ),
        DepartmentDropdown(
          label: 'Cost Center...',
          initialValue: initialCostCenter,
          onChanged: (id, code, name) => onCostCenterChange(id, code, name),
        ),
      ],
    );
  }
}

/// Auto Convert PO & RFQStatus Dropdown TextField [AutoCreateAndRFQStatus]
class AutoCreateAndRFQStatus extends StatelessWidget {
  const AutoCreateAndRFQStatus({
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
        // Auto-convert RFQ to PO after acceptance
        AutoConvertWorkflow(
          from: 'RFQ',
          to: 'PO',
          action: 'acceptance',
          isSelected: isSelected,
          onChanged: onAutoConvertChanged,
        ),
        WorkflowStatusDropdown(
          initialValue: initialStatus,
          onChanged: onStatusChanged,
          workflowType: WorkflowType.rfq,
        ),
      ],
    );
  }
}

/// [RequestedByAndDepartments]
class RequestedByAndDepartments extends StatelessWidget {
  final bool isDisabled;
  final String? initialDepartment;
  final String? initialRequestedBy;
  final void Function(String, String, String) onRequestedChanged;
  final void Function(String, String, String) onDepartmentChange;

  const RequestedByAndDepartments({
    super.key,
    this.isDisabled = false,
    this.initialDepartment,
    this.initialRequestedBy,
    required this.onRequestedChanged,
    required this.onDepartmentChange,
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
          labelText: 'requested by',
          initialValue: initialRequestedBy,
          onChanged: onRequestedChanged,
        ),
        DepartmentDropdown(
          initialValue: initialDepartment,
          onChanged: (id, code, name) => onDepartmentChange(id, code, name),
        ),
      ],
    );
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
