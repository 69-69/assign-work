import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/print_util_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/purchase_order_model.dart';
import 'package:assign_erp/features/inventory_ims/data/models/print/print_po_model.dart';
import 'package:assign_erp/features/setup/data/models/supplier_model.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Print Purchase Order [PrintPO]
class PrintPurchaseOrder {
  final List<PurchaseOrder> orders;
  final Supplier supplier;

  PrintPurchaseOrder({required this.orders, required this.supplier});

  void onPrintPO() {
    // Direct-Printing: This is where we print the document
    Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async {
        // Any valid Pdf document can be returned here as a list of int
        return await _issuePrinting(format: PdfPageFormat.a4);
        // return buildPdf(format);
      },
    );
  }

  // Sample function to aggregate Invoice data
  List<PrintItem> _generatePO() {
    final invoiceItems = orders.asMap().entries.map((entry) {
      // final index = entry.key;
      final order = entry.value;

      return PrintItem(
        sku: order.supplierId,
        itemName: _toCap(order.itemName),
        unitPrice: order.unitPrice,
        quantity: order.quantity,
        discountPercent: order.discountPercent,
        validityDate: order.getDeliveryDate,
        taxPercent: order.taxPercent,
        paymentTerms: _toCap(order.payTerms),
      );
    }).toList();
    return invoiceItems;
  }

  Future<Uint8List> _issuePrinting({
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    List<PrintItem> invoiceItems = _generatePO();

    // lookup approved-by in the list of Orders (POs)
    final approvedBy = orders
        .map<String?>((p) => p.approvedBy)
        .reduce((a, b) => a ?? b);

    /// this.first or first references List<Orders>
    final po = PrintPO(
      purchaseOrderNumber: orders.first.poNumber,
      approvedBy: _toCap(
        approvedBy.isNullOrEmpty ? 'Authorized Signatory' : approvedBy!,
      ),
      items: invoiceItems,
      supplierEmail: supplier.email,
      supplierName: _toCap(supplier.name),
      supplierAddress: _toCap(supplier.address),
      supplierPhone: supplier.phone,
      contactPerson: _toCap(supplier.contactPersonName),
      // baseColor: PdfColors.teal,
      // accentColor: PdfColors.blueGrey900,
    );

    // Now you can use the `po` object as needed, e.g., to print or display it
    return await po.buildPdf(format);
  }

  String _toCap(String i) => i.toTitle;
}

/*
final order = orders.first;
    final invoiceProducts = orders.map((order) {
      // products
      return PrintItem(
        sku: order.productId,
        productName: _toCap(order.productName),
        unitPrice: order.unitPrice,
        quantity: order.quantity,
        discountPercent: order.discountPercent,
      );
    }).toList();
Pdf-Preview
    PdfPreview(
      build: (format) => _generateInvoiceFromOrders(title,
          format: PdfPageFormat.a4),
      maxPageWidth: 700,
      allowPrinting: true,
      onPrinted: _showPrintedToast,
      onShared: _showSharedToast,
    );
    */
