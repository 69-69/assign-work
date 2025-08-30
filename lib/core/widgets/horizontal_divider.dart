import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:flutter/material.dart';

class HorizontalDivider extends StatelessWidget {
  const HorizontalDivider({
    super.key,
    this.width,
    this.thickness = 1,
    this.color,
    this.space,
  });

  /// [thickness] Width of the line in double [default: 1]
  final double thickness;

  /// [width] Width of the line in double [default: 1.0]
  final double? width;
  final Color? color;
  final double? space;

  @override
  Widget build(BuildContext context) {
    final cl = color ?? context.onPrimaryContainer.toAlpha(0.2);

    return width != null ? _line(cl, context) : _divider(cl);
  }

  _divider(Color color) =>
      Divider(color: color, thickness: thickness, height: space);

  _line(Color color, BuildContext context) => Container(
    color: color,
    height: thickness,
    margin: EdgeInsets.zero,
    padding: EdgeInsets.zero,
    width: context.screenWidth / (width ?? 1.0),
  );
}
