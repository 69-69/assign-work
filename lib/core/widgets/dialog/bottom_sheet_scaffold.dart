import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:flutter/material.dart';

class BottomSheetScaffold extends StatelessWidget {
  final Widget body;
  final dynamic title;
  final dynamic btnText;
  final String? tooltip;
  final dynamic subtitle;
  final bool isDetailMode;
  final bool confirmOnClose; // Confirm on accidental close of bottom sheet
  final double? initialSize;
  final Color? subTitleColor;
  final Widget? secondaryWidget;

  /// [onSecondaryTap] For printing out purposes only.
  final Function()? onSecondaryTap, onBackPress;

  const BottomSheetScaffold({
    super.key,
    this.isDetailMode = false,
    this.confirmOnClose = true,
    this.initialSize,
    required this.title,
    required this.body,
    this.subtitle,
    this.btnText,
    this.tooltip,
    this.subTitleColor,
    this.onSecondaryTap,
    this.secondaryWidget,
    this.onBackPress,
  });

  @override
  Widget build(BuildContext context) {
    final size = isDetailMode ? 0.92 : 0.98;
    return CustomDraggableBottomSheet(
      confirmOnClose: confirmOnClose,
      padding: EdgeInsets.only(bottom: context.bottomInsetPadding),
      initialChildSize: initialSize ?? size,
      maxChildSize: size,
      header: title is Widget
          ? title
          : (isDetailMode
                ? _buildViewDetailsHeader(context)
                : _buildHeader(context)),
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
      btnText: btnText ?? 'Close',
      onBackPress: onBackPress,
      onCancel: () => Navigator.pop(context),
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
          if (secondaryWidget != null)
            secondaryWidget!
          else if (onSecondaryTap != null)
            _secondaryWidget(context),

          IconButton(
            icon: Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      onCancel: () => Navigator.pop(context),
    );
  }

  Widget _secondaryWidget(BuildContext context) {
    return context.iconButton(
      Icons.print,
      iconColor: kWarningColor,
      bgColor: kWarningColor.toAlpha(0.1),
      tooltip: tooltip ?? 'Print out',
      onPressed: onSecondaryTap!,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    // Check if subtitle is a Widget first
    if (subtitle is Widget) {
      return subtitle as Widget;
    }

    // If subtitle is a String (or can be converted), handle it properly
    if (subtitle != null) {
      return Text(
        '$subtitle'.toTitle, // Ensure subtitle is converted to String safely
        semanticsLabel: subtitle,
        textAlign: TextAlign.center,
        style: context.textTheme.titleMedium?.copyWith(
          color: subTitleColor ?? kGrayColor,
        ),
      );
    }

    // If subtitle is null, return an empty container or handle as needed
    return SizedBox.shrink(); // Or you can return an empty Container()
  }

  Widget _buildTitle(BuildContext context) {
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
