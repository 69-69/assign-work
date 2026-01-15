import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:flutter/material.dart';

/// [AutoConvertWorkflow] Auto-convert Workflow to RFQ, PO after approval/acceptance
class AutoConvertWorkflow extends StatelessWidget {
  final String from;
  final String to;
  final String action;
  final bool isSelected;
  final void Function(bool) onChanged;

  const AutoConvertWorkflow({
    super.key,
    required this.from,
    required this.to,
    required this.action,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCheckboxTile(
      title: Text(
        'Auto Convert $from?',
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text('Auto-convert $from to $to after $action'),
      contentPadding: EdgeInsets.symmetric(horizontal: 6.0),
      value: isSelected,
      onChanged: (v) => onChanged(v ?? false),
    );
  }

  /*CustomSwitchTile(
      title: 'Auto Create PO',
      subtitle: 'Generate PO when RFQ is accepted',
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      isSelected: isSelected,
      onChanged: onChanged,
    );*/
}
