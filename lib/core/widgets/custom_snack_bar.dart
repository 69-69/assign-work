import 'dart:async';

import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:flutter/material.dart';

/// Helper class to show a snackBar using the passed context.
extension SnackBarExt on BuildContext {
  /// ---------------------------------------------
  /// 🔔 MATERIAL BANNER [showCustomMaterialBanner]
  /// ---------------------------------------------
  void showCustomMaterialBanner(String message, {Color? bgColor}) {
    /*ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showMaterialBanner()*/

    final banner = MaterialBanner(
      content: Text(message, style: const TextStyle(color: kWhiteColor)),
      leading: const Icon(Icons.info, color: kWhiteColor),
      backgroundColor: bgColor ?? kDarkSuccessColor,
      actions: [
        TextButton(
          onPressed: () =>
              ScaffoldMessenger.of(this).hideCurrentMaterialBanner(),
          child: const Text('DISMISS', style: TextStyle(color: kWhiteColor)),
        ),
      ],
    );

    ScaffoldMessenger.of(this).showMaterialBanner(banner);

    // Automatically hide the banner after 5 seconds
    Timer(kFProgressDelay, () {
      ScaffoldMessenger.of(this).hideCurrentMaterialBanner();
    });
  }

  /// -------------------------------------
  /// 🚀 OVERLAY MESSAGE [showAlertOverlay]
  /// -------------------------------------
  void showAlertOverlay(
      String message, {
        Color? bgColor,
        String? label,
        bool isTop = false,
        VoidCallback? onPressed,
        int duration = 6,
        bool showProgress = true,
        VoidCallback? onCallback,
      }) {
    final overlay = Overlay.of(this, rootOverlay: true);

    late OverlayEntry overlayEntry;
    bool isDismissed = false;

    final isError = _isErrorMessage(message);

    final animationController = AnimationController(
      vsync: Navigator.of(this),
      duration: Duration(seconds: duration),
    );

    void handleCompletion() {
      if (isError) return;
      onCallback?.call();
    }

    void removeOverlay() {
      if (isDismissed) return;
      isDismissed = true;

      overlayEntry.remove();
      animationController.dispose();
      handleCompletion();
    }

    void dismissOverlay() {
      if (isDismissed) return;
      removeOverlay();
    }

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        dismissOverlay();
      }
    });

    animationController.forward();

    final resolvedBgColor = bgColor ??
        (isError ? kDangerColor : kSuccessColor).toAlpha(0.85);

    Widget buildBody() {
      return SafeArea(
        child: Align(
          alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Material(
              color: kTransparentColor,
              child: Container(
                decoration: BoxDecoration(
                  color: resolvedBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kWhiteColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (label != null) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: onPressed ?? dismissOverlay,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black26,
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(color: kWhiteColor),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        _AnimatedCloseButton(
                          controller: animationController,
                          onPressed: dismissOverlay,
                        ),
                      ],
                    ),
                    if (showProgress) ...[
                      AnimatedBuilder(
                        animation: animationController,
                        builder: (_, __) {
                          return LinearProgressIndicator(
                            value: animationController.value,
                            backgroundColor: Colors.white24,
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(kWhiteColor),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    overlayEntry = OverlayEntry(
      builder: (_) => buildBody(),
    );

    overlay.insert(overlayEntry);
  }

  bool _isErrorMessage(String message) {
    final keywords = [
      'error',
      'required',
      'invalid',
      'incorrect',
      'failed',
      'wrong',
      'not found',
      'enter',
      'maximum allowed'
    ];

    return keywords.any(message.filterAny);
  }

  /// Material SnackBar [showAlertOverlay]
  void showCustomSnackBar(
    String message, {
    Color? bgColor,
    String? buttonLabel,
    TextAlign? textAlign,
    VoidCallback? onPressed,
  }) {
    final context = this;
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        message,
        textAlign: textAlign,
        style: TextStyle(color: kWhiteColor),
      ),
      backgroundColor: bgColor ?? kDarkSuccessColor,
      duration: const Duration(seconds: 4),
      margin: EdgeInsets.only(bottom: screenHeight - 230),
      action: SnackBarAction(
        label: buttonLabel ?? 'Close',
        textColor: kWhiteColor,
        onPressed:
            onPressed ??
            () {
              if (mounted) {
                // Perform some action when the action button is clicked
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }
              // ..didChangeDependencies();
            },
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}

class _AnimatedCloseButton extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onPressed;

  const _AnimatedCloseButton({
    required this.controller,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: SizedBox(
            height: 32,
            width: 32,
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                return CircularProgressIndicator(
                  value: controller.value,
                  strokeWidth: 2,
                  backgroundColor: Colors.white24,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(kWhiteColor),
                );
              },
            ),
          ),
        ),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close, color: kWhiteColor),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black26,
          ),
        ),
      ],
    );
  }
}

