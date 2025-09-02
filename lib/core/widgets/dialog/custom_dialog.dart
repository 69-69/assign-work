import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  const CustomDialog({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.bgColor,
    this.icon,
  });

  final Widget title;
  final Widget body;
  final List<Widget> actions;
  final Color? bgColor;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      icon: Align(
        alignment: Alignment.topRight,
        child:
            icon ??
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: kWhiteColor.toAlpha(0.4),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: kTextColor),
            ),
      ),
      iconPadding: const EdgeInsets.only(right: 5, top: 5),
      backgroundColor: bgColor ?? kWhiteColor.toAlpha(0.8),
      title: title,
      content: body,
      actions: actions,
    );
  }
}
