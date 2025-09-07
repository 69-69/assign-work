import 'package:assign_erp/core/util/str_util.dart';

/// [TaxMode] Determines whether tax is applied on each line item (each item) or on the total (overall)
enum TaxMode {
  /// [perLineTax] Tax is applied per line item (Per item).
  perLineTax,

  /// [headerTax] Overall tax rate percentage applied to the total amount.
  headerTax,
  unknown,
}

extension TaxApplicationMode on TaxMode {
  String get getValue => getEnumName<TaxMode>(this);

  bool get isPerLineTax => this == TaxMode.perLineTax;
  bool get isHeaderTax => this == TaxMode.headerTax;
}

class TaxModeHelper {
  /// Get Tax Mode from String value [fromString].
  static TaxMode fromString(String mode) => TaxMode.values.firstWhere(
    (e) => e.getValue == mode,
    orElse: () => TaxMode.perLineTax,
  );
}
