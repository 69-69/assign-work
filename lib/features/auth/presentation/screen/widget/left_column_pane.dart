import 'dart:io';

import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:flutter/material.dart';

class LeftColumnPane extends StatelessWidget {
  final String? companyLogo;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const LeftColumnPane({
    super.key,
    this.companyLogo,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return _buildLeftColumn(context);
  }

  _buildLeftColumn(BuildContext context) {
    return Card(
      elevation: 50,
      color: kLightColor.toAlpha(0.8),
      margin: context.isMobile || context.isTablet
          ? null
          : const EdgeInsets.symmetric(horizontal: 150),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildForm(context),
      ),
    );
  }

  Column _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogo(context),
        ListTile(
          dense: true,
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: kPrimaryColor,
            ),
          ),
          subtitle: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.textTheme.titleSmall?.copyWith(color: kBgLightColor),
          ),
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }

  _buildLogo(BuildContext context) {
    var wh = context.screenWidth * 0.07;

    var isComLogo =
        companyLogo != null &&
        companyLogo!.isNotEmpty &&
        File(companyLogo!).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset(
        isComLogo ? companyLogo! : appLogo2,
        fit: BoxFit.cover,
        width: wh,
        semanticLabel: 'logo',
      ),
    );
  }
}
