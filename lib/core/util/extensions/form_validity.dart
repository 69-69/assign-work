import 'package:flutter/material.dart';

extension FormValidityExt on GlobalKey<FormState> {
  void updateValidity({
    required bool currentValidity,
    required void Function(bool) onChanged,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final valid = currentState?.validate() ?? false;

      if (valid != currentValidity) {
        onChanged(valid);
      }
    });
  }
}
