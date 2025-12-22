import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Prints a debug message to the console [prettyPrint].
void prettyPrint(String label, dynamic value) {
  try {
    const encoder = JsonEncoder.withIndent('  ');
    final obj = value is DateTime ? value.toIso8601String() : value;
    final prettyString = encoder.convert(obj);
    debugPrint('📌 DEBUG-$label:\n$prettyString');
  } catch (e) {
    debugPrint('📌 DEBUG-$label:\n$value');
  }
}
