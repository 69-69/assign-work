import 'package:assign_erp/core/util/enum_util.dart';

/* USAGE:
* final status = DiscountType.purchase;
* print(status.label); // Output: purchase
* */
enum DiscountType {
  percentage, // Reduce by %
  fixedAmount, // Reduce by fixed currency value
  overridePrice, // Replace selling price completely
  buyXGetY, // Buy X get Y / free quantity
  quantityTier, // Quantity slab discount
  formula, // Custom calculation logic
  couponCode,
  seasonal,
}

extension DiscountTypeExtension on DiscountType {
  String get getName => EnumUtil<DiscountType>(this).getName;
  /// Returns a user-friendly label (e.g. "coupon code")
  String get getLabel => EnumUtil<DiscountType>(this).getLabel;
}

class QuantityTier {
  final int minQty;
  final int? maxQty;
  final double discountValue;

  const QuantityTier({
    required this.minQty,
    this.maxQty,
    required this.discountValue,
  });
}

class DiscountTypeUtil {
  static bool isCoupon(String? v) =>
      EnumUtil.isEqual(DiscountType.couponCode, v);

  /// [fromString] Converts String/Label to enum value.
  static DiscountType fromString(String? value) =>
      EnumUtil.fromString<DiscountType>(DiscountType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Discount type' : '';
    return EnumUtil.toStringList<DiscountType>(DiscountType.values, label);
  }
}
