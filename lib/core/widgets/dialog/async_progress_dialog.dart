import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:flutter/material.dart';

extension ShowProgressBar on BuildContext {
  /// Show Async ProgressDialog loading Data
  Future<void> progressBarDialog({
    Function? onSuccess,
    Function? onError,
    Widget? child,
    Future<dynamic>? request,
    Color? barrierColor,
  }) async {
    await showDialog(
      context: this,
      barrierDismissible: false,
      barrierColor: barrierColor,
      builder: (_) => AsyncProgressBarDialog(
        future: request,
        message: child ?? const Text('Please wait...'),
        onError: onError,
        onSuccess: onSuccess,
      ),
    );
  }
}

/// This code is an extension to the package flutter_progress_dialog (https://pub.dev/packages/future_progress_dialog)
class AsyncProgressBarDialog extends StatefulWidget {
  /// Dialog will be closed when [future] task is finished.
  // @required
  final Future? future;

  /// [BoxDecoration] of [AsyncProgressBarDialog].
  final BoxDecoration? decoration;

  /// opacity of [AsyncProgressBarDialog]
  final double opacity;

  /// If you want to use custom progress widget set [progress].
  final Widget? progress;

  /// If you want to use message widget set [message].
  final Widget? message;

  /// On error handler
  final Function? onError;

  /// On success handler
  final Function? onSuccess;

  /// If TRUE, show Dialog Modal widget, else only circularProgressBar [isDialog].
  final bool isDialog;

  /// If SIZE set, width & height will inherit from SIZE [size].
  final double? size;

  /// Calculate time left to complete in circularProgressBar [loadProgress].
  final double? loadProgress;

  /// The width of the line used to draw the circle [strokeWidth].
  final double? strokeWidth;

  /// The color of the line used to draw the circle [strokeColor].
  final Color? strokeColor;

  const AsyncProgressBarDialog({
    super.key,
    this.future,
    this.decoration,
    this.opacity = 1.0,
    this.progress,
    this.message,
    this.onError,
    this.onSuccess,
    this.isDialog = true,
    this.size,
    this.loadProgress,
    this.strokeWidth,
    this.strokeColor,
  });

  @override
  State<AsyncProgressBarDialog> createState() => _AsyncProgressBarDialogState();
}

class _AsyncProgressBarDialogState extends State<AsyncProgressBarDialog> {
  @override
  void initState() {
    super.initState();
    _startFuture();
  }

  void _startFuture() {
    widget.future
        ?.then(
          (value) {
            if (widget.onSuccess != null) {
              widget.onSuccess!(value);
            }

            _closeDialog(); // Close dialog on success
          },
          onError: (error) {
            if (widget.onError != null) {
              widget.onError!(error);
            }

            _closeDialog(); // Close dialog on error
          },
        )
        .catchError((error) {
          if (widget.onError != null) {
            widget.onError!(error);
          }

          _closeDialog(); // Close dialog on error
        });
  }

  void _closeDialog() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    var loadSize = widget.size ?? context.screenWidth * 0.03;
    return widget.isDialog
        ? Dialog(
            backgroundColor: kTransparentColor,
            elevation: 0,
            child: Opacity(
              opacity: widget.opacity,
              child: _buildDialogContent(),
            ),
          )
        : Center(
            child: SizedBox(
              height: loadSize,
              width: loadSize,
              child: _buildProgressIndicator(),
            ),
          );
  }

  Widget _buildDialogContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        /// Height > Width
        final isMoreTallThanWide =
            (constraints.maxHeight > constraints.maxWidth);

        final width = context.screenWidth;
        final device = switch (isMoreTallThanWide) {
          /// Its in Portrait Mode: Tall Screen Height
          true => _body(width),

          /// Its in LandScape Mode: Wide Screen Width
          _ => _body(width / 2),
        };

        return device;
      },
    );
  }

  _body(double w) {
    final boxDeco = BoxDecoration(
      color: context.scaffoldBgColor,
      borderRadius: BorderRadius.circular(10),
    );

    return Container(
      width: w,
      padding: const EdgeInsets.all(20),
      decoration: widget.decoration ?? boxDeco,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _closeBtn(),
          Center(child: widget.progress ?? _buildDefaultProgressIndicator()),
          const SizedBox(height: 20),
          widget.message ?? const Text('Loading...'),
        ],
      ),
    );
  }

  Align _closeBtn() {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        onPressed: () {
          if (mounted) {
            Navigator.pop(context);
          }
        },
        style: IconButton.styleFrom(backgroundColor: kTransparentColor),
        icon: const Icon(Icons.close, size: 16, color: Colors.black26),
      ),
    );
  }

  Widget _buildProgressIndicator() =>
      _buildDefaultProgressIndicator(value: widget.loadProgress);

  Widget _buildDefaultProgressIndicator({double? value}) {
    return CircularProgressIndicator(
      value: value,
      semanticsLabel: 'loading',
      strokeWidth: widget.strokeWidth,
      backgroundColor: widget.strokeColor ?? kDangerColor,
      // const Color(0xFFC5D3F8)
      // valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
    );
  }
}
