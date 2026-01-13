// ---------------------------
// 🌐 TaxAutoApplyContext: Defines where autoApply tax should be applied
// ---------------------------

import 'package:assign_erp/core/util/enum_util.dart';

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
  /// [getName] Get the specific Enum Name (e.g. "requestForQuote")
  String get getName => EnumUtil<TaxContext>(this).getName;
}

/// [TaxContextUtil] Utility class for working with TaxContext enum
class TaxContextUtil {
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
      EnumUtil.isValid<TaxContext>(TaxContext.values, value);

  /// [fromString] Converts String/Label to enum value.
  static TaxContext fromString(String? value) =>
      EnumUtil.fromString<TaxContext>(TaxContext.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([List<TaxContext>? contexts]) =>
      EnumUtil.toStringList<TaxContext>(contexts ?? TaxContext.values);
}
