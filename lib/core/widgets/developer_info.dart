import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/url_launcher_util.dart';
import 'package:flutter/material.dart';

class DeveloperInfo extends StatelessWidget {
  const DeveloperInfo({
    super.key,
    this.padding,
    this.margin,
    this.fontSize,
    this.textColor,
  });

  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding, margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: padding ?? const EdgeInsets.all(5.0),
      // margin: margin ?? const EdgeInsets.only(bottom: 20),
      child: _buildBody(),
    );
  }

  _buildBody() {
    final txtColor = textColor ?? kLightBlueColor;

    return GestureDetector(
      onTap: () async => await UrlLaunchUtil.urlLauncher(
        url: 'https://assigndevelopers.com',
        inApp: false,
      ),
      child: ListTile(
        dense: true,
        title: Text.rich(
          textAlign: TextAlign.center,
          TextSpan(
            text: 'Designed By: ',
            style: TextStyle(color: kGrayBlueColor),
            children: [
              TextSpan(
                text: 'assignDevelopers Inc.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: txtColor,
                  fontSize: fontSize ?? 15,
                ),
              ),
            ],
          ),
        ),
        subtitle: Text(
          '+233 24-105-9995',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: txtColor,
            fontSize: fontSize ?? 15,
          ),
        ),
      ),
    );
  }
}
