import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Prints a debug message to the console [prettyPrint].
void prettyPrint(String label, dynamic value) {
  try {
    final obj = _convertToSerializable(value);
    final prettyString = const JsonEncoder.withIndent('  ').convert(obj);
    debugPrint('📌 DEBUG-$label:\n$prettyString');
  } catch (e, st) {
    debugPrint('📌 DEBUG-$label:\n$value\n⚠️ Error: $e\n$st');
  }
}

/// Recursively convert objects with toJson/toMap to Map/List for JSON encoding
dynamic _convertToSerializable(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k, _convertToSerializable(v)));
  } else if (value is List) {
    return value.map(_convertToSerializable).toList();
  } else if (value is DateTime) {
    return value.toIso8601String();
  } else if (value is num ||
      value is bool ||
      value == null ||
      value is String) {
    return value;
  } else {
    try {
      // Try to call toJson() if available
      final json = (value as dynamic).toJson();
      return _convertToSerializable(json);
    } catch (_) {
      try {
        // If toJson() fails, try toMap()
        final map = (value as dynamic).toMap();
        return _convertToSerializable(map);
      } catch (_) {
        // fallback to string for anything else
        return value.toString();
      }
    }
  }
}
