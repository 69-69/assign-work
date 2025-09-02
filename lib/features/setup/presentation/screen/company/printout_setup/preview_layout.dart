import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:flutter/material.dart';

extension PrintoutLayout on BuildContext {
  Future<void> previewLayout({required String img, String layoutName = ''}) =>
      openBottomSheet(
        isExpand: false,
        child: _Layout(img: img, layoutName: layoutName),
      );
}

class _Layout extends StatelessWidget {
  final String img;
  final String layoutName;

  const _Layout({required this.img, required this.layoutName});

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      padding: EdgeInsets.only(bottom: context.bottomInsetPadding),
      sheetBgColor: kTextColor, // kCupertinoModalBarrierColor.toAlpha(0.4)),
      initialChildSize: 0.90,
      maxChildSize: 0.90,
      header: _buildHeader(context),
      child: _buildBody(context),
    );
  }

  DialogHeader _buildHeader(BuildContext context) {
    return DialogHeader(
      isBackButton: false,
      title: ListTile(
        dense: true,
        title: Text(
          'Print Layout',
          textAlign: TextAlign.center,
          semanticsLabel: 'Print Layout',
          style: context.textTheme.titleLarge?.copyWith(color: kWhiteColor),
        ),
        subtitle: Text(
          layoutName.toTitle,
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium?.copyWith(
            color: kLightBlueColor,
          ),
        ),
      ),
      color: kWhiteColor,
      btnText: 'Close',
      onPress: () => Navigator.pop(context),
    );
  }

  _buildBody(BuildContext context) {
    return Wrap(
      children: [
        Image.asset(
          img,
          fit: BoxFit.contain,
          semanticLabel: 'print $layoutName layout',
        ),
      ],
    );
  }
}
