import 'package:assign_erp/core/util/extensions/workflow_status.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

class WorkflowStatusDropdown extends StatelessWidget {
  final String? initialValue;
  final WorkflowType workflowType;
  final void Function(dynamic s) onChanged;

  const WorkflowStatusDropdown({
    super.key,
    required this.workflowType,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      label: 'Status',
      initialValue: initialValue,
      items: WorkflowStatusUtil.toStringList(type: workflowType),
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}
