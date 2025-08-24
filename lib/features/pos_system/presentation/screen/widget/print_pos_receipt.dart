import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/print_util_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_order_model.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_print/print_pos_receipt_model.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Print POS Sales Receipt [PrintPOSReceipt]
class PrintPOSSalesReceipt {
  final List<POSOrder> orders;
  final String storeNumber;
  final String customerId;

  PrintPOSSalesReceipt({
    required this.orders,
    required this.storeNumber,
    required this.customerId,
  });

  void onPrintPOS() {
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

  // Sample function to aggregate Sales Receipt data
  List<PrintItem> _generateReceipt() {
    final receiptProducts = orders.asMap().entries.map((entry) {
      // final index = entry.key;
      final order = entry.value;

      return PrintItem(
        itemName: _toCap(order.itemName),
        unitPrice: order.unitPrice,
        quantity: order.quantity,
        discountPercent: order.discountPercent,
        taxPercent: order.taxPercent,
        paymentTerms: _toCap(order.payMethod),
      );
    }).toList();

    return receiptProducts;
  }

  Future<Uint8List> _issuePrinting({
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    // Aggregate data for each group
    List<PrintItem> receiptItems = _generateReceipt();

    /// Replace 'SO' in the orderNumber with 'IN'
    /// EX: SO-632-20246872 as Order number, will be IN-632-20246872 as Invoice number
    final invoiceNumber = orders.first.orderNumber.convertOrderNumberTo;

    final salesReceipt = PrintPOSReceipt(
      title: 'Receipt',
      storeNumber: _toCap(storeNumber),
      customerId: _toCap(customerId),
      receiptNumber: invoiceNumber,
      products: receiptItems,
    );

    // Now you can use the `receipt` object as needed, e.g., to print or display it
    return await salesReceipt.buildPdf(format);
  }

  String _toCap(String i) => i.toTitleCase;
}
