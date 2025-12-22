import 'dart:async';

import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:flutter/material.dart';

/// Helper class to show a snackBar using the passed context.
/*class ScaffoldSnackBar {
  // ignore: public_member_api_docs
  ScaffoldSnackBar(this._context);

  /// The scaffold of current context.
  factory ScaffoldSnackBar.of(BuildContext context) {
    return ScaffoldSnackBar(context);
  }

  final BuildContext _context;

  /// Helper method to show a SnackBar.
  void show(String message) {
    ScaffoldMessenger.of(_context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}*/

extension ScaffoldSnackBar on BuildContext {
  /// Material Banner [showCustomMaterialBanner]
  void showCustomMaterialBanner(String message) {
    /*ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showMaterialBanner()*/

    final banner = MaterialBanner(
      content: Text(message, style: const TextStyle(color: kWhiteColor)),
      leading: const Icon(Icons.info, color: kWhiteColor),
      backgroundColor: kDarkSuccessColor,
      actions: [
        TextButton(
          onPressed: () =>
              ScaffoldMessenger.of(this).hideCurrentMaterialBanner(),
          child: const Text('DISMISS', style: TextStyle(color: kWhiteColor)),
        ),
      ],
    );

    ScaffoldMessenger.of(this).showMaterialBanner(banner);

    // Automatically hide the banner after 3 seconds
    Timer(kRProgressDelay, () {
      ScaffoldMessenger.of(this).hideCurrentMaterialBanner();
    });
  }

  /// Show alert overlay with optional progress indicator
  void showAlertOverlay(
    String message, {
    Color? bgColor,
    String? label,
    bool isTop = false,
    VoidCallback? onPressed,
    int duration = 6,
    bool showProgress = true,
    void Function()? popContext,
  }) {
    OverlayEntry? overlayEntry;
    final overlay = Overlay.of(this);
    bool isDismissed = false; // Track dismissal

    void handleClose() {
      if (isDismissed) return; // Prevent double removal
      isDismissed = true;

      overlayEntry?.remove();
      overlayEntry?.dispose();
      overlayEntry = null;
    }

    void dismissOverlay() {
      if (isDismissed) return; // Prevent double dismiss
      handleClose();
      if (popContext != null && Navigator.of(this).canPop()) {
        popContext();
      }
    }

    assert(overlayEntry == null);

    final animationController = AnimationController(
      vsync: Navigator.of(this),
      duration: Duration(seconds: duration),
    )..forward();

    atTop(Widget child) =>
        Positioned(top: 80.0, left: 20.0, right: 20.0, child: child);
    atBottom(Widget child) =>
        Positioned(bottom: 80.0, left: 20.0, right: 20.0, child: child);

    buildBody(BuildContext context) => Material(
      color: kTransparentColor,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor ?? kDarkSuccessColor,
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
                      style: const TextStyle(color: kWhiteColor),
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
  }

  /// Material SnackBar [showAlertOverlay]
  void showCustomSnackBar(
    String message, {
    Color? bgColor,
    String? buttonLabel,
    TextAlign? textAlign,
    VoidCallback? onPressed,
  }) {
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
                ScaffoldMessenger.of(this).hideCurrentSnackBar();
              }
              // ..didChangeDependencies();
            },
      ),
    );

    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
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
    int? duration,
  }) {
    OverlayEntry? overlayEntry;
    final overlay = Overlay.of(this);

    // Remove the OverlayEntry.
    void removeHighlightOverlay() {
      overlayEntry?.remove();
      overlayEntry?.dispose();
      overlayEntry = null;
    }

    // Remove the existing OverlayEntry.
    removeHighlightOverlay();

    assert(overlayEntry == null);

    atTop(Widget child) =>
        Positioned(top: 80.0, left: 20.0, right: 20.0, child: child);

    atBottom(Widget child) =>
        Positioned(bottom: 80.0, left: 20.0, right: 20.0, child: child);

    buildBody(BuildContext context) => Material(
      color: kTransparentColor,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor ?? Colors.green,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        padding: const EdgeInsets.all(6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: context.copyPasteText(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (label != null)
              TextButton(
                onPressed: onPressed ?? removeHighlightOverlay,
                style: TextButton.styleFrom(backgroundColor: Colors.black12),
                child: Text(label, style: const TextStyle(color: Colors.white)),
              ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: removeHighlightOverlay,
            ),
          ],
        ),
      ),
    );

    overlayEntry = OverlayEntry(
      builder: (context) =>
          isTop ? atTop(buildBody(context)) : atBottom(buildBody(context)),
    );

    overlay.insert(overlayEntry!);

    // Remove the overlay after a delay
    Future.delayed(
      Duration(seconds: duration ?? 4),
      () => overlayEntry?.remove(),
    );
  }*/
