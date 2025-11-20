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

  /// [getValue] Get the label for the specific enum value (e.g. "officeSupplies").
  String get getValue => _getEnumName(enumValue);

  /// [getLabel] Returns a user-friendly label (e.g. "Office Supplies")
  String get getLabel => getValue.separateWord;

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
      (e) => useContains
          ? _getEnumName(e).contains(value!)
          : _getEnumName(e).toLowerAll == value.toLowerAll,
    );
  }

  /// [fromString] Convert a string value to the enum type.
  static T fromString<T extends Enum>(List<T> enumValues, String? value) {
    final label = value
        ?.combineWord; // Convert to camelCase e.g., "office supplies" -> "officeSupplies"

    return enumValues.firstWhere(
      (e) => _getEnumName(e) == label,
      orElse: () => enumValues.first, // Default to the first value if not found
    );
  }

  /// [toStringList] Convert enum list to a list of strings.
  static List<String> toStringList<T extends Enum>(
    List<T> enumValues, [
    String header = '',
  ]) {
    if (enumValues.isEmpty) return [];

    final list = enumValues.map((e) => _getEnumName(e)).toList();
    return header.isEmpty ? list : [header, ...list];
  }
}
