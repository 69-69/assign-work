import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/tax_model.dart';

extension TaxableLineItemExt on List<LineItem> {
  /// Applies taxes to all taxable line items.
  ///
  /// For each `TaxableLineItem`, this computes:
  /// - `taxPercent`: total tax rate for the item
  /// - `taxAmount`: total tax amount for the item
  /// - `taxNames`: comma-separated string of applied tax names
  List<LineItem> applyTaxes(Map<String, ResolveTaxCode> taxMap) => map((item) {
    if (item is! TaxableLineItem) return item;

    final (:percent, :amount) = item.computeTax(taxMap);
    final taxNames = item.buildTaxNames(taxMap);

    return item.updateLineTax(
      taxPercent: percent,
      taxAmount: amount,
      taxNames: taxNames,
    );
  }).toList();
}

extension SumByExt<T> on Iterable<T> {
  double sumBy(double Function(T) selector) =>
      fold(0.0, (sum, e) => sum + selector(e));
}

class TotalSummary {
  final List<LineItem> lineItems;
  // Optional shipping information if applicable
  final double shippingAmount;
  final double shippingTaxAmount;
  final double shippingTaxPercent;

  TotalSummary({
    required this.lineItems,
    this.shippingAmount = 0.0,
    this.shippingTaxAmount = 0.0,
    this.shippingTaxPercent = 0.0,
  });

  /// CopyWith for immutability
  TotalSummary copyWith({
    double? shippingAmount,
    List<LineItem>? lineItems,
    double? shippingTaxAmount,
    double? shippingTaxPercent,
  }) => TotalSummary(
    lineItems: lineItems ?? this.lineItems,
    shippingAmount: shippingAmount ?? this.shippingAmount,
    shippingTaxAmount: shippingTaxAmount ?? this.shippingTaxAmount,
    shippingTaxPercent: shippingTaxPercent ?? this.shippingTaxPercent,
  );

  /// Sum of 'per line-level' net amounts (after discounts, before tax & shipping)
  double get subTotal => lineItems.sumBy((i) => i.netAmount);

  /// Total Discount amount across all lines
  double get totalDiscountAmount => lineItems.sumBy((i) => i.discountAmount);

  /// Total Tax Amount across all lines
  double get totalTaxAmount => lineItems.sumBy((i) => i.taxAmount);

  /// Total Tax Percent across all lines (for display purposes)
  double get totalTaxPercent => lineItems.sumBy((i) => i.taxPercent);

  /// Taxable amount excluding shipping (if applicable)
  double get taxableAmount => subTotal;

  /// Net total: subtotal + tax (excluding shipping)
  double get netTotal => subTotal + totalTaxAmount;

  /// Returns a new [TotalSummary] with the shipping tax calculated and stored.
  ///
  /// This method determines which tax codes from the line items apply to shipping,
  /// sums their tax rates, and computes the corresponding shipping tax amount.
  ///
  /// If [taxMap] is null, shipping amount is zero, or there are no line items,
  /// the original [TotalSummary] is returned unchanged.
  ///
  /// The returned instance will have:
  /// - [shippingTaxAmount]: the computed tax amount on shipping
  /// - [shippingTaxPercent]: the total tax rate applied to shipping (as a fraction, e.g., 0.05 for 5%)
  TotalSummary withShippingTax(Map<String, ResolveTaxCode>? taxMap) {
    if (taxMap == null || shippingAmount == 0.0 || lineItems.isEmpty) {
      return this;
    }

    // Sum the tax rates of all tax codes that apply to shipping
    final shippingRate = lineItems
        .expand((i) => i.taxCodes)
        .where((c) => taxMap[c]?.isShippingTaxed == true)
        .sumBy((c) => taxMap[c]!.rate);

    final shippingTaxPercent = shippingRate / 100;
    final shippingTaxAmount = shippingAmount * shippingTaxPercent;

    return copyWith(
      shippingTaxAmount: shippingTaxAmount,
      shippingTaxPercent: shippingTaxPercent,
    );
  }

  /// Grand total including shipping & shipping tax(if applicable), but excluding 'exchange rate'
  double get grandTotal => netTotal + shippingAmount + shippingTaxAmount;
}

/*class TotalSummary {
  final List<LineItem> lineItems;
  final double shippingAmount;
  final Map<String, ResolveTaxCode> taxMap;

  TotalSummary({
    required this.lineItems,
    this.shippingAmount = 0.0,
    required this.taxMap,
  });

  /// Sum of 'per line-level' net amounts (after discounts, before tax & shipping)
  double get subTotal =>
      lineItems.fold(0.0, (sum, item) => sum + item.netAmount);

  /// Total Discount amount across all lines
  double get totalDiscountAmount =>
      lineItems.fold(0.0, (sum, item) => sum + item.discountAmount);

  /// Total Tax Amount for all line items
  double get lineItemsTaxAmount =>
      lineItems.fold(0.0, (sum, item) => sum + item.taxAmount);

  /// Total Tax Percent for display purposes
  double get totalTaxPercent =>
      lineItems.fold(0.0, (sum, item) => sum + item.taxPercent);

  /// Shipping Tax Amount (calculated globally)
  double get shippingTaxAmount {
    // Sum rates of all tax codes that apply to shipping
    double shippingRate = lineItems
        .expand((item) => item.taxCodes)
        .map((code) => taxMap[code]?.isShippingTaxed == true ? taxMap[code]!.rate : 0.0)
        .fold(0.0, (sum, rate) => sum + rate);

    return (shippingAmount * shippingRate / 100).toCurrency;
  }

  /// Total Tax Amount including shipping tax
  double get totalTaxAmount => lineItemsTaxAmount + shippingTaxAmount;

  /// Net total: subtotal + tax (excluding shipping amount itself)
  double get netTotal => subTotal + totalTaxAmount;

  /// Grand total: net total + shipping amount
  double get grandTotal => netTotal + shippingAmount;
}

extension TaxableLineItemExt on List<LineItem> {
  /// Apply per-line taxes (without shipping)
  List<LineItem> applyTaxes(Map<String, ResolveTaxCode> taxMap) {
    return map((item) {
      if (item is! TaxableLineItem) return item;

      final (:percent, :amount) = item.computeTax(taxMap);
      final taxNames = item.buildTaxNames(taxMap);

      return item.updateLineTax(
        taxPercent: percent,
        taxAmount: amount,
        taxNames: taxNames,
      );
    }).toList();
  }
}
*/

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
