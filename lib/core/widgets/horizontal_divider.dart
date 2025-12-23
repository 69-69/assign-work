import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:flutter/material.dart';

class HorizontalDivider extends StatelessWidget {
  const HorizontalDivider({
    super.key,
    this.width,
    this.color,
    this.space,
    this.orText,
    this.thickness = 1,
    this.isORSeparator = false,
  });

  /// [orText] Text to be displayed in the OR separator
  final String? orText;

  /// [isORSeparator] Whether to display the OR separator
  final bool isORSeparator;

  /// [thickness] Width of the line in double [default: 1]
  final double thickness;

  /// [width] Width of the line in double [default: 1.0]
  final double? width;
  final Color? color;
  final double? space;

  @override
  Widget build(BuildContext context) {
    if (isORSeparator) {
      return _buildORSeparator(context);
    }
    final cl = color ?? context.onPrimaryContainer.toAlpha(0.2);

    return width != null ? _line(cl, context) : _divider(cl);
  }

  Divider _divider(Color color) =>
      Divider(color: color, thickness: thickness, height: space);

  Container _line(Color color, BuildContext context) => Container(
    color: color,
    height: thickness,
    margin: EdgeInsets.zero,
    padding: EdgeInsets.zero,
    width: context.screenWidth / (width ?? 1.0),
  );

  Widget _buildORSeparator(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: space ?? 0),
      child: Row(
        children: <Widget>[
          const Expanded(child: Divider(thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              orText ?? 'OR',
              style: context.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
          const Expanded(child: Divider(thickness: 1)),
        ],
      ),
    );
  }
}
