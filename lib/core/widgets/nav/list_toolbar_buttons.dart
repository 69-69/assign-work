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
  final Function()? auxOnPressed;
  final Function()? subOnPressed;
  final String refreshLabel;
  final String createLabel;
  final String deleteLabel;
  final String compareLabel;
  final String optLabel;
  final String auxLabel;
  final String subLabel;
  final IconData? subIcon;
  final IconData? optIcon;
  final IconData? auxIcon;
  final String optTooltip;
  final String subTooltip;
  final String auxTooltip;
  final int dataLength;

  const ListToolbarButtons({
    super.key,
    this.onRefresh,
    this.onCreate,
    this.onDelete,
    this.onCompare,
    this.optOnPressed,
    this.auxOnPressed,
    this.subOnPressed,
    this.subLabel = '',
    this.subTooltip = '',
    this.subIcon,
    this.createLabel = '',
    this.deleteLabel = '',
    this.refreshLabel = '',
    this.compareLabel = '',
    this.optLabel = '',
    this.auxLabel = '',
    this.optTooltip = '',
    this.auxTooltip = '',
    this.auxIcon,
    this.optIcon,
    this.dataLength = 0,
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
    if (onRefresh != null) ...{_refreshButton(context)},

    if (onCreate != null) ...[
      const SizedBox(width: 10),
      _createButton(context),
    ],

    if (onCompare != null) ...[
      const SizedBox(width: 10),
      _compareButton(context),
    ],

    if (optOnPressed != null) ...[
      const SizedBox(width: 10),
      _optButton(context),
    ],

    if (subOnPressed != null) ...[
      const SizedBox(width: 10),
      _subButton(context),
    ],

    if (auxOnPressed != null) ...[
      const SizedBox(width: 10),
      _auxButton(context),
    ],

    if (onDelete != null) ...[
      const SizedBox(width: 10),
      _deleteButton(context),
    ],
  ];

  Widget _refreshButton(BuildContext context) {
    return context.actionInfoButton(
      'Refresh List',
      label: refreshLabel,
      count: dataLength,
      onPressed: onRefresh,
    );
  }

  Widget _createButton(BuildContext context) {
    return _button(
      context,
      label: createLabel,
      onPressed: onCreate,
      bgColor: kPrimaryColor,
      tooltip: createLabel,
      icon: Icons.add,
    );
  }

  Widget _compareButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [kSuccessColor, kWarningColor],
          stops: [0.5, 0.5],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: _button(
        context,
        label: 'Compare $compareLabel',
        onPressed: onCompare,
        bgColor: kTransparentColor,
        shadowColor: kTransparentColor,
        tooltip: 'Compare two $compareLabel',
        icon: Icons.compare_arrows,
      ),
    );
  }

  Widget _subButton(BuildContext context) {
    return _button(
      context,
      icon: subIcon,
      label: subLabel,
      tooltip: subTooltip,
      onPressed: subOnPressed,
      bgColor: kBrightPrimaryColor,
    );
  }

  Widget _optButton(BuildContext context) {
    return _button(
      context,
      icon: optIcon,
      label: optLabel,
      tooltip: optTooltip,
      onPressed: optOnPressed,
      bgColor: kPrimaryAccentColor,
    );
  }

  Widget _auxButton(BuildContext context) {
    return _button(
      context,
      icon: auxIcon,
      label: auxLabel,
      tooltip: auxTooltip,
      onPressed: auxOnPressed,
      bgColor: kWarningColor,
    );
  }

  Widget _deleteButton(BuildContext context) {
    return _button(
      context,
      label: 'Delete',
      bgColor: kDangerColor,
      txtColor: kWhiteColor,
      tooltip: 'Delete selected $deleteLabel',
      onPressed: onDelete,
      icon: Icons.delete,
    );
  }

  Widget _button(
    BuildContext context, {
    required String label,
    required Color bgColor,
    IconData? icon,
    String? tooltip,
    Color? txtColor,
    VoidCallback? onPressed,
    bool showLabel = false,
    Color? shadowColor,
  }) => context.toolbarButton(
    label: label,
    bgColor: bgColor,
    icon: icon,
    tooltip: tooltip,
    txtColor: txtColor,
    shadowColor: shadowColor,
    onPressed: onPressed,
    showLabel: showLabel,
  );
}
