import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/ref_master_cache.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/ref_master_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Currency Selection Dropdown [CurrencyDropdown]
class CurrencyDropdown extends StatelessWidget {
  final String? label;
  final String? initialCurrency;
  final void Function(({String code, String symbol, String country})? s)
  onChanged;

  const CurrencyDropdown({
    super.key,
    this.label,
    this.initialCurrency,
    required this.onChanged,
  });

  RefMaster? get _cache => RefMasterCache().getById(currencyMasterCacheId);

  get _excludedCurrencies => (_cache?.references ?? const <String>[]);

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<({String code, String symbol, String country})>(
      // isMenu: true,
      key: key,
      items: currencyType.where((c) => !_excludedCurrencies.contains(c.code)).toList(),
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
