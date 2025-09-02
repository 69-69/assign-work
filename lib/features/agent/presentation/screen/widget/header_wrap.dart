import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:flutter/material.dart';

class HeaderWrap extends StatelessWidget {
  final String title;
  final Widget body;
  const HeaderWrap({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            title.toUpperAll,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kPrimaryLightColor,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis,
            ),
            textScaler: TextScaler.linear(context.textScaleFactor * 0.8),
          ),
        ),
        body,
      ],
    );
  }
}
