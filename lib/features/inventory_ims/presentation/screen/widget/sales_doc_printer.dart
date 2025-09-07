import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/print_theme_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/customer_crm/data/models/customer_model.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/order_model.dart';
import 'package:assign_erp/features/inventory_ims/data/models/print/sales_pdf_builder.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Handles printing of Sales Invoice / Proforma / Delivery Note documents [SalesDocPrinter]
class SalesDocPrinter {
  final Customer customer;
  final List<Orders> orders;

  SalesDocPrinter({required this.orders, required this.customer});

  void printDoc({required String title}) {
    // Direct-Printing: This is where we print the document
    Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async =>
          await _generatePdf(title, format: PdfPageFormat.a4),
    );
  }

  List<PrintItem> _buildLineItems() {
    return orders.asMap().entries.map((entry) {
      // final index = entry.key;
      final order = entry.value;

      return PrintItem(
        sku: order.itemId,
        itemName: _toCap(order.itemName),
        unitPrice: order.unitPrice,
        quantity: order.quantity,
        discount: order.discountPercent,
        validityDate: order.validityDate,
        deliveryAmt: order.deliveryAmount,
        taxPercent: order.taxPercent,
        paymentTerms: _toCap('${order.paymentMethod} - ${order.paymentStatus}'),
      );
    }).toList();
  }

  Future<Uint8List> _generatePdf(
    String title, {
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    List<PrintItem> lineItems = _buildLineItems();

    // Convert 'SO-XXXX' to 'IN-XXXX' (Sales Order -> Invoice)
    final invoiceNumber = orders.first.orderNumber.convertOrderNumberTo;

    final invoice = SalesDocPdfBuilder(
      title: title,
      invoiceNumber: invoiceNumber,
      products: lineItems,
      customerId: customer.isEmpty
          ? orders.first.customerId
          : customer.customerId,
      customerName: _toCap(customer.name),
      customerAddress: _toCap(customer.address),
    );

    return await invoice.build(format);
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
