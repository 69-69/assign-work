import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class FormGroupCard extends StatelessWidget {
  final String title;
  final Color? bgColor;
  final Color? textColor;
  final List<Widget> children;

  const FormGroupCard({
    super.key,
    this.bgColor,
    this.textColor,
    this.title = '',
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      color: bgColor ?? context.onSecondaryColor, // context.scaffoldBgColor
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          runSpacing: 16,
          children: [
            if (title.isNotEmpty) ...{
              Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  color: textColor ?? context.onPrimaryContainer.toAlpha(0.8),
                ),
              ),
            },
            ...children,
          ],
        ),
      ),
    );
  }
}
