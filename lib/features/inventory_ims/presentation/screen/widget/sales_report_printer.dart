import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/print_theme_config.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/inventory_ims/data/models/print/sr_pdf_builder.dart';
import 'package:assign_erp/features/inventory_ims/data/models/sale_model.dart';
import 'package:collection/collection.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Print Sale Report [PrintReport]
class SalesReportPrinter {
  final List<Sale> sales;
  final String createdBy;
  final String storeNumber;

  SalesReportPrinter({
    required this.createdBy,
    required this.sales,
    required this.storeNumber,
  });

  void printReport({required String title}) {
    // Direct-Printing: This is where we print the document
    Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async =>
          await _generatePdf(title, format: PdfPageFormat.a4),
    );
  }

  List<ReportItem> _buildReports(List<Sale> sales) {
    // Group sales by date
    final groupedSales = groupBy(sales, (Sale sale) => sale.createdAt);

    // Aggregate data for each group
    return groupedSales.entries.map((entry) {
      final salesDate = entry.key;
      final salesList = entry.value;

      double totalSales = 0.0;
      int totalOrders = 0;
      int totalItemsSold = 0;
      double totalDiscounts = 0.0;
      double totalTaxes = 0.0;

      for (var sale in salesList) {
        // sale.unitPrice * sale.quantity;
        totalSales += sale.totalAmount;
        totalOrders += 1;
        totalItemsSold += sale.quantity;
        // (sale.unitPrice * sale.quantity) * (sale.discountPercent / 100);
        totalDiscounts += sale.discountAmount;
        // (sale.unitPrice * sale.quantity) * (sale.taxPercent / 100);
        totalTaxes += sale.taxAmount;
      }

      return ReportItem(
        salesDate: salesDate.dateOnly,
        totalSales: totalSales,
        totalOrders: totalOrders,
        totalItemsSold: totalItemsSold,
        totalDiscounts: totalDiscounts,
        totalTaxes: totalTaxes,
      );
    }).toList();
  }

  Future<Uint8List> _generatePdf(
    String title, {
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    // Aggregate data for each group
    final salesReports = _buildReports(sales);

    final invoice = SRPdfBuilder(
      title: title,
      storeNumber: _toCap(storeNumber),
      createdBy: _toCap(createdBy),
      sales: salesReports,
    );

    // Now you can use the `sales` object as needed, e.g., to print or display it
    return await invoice.build(format);
  }

  String _toCap(String i) => i.toTitle;
}
