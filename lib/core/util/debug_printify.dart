import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Prints a debug message to the console [prettyPrint].
void prettyPrint(String label, dynamic value) {
  const encoder = JsonEncoder.withIndent('  ');
  final prettyString = encoder.convert(value);
  debugPrint('📌 DEBUG-$label:\n$prettyString');
}
