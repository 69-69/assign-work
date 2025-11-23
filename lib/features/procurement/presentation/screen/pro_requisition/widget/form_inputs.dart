import 'package:assign_erp/core/constants/erp_priority_enum.dart';
import 'package:assign_erp/core/constants/item_category.dart';
import 'package:assign_erp/core/constants/requisition_status.dart';
import 'package:assign_erp/core/constants/unit_of_measure.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/staff_account/widget/search_employees.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/search_departments.dart';
import 'package:flutter/material.dart';

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
        PRStatusDropdown(
          initialValue: initialStatus,
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}

/// Request & Required(Needed) Date TextField [RequestAndRequiredDateInput]
class RequestAndRequiredDateInput extends StatelessWidget {
  const RequestAndRequiredDateInput({
    super.key,
    this.labelRequest,
    this.labelRequired,
    required this.onRequestChanged,
    required this.onRequiredChanged,
    this.initialRequestDate,
    this.initialRequiredDate,
  });

  final String? initialRequestDate;
  final String? initialRequiredDate;
  final String? labelRequest;
  final String? labelRequired;
  final Function(DateTime) onRequestChanged;
  final Function(DateTime) onRequiredChanged;

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
          helperText: 'When the requisition was initiated',
        ),
        DatePicker(
          inLabel: false,
          initialDate: initialRequiredDate,
          label: labelRequired,
          restorationId: 'Required date',
          selectedDate: onRequiredChanged,
          helperText: 'When the requisition is needed.',
        ),
      ],
    );
  }
}

/// Purchase Requisition Status [PRStatusDropdown]
class PRStatusDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const PRStatusDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      label: 'PR status',
      initialValue: initialValue,
      items: PRStatusHelper.toStringList(),
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}

/// Purchase Requisition Priority/Urgency [PriorityDropdown]
class PriorityDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const PriorityDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      label: 'priority',
      initialValue: initialValue,
      items: PriorityHelper.toStringList(),
      getDisplayText: (priority) => priority,
      onChanged: onChanged,
    );
  }
}

/// Purchase Requisition Item Category [ItemCategoryDropdown]
class ItemCategoryDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(String? s) onChanged;

  const ItemCategoryDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final strList = ItemCategoryHelper.toStringList();

    return StaticDropdown<String>(
      key: key,
      label: strList.first,
      initialValue: initialValue,
      items: strList,
      getDisplayText: (priority) => priority.toTitle,
      onChanged: onChanged,
    );
  }
}

/// Purchase Requisition unit of measure [UnitOfMeasureDropdown]
class UnitOfMeasureDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(String? s) onChanged;

  const UnitOfMeasureDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final strList = UOMHelper.toStringList();

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
