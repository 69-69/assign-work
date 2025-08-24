import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class DialogHeader extends StatelessWidget {
  const DialogHeader({
    super.key,
    this.isBackButton = true,
    this.title = "",
    this.btnText = "",
    this.color,
    this.fontSize,
    this.onPress,
    this.onBackPress,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final EdgeInsets padding;
  final bool isBackButton;
  final Color? color;
  final double? fontSize;
  final dynamic btnText;

  /// [title] Title of the header row (e.g. "Your Cart" or Text("Your Cart"))
  final dynamic title;
  final Function()? onPress, onBackPress;

  @override
  Widget build(BuildContext context) {
    final customTheme = context.ofTheme;
    final customColor = customTheme.textTheme.bodySmall!.color!;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isBackButton)
            Container(
              decoration: BoxDecoration(
                color: customTheme.cardColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onBackPress ?? () => Navigator.pop(context),
                icon: Icon(
                  Icons.adaptive.arrow_back,
                  color: (color ?? customColor).toAlpha(0.5),
                ),
                constraints: const BoxConstraints(),
              ),
            ),
          (title is Widget)
              ? Flexible(child: title)
              : Text(
                  title,
                  style: customTheme.textTheme.titleLarge?.copyWith(
                    color: color ?? customColor,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // textScaler: TextScaler.linear(context.textScaleFactor),
                ),
          (btnText is Widget)
              ? btnText
              : TextButton(
                  onPressed: onPress,
                  child: Text(
                    btnText,
                    style: customTheme.textTheme.titleMedium?.copyWith(
                      color: color ?? customColor,
                      fontWeight: FontWeight.w400,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // textScaler: TextScaler.linear(context.textScaleFactor),
                  ),
                ),
        ],
      ),
    );
  }
}

class DialogTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? txtColor;
  final double? fontSize;
  final TextScaler? textScaler;

  const DialogTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.txtColor,
    this.fontSize,
    this.textScaler,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: context.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: txtColor ?? kPrimaryColor,
          fontSize: fontSize,
        ),
        textScaler: textScaler,
      ),
      subtitle: Text(
        subtitle,
        textAlign: TextAlign.center,
        style: context.textTheme.titleSmall?.copyWith(
          color: txtColor ?? kTextColor,
        ),
        textScaler: textScaler,
      ),
    );
  }
}
