import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Payment terms [PayTermsDropdown]
class PayTermsDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChange;

  const PayTermsDropdown({
    super.key,
    required this.onChange,
    this.initialValue,
  });

  List<Map<String, String>> get _payTerms => paymentTerms;

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<Map<String, String>>(
      key: key,
      items: _payTerms,
      label: 'Payment terms',
      initialValue: _payTerms.firstWhereOrNull(
        (term) => term['id'] == initialValue,
      ),
      getDisplayText: (term) => term['term']!,
      onChanged: (term) => onChange(term?['id']),
      helperText: 'Specify the agreed-upon terms',
    );
  }
}
