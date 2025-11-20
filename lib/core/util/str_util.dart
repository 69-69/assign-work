import 'dart:math';

import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum UIDType { numeric, alphanumeric }

/// Check if a MAP is empty or null [isNullEmpty]
extension SanitizeMap on Map? {
  bool get isNullEmpty => this == null || this!.isEmpty;
}

extension ToCurrencyFormat on double {
  /// [toCurrency] Returns the number formatted with 2 decimal places as a currency string
  get toCurrency => '$this'.isNullOrEmpty ? this : toStringAsFixed(2);

  /// [toPercent] Returns the number formatted with 1 decimal place as a percentage string
  /// If number is `15.0 or 15.00` return 15, else if number is `15.5` return 15.5
  get toPercent => '$this'.isNullOrEmpty
      ? this
      : ('$this'.trim().split('.')).last == '0'
      ? toStringAsFixed(0)
      : toStringAsFixed(1);
}

/// get the first/last index of a list GetIndexPosition
extension GetIndexPosition on List {
  int get getFirstIndex => isEmpty ? -1 : 0;

  int get getLastIndex => isNotEmpty ? length - 1 : 0;
}

/// Copy/Paste text or string to/from Clipboard
extension CopyTextToClipboard on BuildContext {
  SelectionArea copyPasteText({String? str, Widget? child}) => SelectionArea(
    child: child ?? Text(str ?? '', style: TextStyle(color: onSurfaceColor)),
  );

  toClipboard(String text) async =>
      await Clipboard.setData(ClipboardData(text: text));
}

/*bool isNullOrEmpty2(Object? value) {
  if (value == null) return true;
  if (value is String && value.isEmpty) return true;
  if (value is Iterable && value.isEmpty) return true;
  if (value is Map && value.isEmpty) return true;
  return false;
}*/

extension UniversalIsNullOrEmpty on Object? {
  bool get isNullOrEmpty {
    if (this == null || this == "null" || this == "null null") {
      return true;
    }

    if (this is String && (this as String).isEmpty) return true;
    if (this is Iterable && (this as Iterable).isEmpty) return true;
    if (this is Map && (this as Map).isEmpty) return true;

    // Fallback for custom objects that define `isEmpty`
    try {
      return (this as dynamic).isEmpty == true;
    } catch (_) {
      return false;
    }
  }

  bool get isNotNullNorEmpty => !isNullOrEmpty;
}

/// Check if s STRING is empty or null [isNullOrEmpty]
extension SanitizeExtensions on String? {
  /*bool get isNullOrEmpty =>
      this == null ||
      this!.trim().isEmpty ||
      this == "null" ||
      this == "null null";*/

  bool get isNumeric => double.tryParse(this ?? '') != null;

  // Method to check if the string is a full name
  bool get isFullName {
    if (isNullOrEmpty) {
      return false;
    }

    // Split the string by whitespace and check if there are exactly two parts
    final parts = this!.trim().split(RegExp(r'\s+'));
    return parts.length >= 2;
  }

  // Method to get the first and last names
  (String firstName, String lastName) get fullNameParts {
    if (!isFullName) {
      return ('', '');
    }

    final parts = this!.trim().split(RegExp(r'\s+'));
    return (parts.first, parts.last);
  }

  // Remove whitespace from string
  String trimWhitespace(String whiteSpace) {
    if (isNullOrEmpty) return this!;
    int startSlice = 0;
    int endSlice = this!.length;

    // Remove leading whitespace from string
    if (this!.startsWith(whiteSpace)) startSlice = 1;

    // Remove ending whitespace from string
    if (this!.endsWith(whiteSpace)) endSlice -= 1;

    return this!.substring(startSlice, endSlice);
  }

  /// Replace 'ORD' in the orderNumber with 'INV' [convertOrderNumberToInvoiceNumber]
  /// ORD: Orders
  /// EX: ORD-632-20246872 as Order number, will be INV-632-20246872 as Invoice number
  String get convertOrderNumberToInvoiceNumber {
    if (isNullOrEmpty) {
      return '';
    }

    return this!.contains('ORD') ? this!.replaceAll('ORD', 'INV') : this!;
  }

  // Function to replace matched substrings using the map
  String _replaceMatch(Match match) {
    // Define a map for pattern replacements
    // 'ORD'-> 'INV', 'POR'-> 'REC'
    final Map<String, String> replacementMap = {'ORD': 'INV', 'POR': 'REC'};

    // Retrieve the matched substring safely
    final matched = match.group(0);
    // Return the replacement value from the map or the original matched substring
    return replacementMap[matched ?? ''] ?? matched ?? '';
  }

  /// Replace 'ORD' or 'POR' in the orderNumber with 'INV' or REC [convertOrderNumberTo]
  /// ORD: Orders, POR: POS-Order
  /// INV: Invoice, REC: Receipt
  /// EX: ORD-632-20246872 as Order number,
  /// will be INV-632-20246872 as Invoice number
  /// or REC-632-20246872 as Invoice number
  /// Convert Order & POS Order Number to either Invoice-no. or purchase-Order-no
  String get convertOrderNumberTo {
    // Create a regular expression pattern to match 'ORD', 'POR'
    RegExp regex = RegExp(r'\b(ORD|POR)\b');

    return this!.replaceAllMapped(regex, _replaceMatch);
  }

