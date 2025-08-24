import 'package:flutter/material.dart';

// All of our constant stuff

const kTransparentColor = Colors.transparent;
const kPrimaryColor = Color(0xFF232B5A); //0xff041363 - 0xff232b5a - 0xFF673AB7
const kPrimaryLightColor = Color(0xFF4A5D8C);
const kBrightPrimaryColor = Color(0xFF1DD6EF);
const kPrimaryAccentColor = Color(0xFF3468EA);
const kLightColor = Color(0xFFFFFFFF);
const kOffWhiteColor = Colors.white70;
const kGrayColor = Color(0xFFB1B3B8);
const kLightGrayColor = Color(0xFFFbF8FF);
const kGrayBlueColor = Color(0xFF8793B2);
const kTextColor = Color(0xFF757575);
const kBgLightColor = Color(0xFD393636);
const kLightBlueColor = Color(0xFFC5D3F8);
const kWarningColor = Color(0xFFFFA726);
const kDarkWarningColor = Color(0xFFFF8102);
const kOrangeColor = Color(0xFFE65100);
const kLightOrangeColor = Color(0xFFF67952);
const kGoldColor = Color(0xFFAA7706);
const kSuccessColor = Color(0xFF44CA03);
const kDangerColor = Color(0xFFEE3737);
const kDarkTextColor = Colors.black;
const kDefaultPadding = 20.0;
const kBorderRadius = 25.0;
// const kTitleTextColor = Color(0xFF30384D);

extension ColorToInt on Color {
  toAlpha(double value) => withAlpha((value * 255).toInt());
}

extension DefaultColors on BuildContext {
  ThemeData get ofTheme => Theme.of(this);
  TextTheme get textTheme => ofTheme.textTheme;
  ColorScheme get colorScheme => ofTheme.colorScheme;
  Color get primaryColor => ofTheme.primaryColor;
  Color get errorColor => colorScheme.error;
  Color get primaryColorLight => ofTheme.primaryColorLight;
  Color get secondaryColor => colorScheme.secondary;
  Color get secondaryContainerColor => colorScheme.secondaryContainer;
  Color get onSecondaryContainer => colorScheme.onSecondaryContainer;
  Color get onPrimaryColor => colorScheme.onPrimary;
  Color get onPrimaryContainer => colorScheme.onPrimaryContainer;
  Color get surfaceColor => colorScheme.surface;
  Color get surfaceTintColor => colorScheme.surfaceTint;
  Color get scaffoldBgColor => ofTheme.scaffoldBackgroundColor;
}

// list of random colors for the cards
final List<Color> randomBgColors = [
  Color(0xFFE57373),
  Color(0xFFF06292),
  Color(0xFFBA68C8),
  Color(0xFF9575CD),
  Color(0xFF7986CB),
  Color(0xFF64B5F6),
  Color(0xFF4FC3F7),
  Color(0xFF4DD0E1),
  Color(0xFF4DB6AC),
  Color(0xFF81C784),
  Color(0xFFAED581),
  Color(0xFFDCE775),
  Color(0xFFFFEE58),
  Color(0xFFFFCA28),
  kWarningColor,
  Color(0xFFFF7043),
  Color(0xFFE64A19),
  Color(0xFFC21807),
];
