import 'package:assign_erp/core/util/enum_util.dart';

/* USAGE:
* final status = PriceListType.purchase;
* print(status.label); // Output: purchase
* */
enum TransactionType { sales, purchase }

extension TransTypeExtension on TransactionType {
  String get getName => EnumUtil<TransactionType>(this).getName;
  /// Returns a user-friendly label (e.g. "sales")
  String get getLabel => EnumUtil<TransactionType>(this).getLabel;
}


class TransactionTypeUtil {

  /// [fromString] Converts String/Label to enum value.
  static TransactionType fromString(String? value) =>
      EnumUtil.fromString<TransactionType>(TransactionType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Transaction Type' : '';
    return EnumUtil.toStringList<TransactionType>(TransactionType.values, label);
  }
}
