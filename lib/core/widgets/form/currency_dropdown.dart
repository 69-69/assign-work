import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Currency Selection Dropdown [CurrencyDropdown]
class CurrencyDropdown extends StatelessWidget {
  final String? label;
  final String? initialCurrency;
  final void Function(({String code, String symbol, String country})? s) onChanged;

  const CurrencyDropdown({
    super.key,
    this.label,
    this.initialCurrency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<({String code, String symbol, String country})>(
      key: key,
      // isMenu: true,
      items: currencyType,
      label: label ?? 'Select currency',
      initialValue: currencyType.firstWhereOrNull(
        (e) => e.code == initialCurrency,
      ),
      getDisplayText: (currency) => '${currency.code} (${currency.symbol})',
      onChanged: onChanged,
    );

    /*return StaticDropdown<Map<String, String>>(
      key: key,
      items: currencyType,
      label: 'Select currency',
      initialValue: currencyType.firstWhereOrNull(
        (c) => c['code'] == initialCurrency,
      ),
      getDisplayText: (currency) =>
          '${currency['code']} (${currency['symbol']})',
      onChanged: (v) => onCurrencyChanged(v?['code']),
    );*/
  }
}
