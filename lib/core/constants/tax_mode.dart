import 'package:assign_erp/core/util/enum_helper.dart';

/// [TaxMode] Determines whether tax is applied on each line item (each item) or on the total (overall)
enum TaxMode {
  /// [perLineTax] Tax is applied per line item (Per item).
  perLineTax,

  /// [headerTax] Overall tax rate percentage applied to the total amount.
  headerTax,
  unknown,
}

extension TaxApplicationMode on TaxMode {
  /// [getValue] Get the label for the specific enum value.
  String get getValue => EnumHelper<TaxMode>(this).getValue;

  bool get isPerLineTax => this == TaxMode.perLineTax;
  bool get isHeaderTax => this == TaxMode.headerTax;
}

class TaxModeHelper {
  /// Get Tax Mode from String value [fromString].
  static TaxMode fromString(String mode) =>
      EnumHelper.fromString<TaxMode>(TaxMode.values, mode);
}
