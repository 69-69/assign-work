import 'package:assign_erp/core/util/str_util.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

// Convert Flutter Colors to PdfColors
List<PdfColor> convertToPdfColors(List<Color> colors) {
  return colors
      .map((color) => PdfColor(color.r / 255, color.g / 255, color.b / 255))
      .toList();
}

// Assuming PdfColor is a class with red, green, and blue properties
Color pdfColorToColor(PdfColor pdfColor) {
  return Color.fromARGB(
    (pdfColor.alpha * 255).toInt(), // Assuming alpha is a value between 0 and 1
    (pdfColor.red * 255).toInt(),
    (pdfColor.green * 255).toInt(),
    (pdfColor.blue * 255).toInt(),
  );
}

List<Color> convertPdfColorsToColors(List<PdfColor> pdfColors) {
  return pdfColors.map(pdfColorToColor).toList();
}

// Convert a list of color strings to a list of Color objects
List<Color> stringListToColors(List<String> colorStrings) {
  return colorStrings.map((colorString) {
    return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
  }).toList();
}

// Convert a list of Color objects to a string for comparison
String colorsToString(List<Color> colors) {
  return colors
      .map((color) => color.toARGB32().toRadixString(16))
      .toList()
      .join(',');
}

// Find the index of the palette that matches the selected colors
int findPaletteIndex(List<Color> colors, List<List<Color>> colorPalettes) {
  // Convert the list of selected colors to a string
  String selectedColorsString = colorsToString(colors);

  // Find the index of the palette that matches the selected colors
  return colorPalettes.indexWhere(
    (palette) => colorsToString(palette) == selectedColorsString,
  );
}

// convert a Color object to a hexadecimal string format
extension ColorHexConversion on Color {
  /// Convert the [Color] to a hexadecimal string format.
  String toHex() {
    // Return the color in the format "#RRGGBBFF" as 8 counts
    // return '#${value.toRadixString(16).padLeft(8, '0')}';

    // Return the color in the format "#RRGGBB" as 6 counts
    return '#${toARGB32().toRadixString(16).padLeft(8, '0').padHex()}';
  }
}

extension PadColor on String {
  // Return the color in the format "#RRGGBB" as 6 counts
  String padHex() => substring(2).toUpperAll;
}

// convert a hexadecimal string to a Color Object
extension HexToColorConversion on String {
  /// Convert the [Hex] to a Color format.
  Color toColor() {
    var hexString = this;
    if (startsWith('#')) {
      // Remove the '#' character if it is present
      hexString = replaceAll('#', '');
    }

    // Parse the hex string to an integer and create a Color object
    return Color(int.parse(hexString, radix: 16) | 0xFF000000);
  }
}

/*
void _loadSelectedColors2() async {
  */
/*final settings = await _printoutService.getSettings();

  if (settings != null) {
    setState(() {
      _selectedHeaderPreviewIndex = widget.paletteColors.indexOf(
        Color(int.parse(settings.headerColor
            .split(',')
            .first)), // assuming color stored as hex
      );
      _selectedFooterPreviewIndex = widget.paletteColors.indexOf(
        Color(int.parse(settings.footerColor
            .split(',')
            .first)), // assuming color stored as hex
      );
    });
  }*/ /*

}

void _loadSelectedColors() async {
  */
/*final settings = await _printoutService.getSettings();
  if (settings != null) {
    // debugPrint('checker now');

    final headerColor = hexToColor(settings.headerColor);
    // final footerColor = hexToColor(settings.footerColor);
    debugPrint('LOADED: ${settings.headerColor} == $_selectedHeaderPreviewIndex');

    setState(() {
      // Find the index of the palette that contains the header color
      _selectedHeaderPreviewIndex = widget.paletteColors.indexOf(
          headerColor,
        );

        _selectedFooterPreviewIndex = widget.paletteColors.indexOf(
          footerColor,
        );

      // _selectedHeaderPreviewIndex = findPaletteIndex(settings.headerColor);
      _selectedHeaderPreviewIndex = widget.paletteColors.indexOf(
          Color(
            int.parse(settings.headerColor.split(',').first),
          ), // assuming color stored as hex
        );
        _selectedFooterPreviewIndex = widget.paletteColors.indexOf(
          Color(
            int.parse(settings.footerColor.split(',').first),
          ), // assuming color stored as hex
        );
    });
  }*/ /*

}*/
