import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:flutter/material.dart';

class FormBottomSheet extends StatelessWidget {
  final bool isDetails;
  final String title;
  final String? tooltip;
  final Widget body;
  final double? initialSize;
  final String? subtitle;
  final Color? subTitleColor;
  final Function()? onPrint;

  const FormBottomSheet({
    super.key,
    this.isDetails = false,
    this.initialSize,
    required this.title,
    required this.body,
    this.subtitle,
    this.tooltip,
    this.subTitleColor,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final size = isDetails ? 0.92 : 0.98;
    return CustomDraggableBottomSheet(
      padding: EdgeInsets.only(bottom: context.bottomInsetPadding),
      initialChildSize: initialSize ?? size,
      maxChildSize: size,
      header: isDetails
          ? _buildViewDetailsHeader(context)
          : _buildHeader(context),
      child: _buildBody(context),
    );
  }

  DialogHeader _buildHeader(BuildContext context) {
    return DialogHeader(
      title: ListTile(
        dense: true,
        title: _buildTitle(context),
        subtitle: _buildSubtitle(context),
        contentPadding: EdgeInsets.zero,
      ),
      btnText: 'Close',
      onPress: () => Navigator.pop(context),
    );
  }

  DialogHeader _buildViewDetailsHeader(BuildContext context) {
    return DialogHeader(
      title: ListTile(
        dense: true,
        title: _buildTitle(context),
        subtitle: _buildSubtitle(context),
      ),
      btnText: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8.0,
        children: [
          if (onPrint != null) ...{
            context.elevatedButton(
              'Print',
              bgColor: kWarningColor,
              tooltip: tooltip ?? 'Print out',
              onPressed: onPrint,
            ),
          },
          IconButton(
            icon: Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      onPress: () => Navigator.pop(context),
    );
  }

  Text? _buildSubtitle(BuildContext context) {
    return subtitle != null
        ? Text(
            subtitle!.toTitle,
            semanticsLabel: subtitle,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              color: subTitleColor ?? kGrayColor,
            ),
          )
        : null;
  }

  Text _buildTitle(BuildContext context) {
    return Text(
      title,
      semanticsLabel: title,
      textAlign: TextAlign.center,
      style: context.textTheme.titleLarge?.copyWith(color: kGrayColor),
    );
  }

  _buildBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: body,
    );
  }
}