  /// USAGE: '10'.generateUID => Where 10 is the length of UID
  /// Generates a random UID of specified type and length (from string)
  String generateUID({UIDType type = UIDType.alphanumeric}) {
    if (isNullOrEmpty) return '';

    final int? len = int.tryParse(this!);
    if (len == null || len <= 0) {
      throw FormatException(
        'String must be a positive integer to generate UID.',
      );
    }

    final chars = switch (type) {
      UIDType.numeric => '0123456789',
      UIDType.alphanumeric => 'abcdefghijklmnopqrstuvwxyz0123456789',
    };

    final rand = Random();
    return List.generate(len, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// TRANSFORM LETTERS TO DIFFERENT CASES ///

  /// Helper method to check for null or empty strings
  String get _isNullEmpty => isNullOrEmpty ? '' : this!;

  /// [emailToUsername] Create username from email address
  /// e.g., username@domain.com => username234
  String get emailToUsername {
    final checkedString = _isNullEmpty;

    // If the checkedString is empty, return a default or empty value
    if (checkedString.isEmpty) return '';

    final baseUsername = checkedString
        .split('@')[0]
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''); // Removes non-alphanumeric
    final randomSuffix = '5'.generateUID(type: UIDType.numeric);
    return '${baseUsername}_$randomSuffix';
  }

  /// [separateWord] Convert lowerCamelCase to two separate words
  /// e.g., 'thisIsAString' => 'this Is A String'
  String get separateWord {
    // If the string is empty, no need to process further
    if (_isNullEmpty.isEmpty) return '';

    var regex = RegExp(r'([a-z])([A-Z])');
    if (!regex.hasMatch(_isNullEmpty)) return _isNullEmpty;

    return _isNullEmpty.replaceAllMapped(
      regex,
      (m) => '${m.group(1)} ${m.group(2)}',
    );
  }

  /// [combineWord] Convert "separate words" back to lowerCamelCase
  /// e.g., 'this Is A String' => 'thisIsAString'
  String get combineWord {
    final value = _isNullEmpty; // has word or ''
    // Trim and handle empty/null strings
    if (value.isEmpty) return '';

    // If no spaces, return as-is
    if (!value.contains(' ')) return value;

    // Split by spaces
    final parts = value.split(' ');

    // Keep first word lowercase, capitalize the rest
    return parts.first.toLowerCase() +
        parts.skip(1).map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join();
  }

  /// [toUpperFirst] This will put the first letter in UpperCase
  String get toUpperFirst {
    final checkedString = _isNullEmpty;

    // If the string is empty, return it as is
    if (checkedString.isEmpty) return '';

    return checkedString.replaceFirst(
      checkedString[0],
      checkedString[0].toUpperAll,
    );
  }

  /// Converts the string to sentence case (first letter capitalized, rest lowercase)
  String get toSentence {
    final checkedString = _isNullEmpty;

    // If the string is empty, return it as is
    if (checkedString.isEmpty) return '';
    final words = checkedString.toLowerAll;

    // return words[0].toUpperAll + words.substring(1).toLowerAll;
    // Split the string into sentences by period, exclamation mark, or question mark
    List<String> sentences = words.split(RegExp(r'([.!?])'));

    // Iterate through each sentence part
    for (int i = 0; i < sentences.length; i++) {
      // Trim whitespace and ensure the first character is uppercase
      sentences[i] = sentences[i].trim();
      if (sentences[i].isNotEmpty) {
        sentences[i] = sentences[i][0].toUpperAll + sentences[i].substring(1);
      }
    }

    // Join & Return the sentences back together
    return sentences.join('. ');
  }

  /// Capitalizes the first letter of each word in the string (title case)
  String get toTitle {
    return _isNullEmpty.isEmpty
        ? ''
        : _isNullEmpty
              .split(' ')
              .map(
                (w) => w.isNullOrEmpty ? w : w[0].toUpperAll + w.substring(1),
              )
              .join(' ');
  }

  /// Converts all letters to lowercase
  String get toLowerAll =>
      _isNullEmpty.isEmpty ? '' : _isNullEmpty.toLowerCase();

  /// Converts all letters to uppercase
  String get toUpperAll =>
      _isNullEmpty.isEmpty ? '' : _isNullEmpty.toUpperCase();

  /// This will put the first letter in LowerCase
  String get toLowerFirst => _isNullEmpty.isEmpty
      ? ''
      : _isNullEmpty.replaceFirst(_isNullEmpty[0], _isNullEmpty[0].toLowerAll);

  /// This will put the letter in position 1 in UpperCase
  String toUppercaseAnyLetter({required int position}) {
    final checkedString = _isNullEmpty;

    // If the string is empty, return it as is
    if (checkedString.isEmpty) return '';

    return checkedString.replaceFirst(
      checkedString[position],
      checkedString[position].toUpperAll,
    );
  }

  /// This will put the letter in position 1 in LowerCase
  String toLowercaseAnyLetter({required int position}) {
    final checkedString = _isNullEmpty;

    // If the string is empty, return it as is
    if (checkedString.isEmpty) return '';

    return checkedString.replaceFirst(
      checkedString[position],
      checkedString[position].toLowerAll,
    );
  }
}

/* USAGE:
* final flat = flattenToStringMap({
  'data': 'Steve',
  'label': 'name',
  'account': {'date': 'jan. 12 2025', 'role': 'user'},
});
print(flat);
* Output:
* {
  'data': 'Steve',
  'label': 'name',
  'account.date': 'jan. 12 2025',
  'account.role': 'user',
}
*/
Map<String, String> createNewMap(dynamic map, [String prefix = '']) {
  final result = <String, String>{};
  if (map is Map) {
    for (var entry in map.entries) {
      final key = prefix.isEmpty
          ? entry.key.toString()
          : '$prefix.${entry.key}';
      final value = entry.value;
      if (value is Map) {
        result.addAll(createNewMap(value, key));
      } else {
        result[key] = value.toString();
      }
    }
    return result;
  }
  throw ArgumentError('Input is not a valid map: $map');
}
