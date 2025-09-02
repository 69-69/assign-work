import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/print_util_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_print/print_pos_report_model.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_sale_model.dart';
import 'package:collection/collection.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Print POS Sales Report [PrintPOSSalesReport]
class PrintPOSSalesReport {
  final List<POSSale> sales;
  final String storeNumber;

  PrintPOSSalesReport({required this.sales, required this.storeNumber});

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

  // Sample function to aggregate sales data
  List<ReportItem> _generateSalesReports() {
    // Group sales by date
    final groupedSales = groupBy(sales, (POSSale sale) => sale.createdAt);

    // Aggregate data for each group
    final reportItems = groupedSales.entries.map((entry) {
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

    return reportItems;
  }

  Future<Uint8List> _issuePrinting({
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    // Aggregate data for each group
    final salesReports = _generateSalesReports();

    final salesReport = PrintPOSReport(
      title: 'P.O.S Sales Reports',
      storeNumber: _toCap(storeNumber),
      sales: salesReports,
    );

    // Now you can use the `sales` object as needed, e.g., to print or display it
    return await salesReport.buildPdf(format);
  }

  String _toCap(String i) => i.toTitle;
}
