// ---------------------------
// 🌐 TaxAutoApplyContext: Defines where autoApply tax should be applied
// ---------------------------

import 'package:assign_erp/core/util/str_util.dart';

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
  String get getValue => getEnumName<TaxContext>(this);
}

/// [TaxContextHelper] Utility class for working with TaxContext enum
class TaxContextHelper {
  /// [fromString] Convert string to TaxContext enum
  static TaxContext fromString(String value) {
    return TaxContext.values.firstWhere(
      (e) => e.getValue == value,
      orElse: () => TaxContext.all,
    );
  }

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
      TaxContext.values.any((e) => e.getValue.contains(value));

  /// [toStringList] Convert a list of TaxContext enums to a list of strings (e.g., for Firestore)
  static List<String> toStringList(List<TaxContext> contexts) =>
      contexts.map((e) => e.getValue).toList();
}
