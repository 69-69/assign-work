import 'dart:typed_data';

import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/printout_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Print POS Sales Receipt Model [POSReceiptBuilder]
class POSReceiptBuilder {
  POSReceiptBuilder({
    required this.title,
    required this.items,
    required this.storeNumber,
    required this.receiptNumber,
    this.customerId,
  });

  final String title;
  final String storeNumber;
  final String? customerId;
  final String receiptNumber;
  final List<PrintItem> items;

  late final PrintPDFConfig _pdfColors;
  late final IssuerCompany _company;

  double get _subTotal =>
      items.map<double>((p) => p.totalNetPrice).reduce((a, b) => a + b);

  double get _tax =>
      items.map<double>((p) => p.taxPercent).reduce((a, b) => a + b);

  double get _taxAmount => (_tax / 100) * _subTotal;

  double get _grandTotalPrice => _subTotal + _taxAmount;

  String get _receiptTitle => title.toUpperAll;

  /// Generate PDF-Doc [build]
  Future<Uint8List> build(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();
    _pdfColors = await PrintPDFConfig.create();

    _company = _pdfColors.company;

    // Receipt: Add page to the PDF
    await _addReceiptPage(doc, pageFormat, _pdfColors.footerColor);

    // Return the PDF file content
    return doc.save();

    /* Load Assets Images
    ({Uint8List? logo, String bg}) img = await LoadPrintAsset.loadImg();
    _logo = img.logo;*/
  }

  /// PDF-Generator Theme [_buildTheme]
  Future<pw.PageTheme> _buildTheme(PdfPageFormat pageFormat) async {
    return await FontManager.loadTheme(
      pageFormat,
      buildBackground: (context) => pw.SizedBox.shrink(),
    );
  }

  /// Receipt: First page to the PDF [_addReceiptPage]
  _addReceiptPage(
    pw.Document doc,
    PdfPageFormat pageFormat,
    PdfColor fColor,
  ) async {
    doc.addPage(
      pw.MultiPage(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        pageTheme: await _buildTheme(pageFormat),
        header: _buildReceiptHeader,
        footer: _buildPdfFooter,
        build: (context) {
          var bColor = _pdfColors.blackColor;

          return [
            pw.Divider(color: bColor, thickness: 0.2, height: 10),
            _buildItemTable(context),
            pw.Divider(color: bColor, thickness: 0.2, height: 10),
            _buildFooter(),
          ];
        },
      ),
    );
  }

