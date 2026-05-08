import 'package:assign_erp/core/util/enum_util.dart';

/* USAGE:
* final status = PriceListType.purchase;
* print(status.label); // Output: purchase
* */
enum PriceListType { sales, purchase }

extension PriceListTypeExtension on PriceListType {
  String get getName => EnumUtil<PriceListType>(this).getName;
}


class PriceListUtil {

  /// [fromString] Converts String/Label to enum value.
  static PriceListType fromString(String? value) =>
      EnumUtil.fromString<PriceListType>(PriceListType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Price List type' : '';
    return EnumUtil.toStringList<PriceListType>(PriceListType.values, label);
  }
}
