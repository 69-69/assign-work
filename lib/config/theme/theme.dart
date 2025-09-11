import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  /// Light theme
  static MaterialScheme lightScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(0xff232b5a), // 0xff232b5a
      // 0xff515b92
      surfaceTint: Color(0xff232b5a),
      // 0xff515b92
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffdee0ff),
      onPrimaryContainer: Color(0xff0b154b),
      secondary: Color(0xff4a5d8c),
      // 0xff5b5d72,
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffe0e1f9),
      onSecondaryContainer: Color(0xff181a2c),
      tertiary: Color(0xff77536d),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffd7f1),
      onTertiaryContainer: Color(0xff2d1228),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff410002),
      background: Color(0xfffbf8ff),
      onBackground: Color(0xff1b1b21),
      surface: Color(0xfffbf8ff),
      onSurface: Color(0xff1b1b21),
      surfaceVariant: Color(0xffe3e1ec),
      onSurfaceVariant: Color(0xff46464f),
      outline: Color(0xff767680),
      outlineVariant: Color(0xffc7c5d0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff303036),
      inverseOnSurface: Color(0xfff2eff7),
      inversePrimary: Color(0xffbac3ff),
      primaryFixed: Color(0xffdee0ff),
      onPrimaryFixed: Color(0xff0b154b),
      primaryFixedDim: Color(0xffbac3ff),
      onPrimaryFixedVariant: Color(0xff394379),
      secondaryFixed: Color(0xffe0e1f9),
      onSecondaryFixed: Color(0xff181a2c),
      secondaryFixedDim: Color(0xffc3c5dd),
      onSecondaryFixedVariant: Color(0xff434659),
      tertiaryFixed: Color(0xffffd7f1),
      onTertiaryFixed: Color(0xff2d1228),
      tertiaryFixedDim: Color(0xffe6bad7),
      onTertiaryFixedVariant: Color(0xff5d3c55),
      surfaceDim: Color(0xffdbd9e0),
      surfaceBright: Color(0xfffbf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff5f2fa),
      surfaceContainer: Color(0xffefedf4),
      surfaceContainerHigh: Color(0xffe9e7ef),
      surfaceContainerHighest: Color(0xffe4e1e9),
    );
  }

  ThemeData light() => theme(lightScheme().toColorScheme());

  /// Dark theme
  static MaterialScheme darkScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xff232b5a), // 0xff232b5a
      // 0xff515b92
      surfaceTint: Color(0xffbac3ff),
      onPrimary: Color(0xff222c61),
      primaryContainer: Color(0xff394379),
      onPrimaryContainer: Color(0xffdee0ff),
      secondary: Color(0xff4a5d8c),
      // 0xffc3c5dd
      onSecondary: Color(0xff2d2f42),
      secondaryContainer: Color(0xff434659),
      onSecondaryContainer: Color(0xFF8793B2), // 0xffe0e1f9
      tertiary: Color(0xffe6bad7),
      onTertiary: Color(0xff44263d),
      tertiaryContainer: Color(0xff5d3c55),
      onTertiaryContainer: Color(0xffffd7f1),
      error: Color(0xffba1a1a),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      background: Color(0xff121318),
      onBackground: Color(0xffe4e1e9),
      surface: Color(0xff23242c), // 0xff303036
      onSurface: Color(0xffe4e1e9),
      surfaceVariant: Color(0xff46464f),
      onSurfaceVariant: Color(0xffc7c5d0),
      outline: Color(0xff90909a),
      outlineVariant: Color(0xff46464f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe4e1e9),
      inverseOnSurface: Color(0xff303036),
      inversePrimary: Color(0xff515b92),
      primaryFixed: Color(0xffdee0ff),
      onPrimaryFixed: Color(0xff0b154b),
      primaryFixedDim: Color(0xffbac3ff),
      onPrimaryFixedVariant: Color(0xff394379),
      secondaryFixed: Color(0xffe0e1f9),
      onSecondaryFixed: Color(0xff181a2c),
      secondaryFixedDim: Color(0xffc3c5dd),
      onSecondaryFixedVariant: Color(0xff434659),
      tertiaryFixed: Color(0xffffd7f1),
      onTertiaryFixed: Color(0xff2d1228),
      tertiaryFixedDim: Color(0xffe6bad7),
      onTertiaryFixedVariant: Color(0xff5d3c55),
      surfaceDim: Color(0xff121318),
      surfaceBright: Color(0xff39393f),
      surfaceContainerLowest: Color(0xff0d0e13),
      surfaceContainerLow: Color(0xff1b1b21),
      surfaceContainer: Color(0xff1f1f25),
      surfaceContainerHigh: Color(0xff29292f),
      surfaceContainerHighest: Color(0xff34343a),
    );
  }

  ThemeData dark() => theme(darkScheme().toColorScheme());

  /// MAKE CHANGES TO COLORS HERE [theme]
  ThemeData theme(ColorScheme colorScheme) {
    var borderRadius = const BorderRadius.all(Radius.circular(7.0));
    var buttonStyle = ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: borderRadius),
      ),
    );
    var dtColor = WidgetStatePropertyAll(colorScheme.onSurface);
    var dtBtn = ButtonStyle(foregroundColor: dtColor);

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      cardColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(backgroundColor: colorScheme.primary),
      textTheme: textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      tabBarTheme: TabBarThemeData(
        // indicator: BoxDecoration(color: colorScheme.surface),
        labelColor: colorScheme.onPrimaryContainer,
        unselectedLabelColor: colorScheme.onPrimaryContainer,
        labelStyle: TextStyle(
          overflow: TextOverflow.ellipsis,
          color: colorScheme.onPrimaryContainer,
        ),
        indicatorColor: colorScheme.onPrimaryContainer,
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStatePropertyAll(colorScheme.inversePrimary),
      ),
      timePickerTheme: TimePickerThemeData(
        confirmButtonStyle: dtBtn,
        cancelButtonStyle: dtBtn,
      ),
      datePickerTheme: DatePickerThemeData(
        confirmButtonStyle: dtBtn,
        cancelButtonStyle: dtBtn,
        todayForegroundColor: WidgetStatePropertyAll(colorScheme.outline),
        dayForegroundColor: WidgetStatePropertyAll(colorScheme.outline),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        border: OutlineInputBorder(borderRadius: borderRadius),
        labelStyle: TextStyle(
          overflow: TextOverflow.ellipsis,
          color: colorScheme.onSurface,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          overflow: TextOverflow.ellipsis,
          color: colorScheme.onSurface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          labelStyle: TextStyle(
            overflow: TextOverflow.ellipsis,
            color: colorScheme.onSurface,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.error),
          ),
          border: const OutlineInputBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      textButtonTheme: TextButtonThemeData(style: buttonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
    );
  }

  List<ExtendedColor> get extendedColors => [];
}

