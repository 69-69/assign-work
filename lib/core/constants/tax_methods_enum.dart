import 'package:assign_erp/core/util/str_util.dart';

/// [perLineTax] Tax is applied per line item.
/// [headerTax] Overall tax rate percentage applied to the total amount.
enum TaxMethodToApply { perLineTax, headerTax, unknown }

extension TaxApplicationMethods on TaxMethodToApply {
  String get getValue => getEnumName<TaxMethodToApply>(this);

  String get label {
    return switch (this) {
      TaxMethodToApply.perLineTax => 'perLineTax',
      TaxMethodToApply.headerTax => 'headerTax',
      _ => 'unknown',
    };
  }

  bool get isPerLineTax => this == TaxMethodToApply.perLineTax;
  bool get isHeaderTax => this == TaxMethodToApply.headerTax;
}

/// Get Tax Method from String value [getTaxMethodByString.
TaxMethodToApply getTaxMethodByString(String method) =>
    TaxMethodToApply.values.firstWhere(
      (e) => e.label == method,
      orElse: () => TaxMethodToApply.perLineTax,
    );
