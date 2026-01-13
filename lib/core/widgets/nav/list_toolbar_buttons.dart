import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:flutter/material.dart';

class ListToolbarButtons extends StatelessWidget {
  final Function()? onRefresh;
  final Function()? onCreate;
  final Function()? onDelete;
  final Function()? onCompare;
  final Function()? optOnPressed;
  final String refreshLabel;
  final String createLabel;
  final String deleteLabel;
  final String compareLabel;
  final String optLabel;
  final IconData? optIcon;
  final String optTooltip;
  final int count;

  const ListToolbarButtons({
    super.key,
    this.onRefresh,
    this.onCreate,
    this.onDelete,
    this.onCompare,
    this.optOnPressed,
    this.createLabel = '',
    this.deleteLabel = '',
    this.refreshLabel = '',
    this.compareLabel = '',
    this.optTooltip = '',
    this.optLabel = '',
    this.optIcon,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      isFormBuilder: false,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _buildToolbar(context),
    );
  }

  List<Widget> _buildToolbar(BuildContext context) => [
    if (onRefresh != null) ...{
      context.actionInfoButton(
        'Refresh List',
        label: refreshLabel,
        count: count,
        onPressed: onRefresh,
      ),
    },

    if (onCreate != null) ...[
      const SizedBox(width: 20),
      _button(
        context,
        label: createLabel,
        onPressed: onCreate,
        bgColor: kDangerColor,
        tooltip: createLabel,
        icon: Icons.add,
      ),
    ],

    if (onDelete != null) ...[
      const SizedBox(width: 20),
      _button(
        context,
        label: 'Delete',
        bgColor: kDangerColor,
        txtColor: kWhiteColor,
        tooltip: 'Delete selected $deleteLabel',
        onPressed: onDelete,
        icon: Icons.delete,
      ),
    ],

    if (onCompare != null) ...[
      const SizedBox(width: 20),
      _button(
        context,
        label: 'Compare $compareLabel',
        onPressed: onCompare,
        bgColor: kSuccessColor,
        tooltip: 'Compare two $compareLabel',
        icon: Icons.compare_arrows,
      ),
    ],

    if (optOnPressed != null) ...{
      _button(
        context,
        icon: optIcon,
        label: optLabel,
        tooltip: optTooltip,
        onPressed: optOnPressed,
        bgColor: kGrayBlueColor,
      ),
    },
  ];

  Widget _button(
    BuildContext context, {
    required String label,
    required Color bgColor,
    IconData? icon,
    String? tooltip,
    Color? txtColor,
    VoidCallback? onPressed,
    bool showLabel = false,
  }) => context.toolbarButton(
    label: label,
    bgColor: bgColor,
    icon: icon,
    tooltip: tooltip,
    txtColor: txtColor,
    onPressed: onPressed,
    showLabel: showLabel,
  );
}
