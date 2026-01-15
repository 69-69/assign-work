import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
import 'package:assign_erp/core/widgets/form/auto_convert_workflow.dart';
import 'package:assign_erp/core/widgets/form/priority_dropdown.dart';
import 'package:assign_erp/core/widgets/form/workflow_status_dropdown.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/widget/procurement_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_employees.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/employee_account/widget/search_employees.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/search_departments.dart';
import 'package:flutter/material.dart';

class PRFormInputs {
  static updateListFromData<T>(
    List<T> list, {
    required List<Map<String, dynamic>> map,
    required T Function(Map<String, dynamic>, String) fromMap,
  }) => ProcurementFormFields.updateListFromData<T>(
    list,
    map: map,
    fromMap: fromMap,
  );

  static Widget buildPRNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => ProcurementFormFields.buildNumber(
    context,
    what: 'PR',
    count: count,
    onPressed: onPressed,
  );

  static Future getEmployee(String empId) async {
    final employee = await GetEmployees.byEmployeeId(empId);
    return employee.isEmpty ? null : employee;
  }

  /// Audit Log Entry (Tracking actions)
  static AuditProcurement<PurchaseRequisition> updateHistory({
    required String empId,
    required AuditAction action,
    required PurchaseRequisition pr,
  }) {
    final up = AuditProcurement<PurchaseRequisition>(
      documentId: pr.id,
      log: AuditLog.logScaffold(
        oldLogs: pr.history,
        newLog: AuditLog(
          action: action,
          actionBy: empId,
          statusAfterAction: pr.getPRStatus,
        ),
      ),
    );
    return up;
  }

  /// Product(Material)/Service Line Item Fields for PR
  static List<FieldGroupConfig> fields(
    String type, {
    List<String>? keysToExclude,
  }) => ProcurementFormFields.fields(
    type,
    keysToExclude: [
      'unitPrice',
      'serviceRate',
      'discount',
      'netPrice',
      ...?keysToExclude,
    ],
  );

  static List<FieldGroupConfig> get justificationFields => [
    FieldGroupConfig(
      key: 'purpose',
      label: 'Purpose / Reason for PR',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
    ),
  ];
}

/// [RequestedByAndDepartments]
class RequestedByAndDepartments extends StatelessWidget {
  final String? initialDepartment;
  final String? initialRequestedBy;
  final void Function(String, String, String) onRequestedBy;
  final void Function(String, String, String) onDepartmentChange;

  const RequestedByAndDepartments({
    super.key,
    this.initialRequestedBy,
    required this.onRequestedBy,
    this.initialDepartment,
    required this.onDepartmentChange,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SearchEmployees(
          labelText: 'requested by',
          initialValue: initialRequestedBy,
          onChanged: onRequestedBy,
        ),
        SearchDepartments(
          initialValue: initialDepartment,
          onChanged: (id, code, name) => onDepartmentChange(id, code, name),
        ),
        /*StaticDropdown<String>(
          key: key,
          items: departmentsList,
          label: 'internal departments',
          inLabel: false,
          helperText: 'e.g., HR, IT, Accounting',
          initialValue: initialDepartment,
          getValue: (department) => department,
          getDisplayText: (department) => department,
          onChanged: (String? v) => onDepartmentChange(v),
        ),*/
      ],
    );
  }
}

/// [AutoAndCostCenterDepartment]
/// Auto create RFQ when PR is Approved and cost center Department (Who pays for the Supplier)
class AutoAndCostCenterDepartment extends StatelessWidget {
  final bool isSelected;
  final void Function(bool) onAutoConvertChanged;
  final String? initialCostCenter;
  final void Function(String, String, String) onCostCenterChange;

  const AutoAndCostCenterDepartment({
    super.key,
    required this.isSelected,
    required this.onAutoConvertChanged,
    this.initialCostCenter,
    required this.onCostCenterChange,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      children: [
        // Auto-convert PR to RFQ after approval
        AutoConvertWorkflow(
          from: 'PR',
          to: 'RFQ',
          action: 'approval',
          isSelected: isSelected,
          onChanged: onAutoConvertChanged,
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

/// Priority & PRStatus Dropdown TextField [PriorityAndPRStatusDropdown]
class PriorityAndPRStatusDropdown extends StatelessWidget {
  const PriorityAndPRStatusDropdown({
    super.key,
    this.initialStatus,
    required this.onStatusChanged,
    this.initialPriority,
    required this.onPriorityChanged,
  });

  final String? initialPriority;
  final void Function(dynamic) onPriorityChanged;
  final String? initialStatus;
  final void Function(dynamic) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PriorityDropdown(
          initialValue: initialPriority,
          onChanged: onPriorityChanged,
        ),
        WorkflowStatusDropdown(
          initialValue: initialStatus,
          onChanged: onStatusChanged,
          workflowType: WorkflowType.pr,
        ),
      ],
    );
  }
}

/// Request & Required(Needed) Date TextField [RequestAndExpectedDate]
class RequestAndExpectedDate extends StatelessWidget {
  const RequestAndExpectedDate({
    super.key,
    this.labelRequest,
    this.labelExpected,
    required this.onRequestChanged,
    required this.onExpectedChanged,
    this.initialRequestDate,
    this.initialExpectedDate,
  });

  final String? initialRequestDate;
  final String? initialExpectedDate;
  final String? labelRequest;
  final String? labelExpected;
  final Function(DateTime) onRequestChanged;
  final Function(DateTime) onExpectedChanged;

  String get _msgExpected =>
      'When the entire requisition is expected to be completed.';

  String get _msgRequest => 'When the entire requisition was initiated';

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DatePicker(
          inLabel: false,
          initialDate: initialRequestDate,
          label: labelRequest,
          restorationId: 'Request date',
          selectedDate: onRequestChanged,
          helperText: _msgRequest,
          validator: (v) => v == null ? _msgRequest : null,
        ),
        DatePicker(
          inLabel: false,
          initialDate: initialExpectedDate,
          label: labelExpected,
          restorationId: 'Expected date',
          selectedDate: onExpectedChanged,
          helperText: _msgExpected,
          validator: (v) => v == null ? _msgExpected : null,
        ),
      ],
    );
  }
}
