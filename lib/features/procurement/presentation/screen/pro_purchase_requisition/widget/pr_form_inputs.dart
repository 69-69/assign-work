import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/erp_priority_enum.dart';
import 'package:assign_erp/core/constants/unit_of_measure.dart';
import 'package:assign_erp/core/constants/workflow_status.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/widget/procurement_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_employees.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/staff_account/widget/search_employees.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/search_departments.dart';
import 'package:flutter/material.dart';

class PRFormInputs {
  static updateListFromData<T>(
    List<T> list, {
    required List<Map<String, dynamic>> map,
    required T Function(Map<String, dynamic>, String) fromMap,
  }) => ProcurementForm.updateListFromData<T>(list, map: map, fromMap: fromMap);

  static Widget buildPRNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => ProcurementForm.buildNumber(
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
  }) => ProcurementForm.fields(type, keysToExclude: keysToExclude);

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
        _AutoCreatePr(
          isSelected: isSelected,
          onAutoConvertChanged: onAutoConvertChanged,
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
        _PriorityDropdown(
          initialValue: initialPriority,
          onChanged: onPriorityChanged,
        ),
        _PRStatusDropdown(
          initialValue: initialStatus,
          onChanged: onStatusChanged,
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
          helperText: 'When the entire requisition was initiated',
        ),
        DatePicker(
          inLabel: false,
          initialDate: initialExpectedDate,
          label: labelExpected,
          restorationId: 'Expected date',
          selectedDate: onExpectedChanged,
          helperText:
              'When the entire requisition is expected to be completed.',
        ),
      ],
    );
  }
}

/// Purchase Requisition unit of measure [UnitOfMeasureDropdown]
class UnitOfMeasureDropdown extends StatelessWidget {
  final String? label;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const UnitOfMeasureDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = UOMHelper.toStringList();
    // If label is provided, replace it with the first in the list
    if (label != null) strList[0] = label!;

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

/// [_AutoCreatePr] Auto-convert PR to RFQ after approval
class _AutoCreatePr extends StatelessWidget {
  final bool isSelected;
  final void Function(bool) onAutoConvertChanged;

  const _AutoCreatePr({
    required this.isSelected,
    required this.onAutoConvertChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-Convert RFQ to PR when PR is Approved
    return CustomCheckboxTile(
      title: Text(
        'Auto Convert PR?',
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text('Auto-convert PR to RFQ after approval'),
      contentPadding: EdgeInsets.symmetric(horizontal: 6.0),
      value: isSelected,
      onChanged: (v) => onAutoConvertChanged(v ?? false),
    );
    /*CustomSwitchTile(
      title: 'Auto Create RFQ',
      subtitle: 'Generate RFQ when PR is approved',
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      isSelected: isSelected,
      onChanged: onChanged,
    );*/
  }
}

/// Purchase Requisition Status [_PRStatusDropdown]
class _PRStatusDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const _PRStatusDropdown({required this.onChanged, this.initialValue});

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      label: 'PR status',
      initialValue: initialValue,
      items: WorkflowStatusHelper.toStringList(type: WorkflowType.pr),
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}

/// Purchase Requisition Priority/Urgency [_PriorityDropdown]
class _PriorityDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const _PriorityDropdown({required this.onChanged, this.initialValue});

  @override
  Widget build(BuildContext context) {
    final strList = PriorityHelper.toStringList();

    return StaticDropdown<String>(
      key: key,
      label: 'priority',
      initialValue: initialValue,
      items: strList,
      getDisplayText: (priority) => priority,
      onChanged: onChanged,
    );
  }
}
