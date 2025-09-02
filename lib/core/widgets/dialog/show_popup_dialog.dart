import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:flutter/material.dart';

extension ShowPopupDialog on BuildContext {
  /// open dialog [openDialog]
  Future<dynamic> openDialog({
    required Widget child,
    required List<Widget> actions,
    String title = '',
  }) {
    return showDialog(
      context: this,
      // barrierColor: kTransparentColor,
      builder: (context) => AlertDialog(
        titlePadding: EdgeInsets.zero,
        // backgroundColor: kPrimaryColor,
        title: _buildTitle(title: title),
        content: child,
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 10.0),
        actions: actions,
      ),
    );
  }

  Container _buildTitle({String title = ''}) {
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      child: Text(
        title.toUpperAll,
        textAlign: TextAlign.center,
        style: ofTheme.textTheme.headlineSmall?.copyWith(
          color: kPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
        // textScaler: TextScaler.linear(textScaleFactor),
      ),
    );
  }
}