  /// PDF-Doc Header [_buildReceiptHeader]
  pw.Widget _buildReceiptHeader(pw.Context context) {
    return pw.Expanded(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _companyInfo(),
          pw.SizedBox(height: 15),
          _buildDateAndReference(),
        ],
      ),
    );
  }

  /// Company Logo [_buildCompanyLogo]
  _buildCompanyLogo() {
    return (_pdfColors.logo != null)
        ? pw.Container(
            alignment: pw.Alignment.center,
            height: 30,
            padding: pw.EdgeInsets.zero,
            margin: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Image(pw.MemoryImage(_pdfColors.logo!)),
            // _logo != null ? pw.SvgImage(svg: _logo!) : pw.PdfLogo(),
          )
        : pw.SizedBox.shrink();
  }

  /// PDF-Doc Footer [_buildPdfFooter]
  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            height: 20,
            width: 100,
            alignment: pw.Alignment.center,
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.pdf417(),
              data: '$_receiptTitle # $receiptNumber',
              drawText: false,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 10, color: _pdfColors.blackColor),
          ),
        ],
      ),
    );
  }

  /// date, Total Report & StoreNumber [_buildDateAndReference]
  _buildDateAndReference() {
    return pw.Container(
      // height: 70,
      alignment: pw.Alignment.center,
      child: pw.DefaultTextStyle(
        softWrap: true,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.normal,
          fontSize: 10,
          color: _pdfColors.blackColor,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              _receiptTitle,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3.0),
            pw.RichText(
              text: pw.TextSpan(
                text: 'Date: ',
                children: [
                  pw.TextSpan(text: PrintItem.formatDate(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 2.0),
            pw.RichText(
              text: pw.TextSpan(
                text: 'Total Items: ',
                children: [pw.TextSpan(text: items.length.toString())],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Customer Name & Address [_companyInfo]
  _companyInfo() {
    return pw.Container(
      // height: 70,
      alignment: pw.Alignment.center,
      child: pw.DefaultTextStyle(
        softWrap: true,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (_pdfColors.logo != null) ...{_buildCompanyLogo()},
            pw.Text(
              _company.name,
              softWrap: true,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 3),
            pw.Text(_company.address),
            pw.SizedBox(height: 2),
            pw.Text('Tel: ${_company.phone}'),
            pw.SizedBox(height: 2),
            pw.Text('Fax:  ${_company.fax}'),
            pw.SizedBox(height: 2),
            pw.Text('Email:  ${_company.email}'),
            pw.SizedBox(height: 4.0),
            pw.RichText(
              text: pw.TextSpan(
                text: 'Store #: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                children: [pw.TextSpan(text: storeNumber)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// PDF Receipt Content: Table-labels & contents [_buildItemTable]
  pw.Widget _buildItemTable(pw.Context context) {
    const tableHeaders = ['item', 'qty', 'net price'];

    return _buildTableLayout(tableHeaders);
  }

  pw.Table _buildTableLayout(List<String> tableHeaders) {
    return pw.TableHelper.fromTextArray(
      tableWidth: pw.TableWidth.min,
      cellPadding: const pw.EdgeInsets.all(2),
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(width: 0.2, color: PdfColors.black),
        verticalInside: pw.BorderSide.none,
      ),
      cellAlignment: pw.Alignment.center,
      // headerHeight: 20,
      cellHeight: 10,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
      },
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.normal),
      cellStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.normal),
      data: List<List<String>>.generate(
        items.length,
        (row) => List<String>.generate(
          tableHeaders.length,
          (col) => items[row].getIndex(tableHeaders[col], row),
        ),
      ),
    );
  }

  /// Total Amount Bottom-Section [_totalAmountBottom]
  pw.DefaultTextStyle _totalAmountBottom() {
    return pw.DefaultTextStyle(
      textAlign: pw.TextAlign.center,
      style: const pw.TextStyle(fontSize: 10),
      child: pw.RichText(
        text: pw.TextSpan(
          text: 'Total: ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          children: [
            pw.TextSpan(
              text: PrintItem.formatCurrency(_grandTotalPrice),
              style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  /// Tax Percent [_buildTax]
  _buildTax() {
    return pw.DefaultTextStyle(
      textAlign: pw.TextAlign.center,
      style: const pw.TextStyle(fontSize: 10),
      child: pw.RichText(
        text: pw.TextSpan(
          text: 'Tax: ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
          children: [
            pw.TextSpan(
              text: '($_tax%) $ghanaCedis${_taxAmount.toStringAsFixed(2)}',
              // pw.Text('${(tax * 100).toStringAsFixed(1)}%'),
            ),
          ],
        ),
      ),
    );
  }

  /// Sub Total [_buildSubTotal]
  _buildSubTotal() {
    return pw.DefaultTextStyle(
      textAlign: pw.TextAlign.center,
      style: const pw.TextStyle(fontSize: 10),
      child: pw.RichText(
        text: pw.TextSpan(
          text: 'Sub Total: ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
          children: [pw.TextSpan(text: PrintItem.formatCurrency(_subTotal))],
        ),
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _buildSubTotal(),
        pw.SizedBox(height: 5),
        _buildTax(),
        pw.Divider(color: _pdfColors.blackColor),
        _totalAmountBottom(),
        pw.SizedBox(height: 5),
        pw.Text(
          'Thank you for your business',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}

/*
  final IssuerCompany company;
  static const PdfColor accentColor = PdfColors.blueGrey900;
  Uint8List? _logo;*/
