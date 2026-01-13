import 'package:assign_erp/core/util/str_util.dart';

/// Calculate Additional/Extra Cost [CalculateExtras]
class CalculateExtras {
  /// function to round a double to two decimal places [roundToTwoDecimalPlaces]
  static double roundToTwoDecimalPlaces(double v) => (v * 100).round() / 100;

  /// Calculate Sub-Total by Quantity & Unit Price [subTotal]
  static void subTotal({
    required String qty,
    required String unitPrice,
    required Function(String) onChanged,
  }) {
    if (unitPrice.isEmpty) {
      return;
    }

    double totalPrice = double.parse(unitPrice) * (int.tryParse(qty) ?? 0.0);

    onChanged(totalPrice.toStringAsFixed(2));
  }

  /// Calculate Discount-Amount by Total-Price & Discount-Percentile [discountAmount]
  static void discountAmount({
    required String subTotal,
    required String discountPercent,
    required Function(double) onChanged,
  }) {
    if (subTotal.isEmpty) return;

    double discountAmt =
        (discountPercent.asDouble / 100) * double.parse(subTotal);

    var roundToTwo = roundToTwoDecimalPlaces(discountAmt);
    onChanged(roundToTwo);
  }

  /// Calculate Tax-Amount by Total-Price & Tax-Percentile [taxAmount]
  static void taxAmount({
    required String subTotal,
    required String taxPercent,
    String deliveryAmt = '',
    double discountAmt = 0.0,
    required Function(double) onChanged,
  }) {
    if (subTotal.isEmpty) return;

    /// NetPrice: After discountAmt is deducted & other charges are added from 'subTotal'
    double netPrice = (subTotal.asDouble - discountAmt) + deliveryAmt.asDouble;

    double taxAmount = (taxPercent.asDouble / 100) * netPrice;

    var roundToTwo = roundToTwoDecimalPlaces(taxAmount);
    onChanged(roundToTwo);
  }

  /// Calculate Total-Amount by All [totalAmount]
  static void totalAmount({
    required String subTotal,
    String deliveryAmt = '',
    double taxAmount = 0.0,
    double discountAmount = 0.0,
    required Function(double) onChanged,
  }) {
    if (subTotal.isEmpty) return;

    /// NetPrice: After discountAmt is deducted & other charges are added from 'subTotal'
    double netPrice = double.parse(subTotal) - discountAmount;

    double plusDelivery = netPrice + deliveryAmt.asDouble;
    double totalAmount = plusDelivery + taxAmount;

    /*double totalAmount2 =
    (((double.tryParse(deliveryAmt) ?? 0.0) + double.parse(subTotal) + taxAmount) - discountAmount)
        .roundToDouble();*/

    var roundToTwo = roundToTwoDecimalPlaces(totalAmount);
    onChanged(roundToTwo);
  }
}
