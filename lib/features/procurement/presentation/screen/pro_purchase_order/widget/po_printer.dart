import 'dart:typed_data';

import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/printout_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/inventory_ims/data/models/print/po_pdf_builder.dart';
import 'package:assign_erp/features/procurement/data/model/pro_purchase_order_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Print Purchase Order [POPrinter]
class POPrinter {
  final Supplier supplier;
  final ProPurchaseOrder order;

  POPrinter({required this.order, required this.supplier});

  Future<void> printPO() async {
    // Direct-Printing: This is where we print the document
    Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async =>
          await _generatePdf(format: PdfPageFormat.a4),
    );
  }

  // Sample function to aggregate Invoice data
  List<PrintItem> _buildLineItems() {
    final currencySign = getCurrencySign(order.currency);
    return order.lineItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return PrintItem(
        sku: '${index + 1}',
        currencySign: currencySign,
        itemName: item.description,
        quantity: item.quantity,
        discount: item.discount,
        unitPrice: item.unitPrice,
        taxAmount: item.taxAmount,
        paymentTerms: order.paymentTerm,
        taxNames: item.taxNames.toUpperAll,
        validityDate: order.getDeliveryDate,
      );
    }).toList();
  }

  Future<Uint8List> _generatePdf({
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    List<PrintItem> lineItems = _buildLineItems();

    // lookup approved-by in the list of Orders (POs)
    final approvedBy = order.history
        .map<String?>(
          (p) => AuditActionHelper.isApproved(p.getAction) ? p.actionBy : null,
        )
        .reduce((a, b) => a ?? b);

    /// this.first or first references List<Orders>
    final po = POPdfBuilder(
      poNumber: order.poNumber,
      approvedBy: _toCap(
        approvedBy.isNullOrEmpty ? 'Authorized Signatory' : approvedBy!,
      ),
      items: lineItems,
      supplierEmail: supplier.email,
      supplierName: _toCap(supplier.name),
      supplierAddress: _toCap(supplier.address),
      supplierPhone: supplier.phone,
      contactName: _toCap(supplier.contactPersons.first.name),
      // baseColor: PdfColors.teal,
      // accentColor: PdfColors.blueGrey900,
    );

    // Now you can use the `po` object as needed, e.g., to print or display it
    return await po.build(format);
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
