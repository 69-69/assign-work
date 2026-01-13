import 'package:assign_erp/core/util/enum_util.dart';

enum StockTxnType {
  grn, // Goods Receipt (PO, Production)
  issue, // Goods Issue to Sales / Production
  transfer, // WH → WH or Bin → Bin
  adjustment, // Cycle count / correction
}

extension StockTxnTypeExtension on StockTxnType {
  /// [getName] Get the specific Enum Name
  String get getName => EnumUtil<StockTxnType>(this).getName;
}

class StockTxnTypeUtil {
  /// [fromString] Converts String/Label to enum value.
  static StockTxnType fromString(String? value) =>
      EnumUtil.fromString<StockTxnType>(StockTxnType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Stock Transaction Types' : '';
    return EnumUtil.toStringList<StockTxnType>(StockTxnType.values, label);
  }
}
