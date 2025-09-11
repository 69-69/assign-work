import 'dart:typed_data';

import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/network/data_sources/models/print_theme_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/request_for_quote_model.dart';
import 'package:assign_erp/features/inventory_ims/data/models/print/rfq_pdf_builder.dart';
import 'package:assign_erp/features/system_admin/data/models/supplier_model.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Printout for Request For Quotation [RFQPrinter]
class RFQPrinter {
  final Supplier supplier;
  final RequestForQuote quote;

  RFQPrinter({required this.quote, required this.supplier});

  Future<void> printRFQ() async {
    Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async =>
          await _generatePdf(format: PdfPageFormat.a4),
    );
  }

  List<PrintItem> _buildLineItems() {
    final currencySign = getCurrencySign(quote.currency);

    return quote.lineItems.asMap().entries.map((entry) {
      // final index = entry.key;
      final item = entry.value;

      return PrintItem(
        currencySign: currencySign,
        itemName: _toCap(item.itemName),
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        discount: item.discount,
        validityDate: quote.getDeadlineDate,
        taxAmount: item.taxAmount,
        taxNames: item.taxNames.toUpperAll,
        paymentTerms: quote.paymentTerm,
      );
    }).toList();
  }

  Future<Uint8List> _generatePdf({
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    List<PrintItem> lineItems = _buildLineItems();

    final rfq = RFQPdfBuilder(
      rfqNumber: quote.rfqNumber,
      items: lineItems,
      supplierEmail: supplier.email,
      supplierName: _toCap(supplier.name),
      supplierAddress: supplier.address.toSentence,
      supplierPhone: supplier.phone,
      contactName: _toCap(supplier.contactPersons.first.name),
      altDeliveryAddress: quote.deliveryAddress.toSentence,
      validityDate: quote.getDeadlineDate,
      deliveryDate: quote.getDeliveryDate,
      // baseColor: PdfColors.teal,
      // accentColor: PdfColors.blueGrey900,
    );

    // Now you can use the `rfq` object as needed, e.g., to print or display it
    return await rfq.build(format);
  }

  String _toCap(String i) => i.toTitle;
}
