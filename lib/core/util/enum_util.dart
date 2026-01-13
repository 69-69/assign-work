// ---------------------------------------------
// 🛠️ Enum Label Helper - Generic Utility
// ---------------------------------------------

import 'package:assign_erp/core/util/str_util.dart';

/// Utility function to get the name from an Enum [getEnumName]
String _getEnumName<T extends Enum>(T e) => e.name;

// Generic Enum Helper Class
class EnumHelper<T extends Enum> {
  final T enumValue;

  EnumHelper(this.enumValue);

  /// [getName] Get the specific Enum Name (e.g. "officeSupplies")
  String get getName => _getEnumName(enumValue);

  /// [getLabel] Returns a user-friendly label (e.g. "Office Supplies")
  String get getLabel => getName.separateWord;

  /// [isValid] Checks if [value] corresponds to any enum value in [enumValues].
  ///
  /// If [useContains] is true (default), performs a partial (substring) match.
  /// If false, performs an exact match.
  /// USAGE:
  /// isValid(Color.values, 're');          // true if useContains = true (default)
  /// isValid(Color.values, 'red', false);  // true only if exact match
  static bool isValid<T extends Enum>(
    List<T> enumValues,
    String? value, [
    bool useContains = true,
  ]) {
    if (enumValues.isEmpty || value.isNullOrEmpty) return false;

    return enumValues.any(
      (e) => useContains ? _getEnumName(e).contains(value!) : isEqual(e, value),
    );
  }

  /// Compare two enum values for equality.
  /// Returns true if the enum values are equal, false otherwise.
  /// USAGE: isEqual(Color.red, 'red'); // true
  static bool isEqual<T extends Enum>(T e, String? str) {
    final val = str
        ?.combineWord; // Convert to camelCase e.g., "office supplies" -> "officeSupplies"
    return _getEnumName(e).toLowerAll == val.toLowerAll;
  }

  /// [fromString] Convert a string value to the enum type.
  static T fromString<T extends Enum>(List<T> enumValues, String? value) {
    return enumValues.firstWhere(
      (e) => isEqual(e, value),
      orElse: () => enumValues.first, // Default to the first value if not found
    );
  }

  /// [toStringList] Convert enum list to a list of strings.
  static List<String> toStringList<T extends Enum>(
    List<T> enumValues, [
    String header = '',
  ]) {
    if (enumValues.isEmpty) return [];

    final list = enumValues.map((e) => _getEnumName(e).separateWord).toList();
    return header.isEmpty ? list : [header, ...list];
  }
}
