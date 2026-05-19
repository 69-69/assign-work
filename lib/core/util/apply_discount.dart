import 'extensions/discount_type.dart';

double applyDiscount({
  required double basePrice,
  required DiscountType type,

  /// Main discount value
  required double value,

  /// Purchased quantity
  int quantity = 1,

  /// Buy X Get Y
  int buyQty = 0,
  int freeQty = 0,

  /// Quantity Tier
  List<QuantityTier> tiers = const [],

  /// Formula support
  String? formula,

  /// Coupon validation
  bool couponValid = false,

  /// Seasonal validation
  bool seasonalActive = false,
}) {
  switch (type) {
    /// ----------------------------------------
    /// Percentage
    /// ----------------------------------------
    case DiscountType.percentage:
      return basePrice - (basePrice * value / 100);

    /// ----------------------------------------
    /// Fixed Amount
    /// ----------------------------------------
    case DiscountType.fixedAmount:
      return (basePrice - value).clamp(0, double.infinity);

    /// ----------------------------------------
    /// Override Price
    /// ----------------------------------------
    case DiscountType.overridePrice:
      return value;

    /// ----------------------------------------
    /// Buy X Get Y
    /// ----------------------------------------
    case DiscountType.buyXGetY:
      {
        if (buyQty <= 0 || freeQty <= 0) {
          return basePrice * quantity;
        }

        final eligibleSets = quantity ~/ buyQty;

        final totalFreeQty = eligibleSets * freeQty;

        final payableQty = (quantity - totalFreeQty).clamp(0, quantity);

        return payableQty * basePrice;
      }

    /// ----------------------------------------
    /// Quantity Tier
    /// ----------------------------------------
    case DiscountType.quantityTier:
      {
        if (tiers.isEmpty) {
          return basePrice * quantity;
        }

        QuantityTier? matchedTier;

        for (final tier in tiers) {
          final maxQty = tier.maxQty ?? 999999;

          if (quantity >= tier.minQty && quantity <= maxQty) {
            matchedTier = tier;
          }
        }

        if (matchedTier == null) {
          return basePrice * quantity;
        }

        final discountedPrice =
            basePrice - (basePrice * matchedTier.discountValue / 100);

        return discountedPrice * quantity;
      }

    /// ----------------------------------------
    /// Formula Discount
    /// ----------------------------------------
    case DiscountType.formula:
      {
        /// VERY BASIC example
        /// Replace with proper parser later

        if (formula == null || formula.isEmpty) {
          return basePrice;
        }

        /// Example:
        /// formula = "0.85"
        /// Means 85% of base price

        final multiplier = double.tryParse(formula) ?? 1.0;

        return basePrice * multiplier;
      }

    /// ----------------------------------------
    /// Coupon Code
    /// ----------------------------------------
    case DiscountType.couponCode:
      {
        if (!couponValid) {
          return basePrice;
        }

        return basePrice - (basePrice * value / 100);
      }

    /// ----------------------------------------
    /// Seasonal
    /// ----------------------------------------
    case DiscountType.seasonal:
      {
        if (!seasonalActive) {
          return basePrice;
        }

        return basePrice - (basePrice * value / 100);
      }
  }
}

/*/// 10% off
applyDiscount(
  basePrice: 100,
  type: DiscountType.percentage,
  value: 10,
);

/// Buy 2 Get 1
applyDiscount(
  basePrice: 50,
  type: DiscountType.buyXGetY,
  value: 0,
  quantity: 6,
  buyQty: 2,
  freeQty: 1,
);

/// Quantity tier
applyDiscount(
  basePrice: 100,
  type: DiscountType.quantityTier,
  value: 0,
  quantity: 25,
  tiers: [
    QuantityTier(
      minQty: 10,
      maxQty: 49,
      discountValue: 5,
    ),
  ],
);*/
