import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

extension PromptUserFor on BuildContext {
  /// Prompt User to confirm Pending Action [confirmAction]
  Future<T> confirmAction<T>(
    Widget child, {
    String title = 'Confirm',
    String onAcceptLabel = "Yes",
    String onRejectLabel = "No",
    String? anyAction,
    Color? barrierColor,
    bool barrierDismissible = true,
  }) async {
    var result = await showDialog(
      context: this,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: (context) => _buildBody(
        context,
        title,
        child,
        onAcceptLabel,
        onRejectLabel,
        anyAction: anyAction,
      ),
    );
    // result ??= false as T;
    return result as T;
  }

  /// Prompt User to agree to Pending Action [confirmDone]
  Future<bool> confirmDone(
    Widget child, {
    String title = 'Confirm',
    String onDone = "OK",
    bool barrierDismissible = true,
  }) async {
    final result = await showCupertinoDialog<bool>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: (context) => _buildBody(context, title, child, onDone, ''),
    );
    return result ?? false;
  }

  CupertinoAlertDialog _buildBody(
    BuildContext context,
    String title,
    Widget child,
    String onAccept,
    String onReject, {
    String? anyAction,
  }) {
    var cupertinoAlertDialog = CupertinoAlertDialog(
      title: Padding(padding: const EdgeInsets.all(8.0), child: Text(title)),
      content: child,
      actions: [
        _cupertinoDialogAction(context, label: onAccept),
        if (onReject.isNotEmpty) ...{
          _cupertinoDialogAction(context, label: onReject, status: false),
        },
        if (anyAction != null) ...{
          _cupertinoDialogAction(context, label: anyAction, status: null),
        },
      ],
    );
    return cupertinoAlertDialog;
  }

  CupertinoDialogAction _cupertinoDialogAction(
    BuildContext context, {
    required String label,
    bool? status = true,
  }) {
    return CupertinoDialogAction(
      key: ValueKey(label),
      isDefaultAction: true,
      onPressed: () async => Navigator.pop(context, status),
      child: Text(label, style: TextStyle(color: context.onSecondaryContainer)),
    );
  }
}
