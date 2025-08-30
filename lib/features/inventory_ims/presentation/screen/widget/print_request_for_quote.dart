import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/print_util_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/request_for_quotation_model.dart';
import 'package:assign_erp/features/inventory_ims/data/models/print/print_rfq_model.dart';
import 'package:assign_erp/features/setup/data/models/supplier_model.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Print Request For Quotation [PrintRFQ]
class PrintRequestForQuotation {
  final RequestForQuotation quote;
  final Supplier supplier;

  PrintRequestForQuotation({required this.quote, required this.supplier});

  void onPrintRFQ() {
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

  // Sample function to aggregate Request For Quotation data
  List<PrintItem> _generateRFQ() {
    final invoiceProducts = quote.lineItems.asMap().entries.map((entry) {
      // final index = entry.key;
      final item = entry.value;

      return PrintItem(
        sku: quote.supplierId,
        itemName: _toCap(item.itemName),
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        discountPercent: item.discountPercent,
        validityDate: quote.getDeliveryDate,
        taxPercent: 120,
        // taxPercent: quote.taxCodes,
        paymentTerms: 'Not Specified',
      );
    }).toList();
    return invoiceProducts;
  }

  Future<Uint8List> _issuePrinting({
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    List<PrintItem> invoiceItems = _generateRFQ();

    /// this.first or first references List<Quotes>
    final rfq = PrintRFQ2(
      rfqNumber: quote.rfqNumber,
      items: invoiceItems,
      supplierEmail: supplier.email,
      supplierName: _toCap(supplier.name),
      supplierAddress: _toCap(supplier.address),
      supplierPhone: supplier.phone,
      contactPerson: _toCap(supplier.contactPersonName),
      // baseColor: PdfColors.teal,
      // accentColor: PdfColors.blueGrey900,
    );

    // Now you can use the `rfq` object as needed, e.g., to print or display it
    return await rfq.buildPdf(format);
  }

  String _toCap(String i) => i.toTitleCase;
}