class ShowToast extends StatefulWidget {
  final String message;
  final Color? bgColor;

  const ShowToast({super.key, required this.message, this.bgColor});

  @override
  State<ShowToast> createState() => _ShowToastState();
}

class _ShowToastState extends State<ShowToast> {
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Timer(kRProgressDelay, () {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isVisible
        ? Card(
            color: widget.bgColor ?? kDarkSuccessColor,
            elevation: 5.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.message,
                style: const TextStyle(color: kWhiteColor),
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}

/*
  void showAlertOverlay2(
    String message, {
    Color? bgColor,
    String? label,
    bool isTop = false,
    VoidCallback? onPressed,
    int duration = 6,
    bool showProgress = true,
    VoidCallback? onCallback,
  }) {
    OverlayEntry? overlayEntry;
    final context = this;
    final overlay = Overlay.of(context);
    bool isDismissed = false; // Track dismissal

    // If message contains error, use red color, else use green color
    final resolvedIsError = _isErrorMessage(message);

    final animationController = AnimationController(
      vsync: Navigator.of(context),
      duration: Duration(seconds: duration),
    )..forward();

    void handleCompletion() {
      if (resolvedIsError) return; // Prevent dialog from closing if snackBar is error

      final callback = onCallback;

      if (callback != null && Navigator.of(context).canPop()) {
        callback();
      }
    }

    void handleClose() {
      if (isDismissed) return; // Prevent double removal
      isDismissed = true;
      handleCompletion();

      overlayEntry?.remove();
      overlayEntry?.dispose();
      overlayEntry = null;
    }

    void dismissOverlay() {
      if (isDismissed) return; // Prevent double dismiss
      handleClose();
      animationController.dispose();
      // handleCompletion();
    }

    assert(overlayEntry == null);

    /*final animationController = AnimationController(
      vsync: Navigator.of(context),
      duration: Duration(seconds: duration),
    )..forward();*/

    atTop(Widget child) =>
        Positioned(top: 80.0, left: 20.0, right: 20.0, child: child);
    atBottom(Widget child) =>
        Positioned(bottom: 80.0, left: 20.0, right: 20.0, child: child);

    bgColor =
        bgColor ?? (resolvedIsError ? kDangerColor : kDarkSuccessColor).toAlpha(0.6);

    buildBody(BuildContext context) => Material(
      color: kTransparentColor,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: context.copyPasteText(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: kWhiteColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (label != null) ...[
                  TextButton(
                    onPressed: onPressed ?? dismissOverlay,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black26,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(color: kWhiteColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _animatedCloseButton(animationController, handleClose),
              ],
            ),
            /*if (showProgress)
              AnimatedBuilder(
                animation: animationController,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: animationController.value,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  );
                },
              ),*/
          ],
        ),
      ),
    );

    overlayEntry = OverlayEntry(
      builder: (context) =>
          isTop ? atTop(buildBody(context)) : atBottom(buildBody(context)),
    );

    overlay.insert(overlayEntry!);

    // Remove after the duration
    // Delayed auto-dismiss
    Future.delayed(Duration(seconds: duration), () {
      if (!isDismissed) dismissOverlay();
    });
  }

  Stack _animatedCloseButton(
    AnimationController animationController,
    void Function() onPressed,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          right: 7,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: kTextColor,
            child: AnimatedBuilder(
              animation: animationController,
              builder: (context, _) {
                return CircularProgressIndicator(
                  value: animationController.value,
                  strokeWidth: 2,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(kWhiteColor),
                );
              },
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onPressed,
          label: const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Text('Close', style: TextStyle(color: kWhiteColor)),
          ),
          iconAlignment: IconAlignment.end,
          icon: Icon(Icons.close, color: kWhiteColor, size: 16),
          style: IconButton.styleFrom(
            minimumSize: Size(100, 46),
            backgroundColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
        /*
        SizedBox(
            height: 32,
            width: 32,
            color: kBgLightColor,
            child: AnimatedBuilder(
              animation: animationController,
              builder: (context, _) {
                return CircularProgressIndicator(
                  value: animationController.value,
                  strokeWidth: 2,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(kWhiteColor),
                );
              },
            ),
          ),
        ),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close, color: kWhiteColor),
          style: IconButton.styleFrom(backgroundColor: Colors.black26),
          onPressed: onPressed,
          iconSize: 20,
        ),*/
      ],
    );
  }*/
