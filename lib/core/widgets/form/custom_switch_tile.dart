import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomSwitchTile extends StatelessWidget {
  final ValueChanged<bool>? onChanged;
  final bool dense;
  final dynamic title;
  final dynamic subtitle;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;

  const CustomSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onChanged,
    this.padding,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      dense: dense,
      contentPadding: padding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: title is Widget
          ? title
          : Text(
              title,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
      subtitle: subtitle is Widget
          ? subtitle
          : Text(subtitle, style: context.textTheme.bodySmall),
      value: isSelected,
      onChanged: onChanged,
    );
  }
}
