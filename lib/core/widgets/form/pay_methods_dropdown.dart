import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// Payment terms [PayTermsDropdown]
class PayMethodsDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const PayMethodsDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      items: paymentMethod,
      label: 'Payment method',
      initialValue: initialValue,
      getDisplayText: (method) => method,
      onChanged: onChanged,
      helperText: 'Indicate the payment method used',
    );
  }
}
