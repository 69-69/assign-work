import 'package:flutter/material.dart';

// All of our constant stuff

const kTransparentColor = Colors.transparent;
const kPrimaryColor = Color(0xFF05318E); //0xff232b5a, 0xff041363, 0xFF673AB7
const kPrimaryLightColor = Color(0xFF4A5D8C);
const kBrightPrimaryColor = Color(0xFF1DD6EF);
const kPrimaryAccentColor = Color(0xFF3468EA);
const kWhiteColor = Color(0xFFFFFFFF);
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
const kDarkSuccessColor = Color(0xFF3AAE02);
const kDangerColor = Color(0xFFEE3737);
const kModelColor = Color(0x33000000);
const kDarkTextColor = Colors.black;
const kDefaultPadding = 20.0;
const kBorderRadius = 25.0;
/*color: Color(0x33000000),
  darkColor: Color(0x7A000000),*/
// const kTitleTextColor = Color(0xFF30384D);

extension ColorToInt on Color {
  toAlpha(double value) => withAlpha((value * 255).toInt());
}

extension DefaultColors on BuildContext {
  ThemeData get ofTheme => Theme.of(this);
  TextTheme get textTheme => ofTheme.textTheme;
  ColorScheme get colorScheme => ofTheme.colorScheme;
  Color get primaryColor => ofTheme.primaryColor;
  Color get mainPrimaryColor => colorScheme.primary;
  Color get errorColor => colorScheme.error;
  Color get onSecondaryColor => colorScheme.onSecondary;
  // switch between white/red
  Color get onErrorColor => colorScheme.onError;
  // switch between primaryLight/gray
  Color get primaryColorLight => ofTheme.primaryColorLight;
  // switch between black/primary
  Color get secondaryColor => colorScheme.secondary;
  // switch between fade white/fade gray
  Color get secondaryContainerColor => colorScheme.secondaryContainer;
  // switch between black/gray
  Color get onSecondaryContainer => colorScheme.onSecondaryContainer;
  // switch between black/primary
  Color get surfaceTintColor => colorScheme.surfaceTint;
  // switch between white/primary
  Color get onPrimaryColor => colorScheme.onPrimary;
  // switch between primary/white
  Color get onPrimaryContainer => colorScheme.onPrimaryContainer;
  // switch between dark-gray/primary
  Color get primaryContainer => colorScheme.primaryContainer;
  // switch between black/white
  Color get surfaceColor => colorScheme.surface;
  // switch between black/white
  Color get onSurfaceColor => colorScheme.onSurface;
  // switch between dark-gray/white
  Color get outlineColor => colorScheme.outline;
  // switch between black/off-white
  Color get scaffoldBgColor => ofTheme.scaffoldBackgroundColor;
  Color get bgAuthColor => scaffoldBgColor.toAlpha(0.8);
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
  Color(0xFFFFA726),
  Color(0xFFFF7043),
  Color(0xFFE64A19),
  Color(0xFFC21807),
  Color(0xFF910000),
  Color(0xFF610451),
  Color(0xFF30003D),
];
