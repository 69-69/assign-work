import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';

class TotalSummary {
  final List<LineItem> lineItems;
  final double shippingAmount;

  TotalSummary({required this.lineItems, this.shippingAmount = 0.0});

  bool get _isShippingTaxable => lineItems.first.isShippingTaxed;

  /// Sum of 'per line-level' net amounts (after discounts, before tax & shipping)
  double get subTotal =>
      lineItems.fold(0.0, (sum, item) => sum + item.netAmount);

  /// Total Discount amount across all lines
  double get totalDiscountAmount =>
      lineItems.fold(0.0, (sum, item) => sum + item.discountAmount);

  /// Total Tax Amount across all lines
  double get totalTaxAmount =>
      lineItems.fold(0.0, (sum, item) => sum + item.taxAmount);

  /// Total Tax Percent across all lines (for display purposes)
  double get totalTaxPercent =>
      lineItems.fold(0.0, (sum, item) => sum + item.taxPercent);

  /// Taxable amount including shipping if shipping is taxable
  double get taxableAmount =>
      subTotal + (_isShippingTaxable ? shippingAmount : 0.0);

  /// Net total: subtotal + tax (excluding shipping)
  double get netTotal => subTotal + totalTaxAmount;

  /// Grand total: net total + shipping excluding 'exchange rate'
  double get grandTotal =>
      netTotal + (_isShippingTaxable ? 0.0 : shippingAmount);

  /// Taxable Amount + shippingAmount excluding 'exchange rate'
  // double get grandTotal => taxableAmount + totalTaxAmount;
}

/*/// Sum of 'per line-level' net amounts (after discounts, before tax & shipping)
  double get subTotal =>
      lineItems.fold(0.0, (sum, item) => sum + item.netAmount);

  /// Taxable amount (includes shipping if shipping is taxable)
  double get taxableAmount => subTotal + shippingAmount;

  /// Total Discount amount: Subtract from subtotal
  double get totalDiscountAmount =>
      lineItems.fold(0.0, (sum, item) => sum + item.discountAmount);

  /// Total Tax Percent (Sum of Line-Level Tax percentage)
  double get totalTaxPercent =>
      lineItems.fold(0.0, (sum, item) => sum + item.taxPercent);

  /// Total Tax Amount: Add tax based on the subtotal (before discount)
  double get totalTaxAmount =>
      lineItems.fold(0.0, (sum, item) => sum + item.taxAmount);

  /// Document-level net total (after discounts, including tax)
  double get netTotal => subTotal + totalTaxPercent;

  /// Taxable Amount + shippingAmount excluding 'exchange rate'
  double get grandTotal => taxableAmount + totalTaxAmount;*/
