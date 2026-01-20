import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class BlockQuote extends StatelessWidget {
  const BlockQuote({
    super.key,
    this.child,
    this.isColored = true,
    this.margin,
    this.childPadding,
    this.blockColor,
    this.blockWidth,
  });

  final Widget? child;
  final bool isColored;
  final EdgeInsets? margin;
  final EdgeInsets? childPadding;
  final Color? blockColor;
  final double? blockWidth;

  @override
  Widget build(BuildContext context) {
    final color = blockColor ?? context.onSurfaceColor;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isColored ? color.toAlpha(0.05) : null,
        border: Border(
          left: BorderSide(color: color, width: blockWidth ?? 4.0),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: childPadding ?? const EdgeInsets.all(5),
        child: child ?? SizedBox.shrink(),
      ),
    );
  }
}
