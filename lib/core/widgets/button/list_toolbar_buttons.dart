import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:flutter/material.dart';

class ListToolbarButtons extends StatelessWidget {
  // Callbacks
  final Function()? onRefresh;
  final Function()? onPrimary;
  final Function()? onDanger;
  final Function()? onCompare;
  final Function()? onTertiary;
  final Function()? onWarning;
  final Function()? onSecondary;
  final Function()? onPermanent;
  // Labels
  final String refreshLabel;
  final String primaryLabel;
  final String dangerLabel;
  final String compareLabel;
  final String tertiaryLabel;
  final String warningLabel;
  final String secondaryLabel;
  final String permanentLabel;
  // Tooltips
  final String? permanentTooltip;
  final String? secondaryTooltip;
  final String? tertiaryTooltip;
  final String? primaryTooltip;
  final String? warningTooltip;
  final String? dangerTooltip;
  // Icons
  final IconData? permanentIcon;
  final IconData? secondaryIcon;
  final IconData? tertiaryIcon;
  final IconData? warningIcon;
  final int dataLength;

  const ListToolbarButtons({
    super.key,
    this.onRefresh,
    this.onCompare,
    this.onPrimary,
    this.onDanger,
    this.onWarning,
    this.onTertiary,
    this.onSecondary,
    this.onPermanent,
    this.permanentLabel = '',
    this.secondaryLabel = '',
    this.tertiaryLabel = '',
    this.refreshLabel = '',
    this.compareLabel = '',
    this.primaryLabel = '',
    this.warningLabel = '',
    this.dangerLabel = '',
    this.permanentTooltip,
    this.secondaryTooltip,
    this.tertiaryTooltip,
    this.primaryTooltip,
    this.warningTooltip,
    this.dangerTooltip,
    this.permanentIcon,
    this.secondaryIcon,
    this.tertiaryIcon,
    this.warningIcon,
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

    if (onPrimary != null) ...[
      const SizedBox(width: 10),
      _primaryButton(context),
    ],

    if (onCompare != null) ...[
      const SizedBox(width: 10),
      _compareButton(context),
    ],

    if (onSecondary != null) ...[
      const SizedBox(width: 10),
      _secondaryButton(context),
    ],

    if (onTertiary != null) ...[
      const SizedBox(width: 10),
      _tertiaryButton(context),
    ],

    if (onWarning != null) ...[
      const SizedBox(width: 10),
      _warningButton(context),
    ],

    if (onDanger != null) ...[
      const SizedBox(width: 10),
      _dangerButton(context),
    ],

    if (onPermanent != null) ...[
      const SizedBox(width: 10),
      _permanentButton(context),
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

  Widget _primaryButton(BuildContext context) {
    return _button(
      context,
      label: primaryLabel,
      onPressed: onPrimary,
      bgColor: kPrimaryColor,
      tooltip: primaryTooltip ?? primaryLabel,
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

  Widget _secondaryButton(BuildContext context) {
    return _button(
      context,
      icon: secondaryIcon,
      label: secondaryLabel,
      tooltip: secondaryTooltip ?? secondaryLabel,
      onPressed: onSecondary,
      bgColor: kBrightPrimaryColor,
    );
  }

  Widget _tertiaryButton(BuildContext context) {
    return _button(
      context,
      icon: tertiaryIcon,
      label: tertiaryLabel,
      tooltip: tertiaryTooltip ?? tertiaryLabel,
      onPressed: onTertiary,
      bgColor: kPrimaryAccentColor,
    );
  }

  Widget _warningButton(BuildContext context) {
    return _button(
      context,
      icon: warningIcon,
      label: warningLabel,
      tooltip: warningTooltip ?? warningLabel,
      onPressed: onWarning,
      bgColor: kWarningColor,
    );
  }

  Widget _dangerButton(BuildContext context) {
    return _button(
      context,
      label: dangerLabel,
      bgColor: kDangerColor,
      tooltip: dangerTooltip ?? dangerLabel,
      onPressed: onDanger,
      icon: Icons.delete,
    );
  }

  Widget _permanentButton(BuildContext context) {
    return _button(
      context,
      label: permanentLabel,
      bgColor: kBgLightColor,
      tooltip: permanentTooltip ?? permanentLabel,
      onPressed: onPermanent,
      icon: permanentIcon,
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
    txtColor: txtColor ?? kWhiteColor,
    shadowColor: shadowColor,
    onPressed: onPressed,
    showLabel: showLabel,
  );
}
