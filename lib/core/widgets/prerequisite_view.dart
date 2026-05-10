import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:flutter/material.dart';

class PrerequisiteView extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final TextStyle? style;

  const PrerequisiteView({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 10,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: style ?? context.textTheme.bodyLarge,
        ),
        context.elevatedButton(
          actionLabel,
          onPressed: onAction,
        ),
      ],
    );
  }
}