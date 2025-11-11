import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/printout_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_order_model.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_print/pos_receipt_builder.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Print POS Sales Receipt [POSReceiptPrinter]
class POSReceiptPrinter {
  final List<POSOrder> orders;
  final String storeNumber;
  final String customerId;

  POSReceiptPrinter({
    required this.orders,
    required this.storeNumber,
    required this.customerId,
  });

  void printReceipt() {
    // Direct-Printing: This is where we print the document
    Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async =>
          await _generatePdf(format: PdfPageFormat.a4),
    );
  }

  // Sample function to aggregate Sales Receipt data
  List<PrintItem> _buildLineItems() {
    return orders.asMap().entries.map((entry) {
      // final index = entry.key;
      final order = entry.value;

      return PrintItem(
        itemName: _toCap(order.itemName),
        unitPrice: order.unitPrice,
        quantity: order.quantity,
        discount: order.discountPercent,
        taxPercent: order.taxPercent,
        paymentTerms: _toCap(order.payMethod),
      );
    }).toList();
  }

  Future<Uint8List> _generatePdf({
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    // Aggregate data for each group
    List<PrintItem> receiptItems = _buildLineItems();

    /// Replace 'SO' in the orderNumber with 'IN'
    /// EX: SO-632-20246872 as Order number, will be IN-632-20246872 as Invoice number
    final invoiceNumber = orders.first.orderNumber.convertOrderNumberTo;

    final salesReceipt = POSReceiptBuilder(
      title: 'Receipt',
      storeNumber: _toCap(storeNumber),
      customerId: _toCap(customerId),
      receiptNumber: invoiceNumber,
      items: receiptItems,
    );

    // Now you can use the `receipt` object as needed, e.g., to print or display it
    return await salesReceipt.build(format);
  }

  String _toCap(String i) => i.toTitle;
}