class MaterialScheme {
  const MaterialScheme({
    required this.brightness,
    required this.primary,
    required this.surfaceTint,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.inversePrimary,
    required this.primaryFixed,
    required this.onPrimaryFixed,
    required this.primaryFixedDim,
    required this.onPrimaryFixedVariant,
    required this.secondaryFixed,
    required this.onSecondaryFixed,
    required this.secondaryFixedDim,
    required this.onSecondaryFixedVariant,
    required this.tertiaryFixed,
    required this.onTertiaryFixed,
    required this.tertiaryFixedDim,
    required this.onTertiaryFixedVariant,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
  });

  final Brightness brightness;
  final Color primary;
  final Color surfaceTint;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color inversePrimary;
  final Color primaryFixed;
  final Color onPrimaryFixed;
  final Color primaryFixedDim;
  final Color onPrimaryFixedVariant;
  final Color secondaryFixed;
  final Color onSecondaryFixed;
  final Color secondaryFixedDim;
  final Color onSecondaryFixedVariant;
  final Color tertiaryFixed;
  final Color onTertiaryFixed;
  final Color tertiaryFixedDim;
  final Color onTertiaryFixedVariant;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
}

extension MaterialSchemeUtils on MaterialScheme {
  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: shadow,
      scrim: scrim,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
    );
  }
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
