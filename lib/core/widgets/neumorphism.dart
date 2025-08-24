import 'dart:ui';

import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

// Neumorphism is a design style that combines minimalism with three-dimensionality, and is often used in graphical user interfaces (GUIs)
// We can apply it on any  widget

extension Neumorphism on Widget {
  addNeumorphism({
    double borderRadius = 10.0,
    Offset offset = const Offset(5, 5),
    double blurRadius = 10,
    Color? bgColor,
    Color topShadowColor = kGrayColor, //Colors.white60,
    Color bottomShadowColor = const Color(0x26234395),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        boxShadow: [
          BoxShadow(
            offset: offset,
            blurRadius: blurRadius,
            color: bottomShadowColor,
          ),
          BoxShadow(
            offset: Offset(-offset.dx, -offset.dx),
            blurRadius: blurRadius,
            color: topShadowColor,
          ),
        ],
      ),
      child: this,
    );
  }

  fluidGlassMorphism({
    double blurRadius = 10,
    double blurRadius2 = 20,
    double? borderRadius,
    Color? bgColor,
    VoidCallback? onTap,
    bool fadeBg = true,
    double? width,
    double? height,
    double opacity = 0.8,
    bool addBorder = true,
  }) {
    final bColor = (bgColor ?? Colors.blue);
    final cardBgColor = fadeBg ? bColor.toAlpha(opacity) : bColor;
    final bRadius = borderRadius ?? kBorderRadius;
    return AnimatedContainer(
      width: width,
      height: height,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(bRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.white.toAlpha(0.05),
            blurRadius: blurRadius,
            offset: Offset(-6, -6),
          ),
          BoxShadow(
            color: Colors.black.toAlpha(0.2),
            blurRadius: blurRadius2,
            offset: Offset(6, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(bRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.toAlpha(0.08),
              borderRadius: BorderRadius.circular(bRadius),
              border: addBorder
                  ? Border.all(color: Colors.white.toAlpha(0.2), width: 1.5)
                  : null,
            ),
            child: this,
          ),
        ),
      ),
    );
  }
}
