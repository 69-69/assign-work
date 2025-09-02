import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/print_util_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/customer_crm/data/models/customer_model.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/order_model.dart';
import 'package:assign_erp/features/inventory_ims/data/models/print/print_invoice_model.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Print Order Invoice/Proforma/DeliveryNote [PrintPO]
class PrintOrderInvoice {
  final List<Orders> orders;
  final Customer customer;

  PrintOrderInvoice({required this.orders, required this.customer});

  void onPrintIn({required String title}) {
    // Direct-Printing: This is where we print the document
    Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async {
        // Any valid Pdf document can be returned here as a list of int
        return await _issuePrinting(title, format: PdfPageFormat.a4);
        // return buildPdf(format);
      },
    );
  }

  // Sample function to aggregate Invoice data
  List<PrintItem> _generateInvoice() {
    final invoiceItems = orders.asMap().entries.map((entry) {
      // final index = entry.key;
      final order = entry.value;

      return PrintItem(
        sku: order.itemId,
        itemName: _toCap(order.itemName),
        unitPrice: order.unitPrice,
        quantity: order.quantity,
        discountPercent: order.discountPercent,
        validityDate: order.validityDate,
        deliveryAmt: order.deliveryAmount,
        taxPercent: order.taxPercent,
        paymentTerms: _toCap('${order.paymentMethod} - ${order.paymentStatus}'),
      );
    }).toList();

    return invoiceItems;
  }

  Future<Uint8List> _issuePrinting(
    String title, {
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    List<PrintItem> invoiceItems = _generateInvoice();

    /// Replace 'SO' in the orderNumber with 'IN'
    /// EX: SO-632-20246872 as Order number, will be IN-632-20246872 as Invoice number
    final invoiceNumber = orders.first.orderNumber.convertOrderNumberTo;

    final invoice = PrintInvoice(
      title: title,
      invoiceNumber: invoiceNumber,
      products: invoiceItems,
      customerId: customer.isEmpty
          ? orders.first.customerId
          : customer.customerId,
      customerName: _toCap(customer.name),
      customerAddress: _toCap(customer.address),
    );

    // Now you can use the `invoice` object as needed, e.g., to print or display it
    return await invoice.buildPdf(format);
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
