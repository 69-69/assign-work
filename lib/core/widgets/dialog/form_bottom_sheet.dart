import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:flutter/material.dart';

class FormBottomSheet extends StatelessWidget {
  final String title;
  final Widget body;
  final String? subtitle;
  final Color? subTitleColor;
  final double? initialChildSize;
  final double? maxChildSize;

  const FormBottomSheet({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.subTitleColor,
    this.initialChildSize,
    this.maxChildSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      padding: EdgeInsets.only(bottom: context.bottomInsetPadding),
      initialChildSize: initialChildSize ?? 0.98,
      maxChildSize: maxChildSize ?? 0.98,
      header: _buildHeader(context),
      child: _buildBody(context),
    );
  }

  DialogHeader _buildHeader(BuildContext context) {
    return DialogHeader(
      title: ListTile(
        dense: true,
        title: Text(
          title,
          semanticsLabel: title,
          textAlign: TextAlign.center,
          style: context.textTheme.titleLarge?.copyWith(color: kGrayColor),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!.toTitleCase,
                semanticsLabel: subtitle,
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium?.copyWith(
                  color: subTitleColor ?? kGrayColor,
                ),
              )
            : null,
      ),
      btnText: 'Close',
      onPress: () => Navigator.pop(context),
    );
  }

  _buildBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: body,
    );
  }
}
