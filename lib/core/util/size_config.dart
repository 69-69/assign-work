import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

/*import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
PackageInfo packageInfo = await PackageInfo.fromPlatform();*/

extension SizeConfig on BuildContext {
  /// Safely get MediaQueryData, with fallback if null
  MediaQueryData get mediaQueryData =>
      MediaQuery.maybeOf(this) ?? const MediaQueryData();
  // MediaQueryData get mediaQueryData => MediaQuery.of(this);

  double get bottomInsetPadding => mediaQueryData.viewInsets.bottom;

  /// Get Device OS: Operating-System type [deviceOSType]
  ({
    bool android,
    bool ios,
    bool isWin,
    bool isMac,
    bool isLinux,
    bool isFuchsia,
  })
  get deviceOSType => (
    android: Platform.isAndroid,
    ios: Platform.isIOS,
    isWin: Platform.isWindows,
    isMac: Platform.isMacOS,
    isLinux: Platform.isLinux,
    isFuchsia: Platform.isFuchsia,
  );

  /// Get screen size [mediaSize]
  Size get mediaSize => mediaQueryData.size;

  /// Check for darkMode Appearance [isDarkMode]
  bool get isDarkMode => mediaQueryData.platformBrightness == Brightness.dark;

  /// Get screen width [screenWidth]
  double get screenWidth => mediaSize.width;

  /// Responsive width
  ///
  /// - On mobile: returns fraction of full width
  /// - On tablet (portrait): treat like mobile
  /// - On tablet (landscape) & desktop: returns fraction of width scaled by `scaleFactor`
  double dynamicWidth(double fraction, {double scaleFactor = 1}) {
    if (isMobile || (isTablet && isPortraitMode)) {
      return screenWidth;
    }
    // tablet landscape & desktop
    return screenWidth * fraction * scaleFactor;
  }

  /// Responsive height
  double dynamicHeight(double fraction, {double scaleFactor = 1}) {
    if (isMobile || (isTablet && isPortraitMode)) {
      return screenHeight;
    }
    return screenHeight * fraction * scaleFactor;
  }

  /// Get screen height [screenHeight]
  double get screenHeight => mediaSize.height;

  /// Large screens >=1100 (desktop, TV) [isDesktop]
  bool get isDesktop => screenWidth >= 1100;

  /// Large screens >=650 <1100 (tablet on landscape mode, mini laptop) [isTablet]
  bool get isTablet => screenWidth >= 650 && screenWidth < 1100;

  /// Get screen mobile-width [isMobile]
  bool get isMobile => screenWidth <= 650;

  /// Get screen min-mobile-width [isMiniMobile]
  bool get isMiniMobile => screenWidth <= 330;

  /// Is a large screen or tablet [isLargeScreen]
  bool get isLargeScreen => screenWidth >= 650;

  /// Responsive Text-Size: Change size based on ScreenSize [textScaleFactor] 1400
  double get textScaleFactor => max(1, min((screenWidth / 1700) * 2.0, 2.0));

  /// Get Screen/Device Orientation either in Landscape or portrait mode [orientation]
  Orientation get orientation => mediaQueryData.orientation;

  /// Screen/Device Orientation is in Landscape mode (Longest Screen/Device width) [isLandscapeMode]
  bool get isLandscapeMode => orientation == Orientation.landscape;

  /// Screen/Device Orientation is in portrait mode (Shortest Screen/Device width) [isPortraitMode]
  bool get isPortraitMode => orientation == Orientation.portrait;

  /// Get magnitudes of the Screen/Device width and the height [mediaLongestSide]
  double get mediaLongestSide => mediaSize.longestSide;

  /// Get magnitudes of the Screen/Device width and the height [mediaShortestSide]
  double get mediaShortestSide => mediaSize.shortestSide;
}

/*/// Get screen width by provided size [screenWidth]
  /// USAGE: context.dynamicWidth(0.5);
  double dynamicWidth2(double fraction) =>
      isMobile || (isTablet && isPortraitMode)
      ? mediaSize.width
      : mediaSize.width * fraction;
  /// Get screen height by provided size [screenHeight]
  /// USAGE: context.dynamicHeight(0.5);
  double dynamicHeight2(double fraction) =>
      isMobile || (isTablet && isPortraitMode)
          ? mediaSize.height
          : mediaSize.height * fraction;*/
