// ---------------------------
// 🌐 TaxAutoApplyContext: Defines where autoApply tax should be applied
// ---------------------------

import 'package:assign_erp/core/util/enum_helper.dart';

/// [TaxContext] - Defines where tax should be applied based on the context
enum TaxContext {
  all, // All contexts
  pos, // Point of Sale (POS)
  inventory, // Inventory
  requestForQuote, // Request for Quotation (RFQ)
  purchaseOrder, // Purchase Order (PO)
  saleOrder, // Sales Order
  invoice, // Invoice
  services, // Services
  documents, // Documents (Invoices, Contracts, etc.)
  customers, // Customers
  suppliers, // Suppliers/Vendors
  orders, // Sales Orders / Purchase Orders
  shipping, // Shipping & Delivery
  transfers, // Inventory Transfers (Across Locations)
  payroll, // Payroll / Employee Compensation
  operational, // Expenses (Operational)
  financial, // Financial Transactions (Interest, Dividends, Loans)
  international, // International Sales/Imports
}

extension TaxContextExtension on TaxContext {
  /// [getValue] Get the label for the specific enum value.
  String get getValue => EnumHelper<TaxContext>(this).getValue;
}

/// [TaxContextHelper] Utility class for working with TaxContext enum
class TaxContextHelper {
  /// [parseList] Parse a list of dynamic (string or enum) values into a `List<TaxContext>`
  static List<TaxContext> parseList(dynamic data) {
    if (data is! List) return [];

    return (data as List?)
            ?.map((i) => i is String ? fromString(i) : i)
            .whereType<TaxContext>()
            .toList() ??
        [];
  }

  /// [isAutoAppliedTo] Check if tax is auto-applied to a given string value
  static bool isAutoAppliedTo(String value) =>
      EnumHelper.isValid<TaxContext>(TaxContext.values, value);

  /// [fromString] Converts String/Label to enum value.
  static TaxContext fromString(String? value) =>
      EnumHelper.fromString<TaxContext>(TaxContext.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList(List<TaxContext> contexts) =>
      EnumHelper.toStringList<TaxContext>(contexts);
}
