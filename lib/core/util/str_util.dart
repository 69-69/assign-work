import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum UIDType { numeric, alphanumeric }

/// Utility function to get the name from an Enum [getEnumName]
String getEnumName<T extends Enum>(T e) => e.name;

/// Check if a MAP is empty or null [isNullEmpty]
extension SanitizeMap on Map? {
  bool get isNullEmpty => this == null || this!.isEmpty;
}

bool isNullOrEmpty2(Object? value) {
  if (value == null) return true;
  if (value is String && value.isEmpty) return true;
  if (value is Iterable && value.isEmpty) return true;
  if (value is Map && value.isEmpty) return true;
  return false;
}

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
}

extension ToCurrencyFormat on double {
  get toCurrency => '$this'.isNullOrEmpty ? this : toStringAsFixed(2);
}

/// get the first/last index of a list GetIndexPosition
extension GetIndexPosition on List {
  int get getFirstIndex => isEmpty ? -1 : 0;

  int get getLastIndex => isNotEmpty ? length - 1 : 0;
}

extension CaseSenitive on String {
  // USAGE: '10'.generateUID => Where 10 is the length of UID
  // Generates a random UID of specified type and length (from string)
  String generateUID({UIDType type = UIDType.alphanumeric}) {
    final int? len = int.tryParse(this);
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

  /// Create username from email address
  String get emailToUsername {
    final baseUsername = split(
      '@',
    )[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''); // Removes non-alphanumeric
    final randomSuffix = '5'.generateUID(type: UIDType.numeric);
    return '${baseUsername}_$randomSuffix';
  }

  /// Convert lowerCamelCase to two separate words
  /// Ex: 'dataType' to 'Data Type' [separateWord]
  String get separateWord {
    if (isNullOrEmpty) return this;

    var regex = RegExp(r'([a-z])([A-Z])');
    if (!regex.hasMatch(this)) return this;

    return replaceAllMapped(
      regex,
      (match) => '${match.group(1)} ${match.group(2)}',
    );
  }

  /// This will put the first letter in UpperCase, will print 'Name'
  /// print(TextTools.toUppercaseFirstLetter(text: 'name'));
  /// This will put the first letter in UpperCase, will print 'What Is Your Name'
  /// print(TextTools.toUppercaseFirstLetter(text: 'what is your name'));
  String get toUpperCaseFirst =>
      !isNullOrEmpty ? replaceFirst(this[0], this[0].toUpperCaseAll) : this;

  /// [toTitleCase] This will put the first letter in UpperCase, will print 'What Is Your Name'
  /// print(TextTools.toUppercaseFirstLetterEach('what is your name'));
  String get toTitleCase => !isNullOrEmpty
      ? split(' ')
            .map(
              (word) => word.isNullOrEmpty
                  ? word
                  : word[0].toUpperCaseAll + word.substring(1),
            ) // Handles empty words
            .join(' ')
      : this;

  /// This will put the letter in position 1 in UpperCase, will print 'nAme'
  /// print(TextTools.toUppercaseAnyLetter(text: 'name', position: 1));
  String toUppercaseAnyLetter({required int position}) =>
      replaceFirst(this[position], this[position].toUpperCaseAll);

  /// This will put the all letters in LowerCase, will print 'name'
  /// print(TextTools.toLowercaseFirstLetter(text: 'NAME'));
  String get toLowercaseAll => toLowerCase();

  /// Convert All letters to UpperCase
  String get toUpperCaseAll => toUpperCase();

  /// This will put the first letter in LowerCase, will print 'nAME'
  /// print(TextTools.toLowercaseFirstLetter(text: 'NAME'));
  String get toLowerCaseFirst => replaceFirst(this[0], this[0].toLowercaseAll);

  /// This will put the letter in position 1 in LowerCase, will print 'NaME'
  /// print(TextTools.toLowercaseAnyLetter(text: 'NAME'));
  String toLowercaseAnyLetter({required int position}) =>
      replaceFirst(this[position], this[position].toLowercaseAll);
}

/// Copy/Paste text or string to/from Clipboard
extension CopyTextToClipboard on BuildContext {
  SelectionArea copyPasteText({String? str, Widget? child}) =>
      SelectionArea(child: child ?? Text(str ?? ''));

  toClipboard(String text) async =>
      await Clipboard.setData(ClipboardData(text: text));
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
