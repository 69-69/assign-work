import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/printout_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Print Inventory Sales Report [SRPdfBuilder]
class SRPdfBuilder {
  SRPdfBuilder({
    required this.title,
    required this.sales,
    required this.createdBy,
    required this.storeNumber,
    // required this.baseColor,
    // required this.accentColor,
  });

  final String title;
  final String createdBy;
  final String storeNumber;
  final List<ReportItem> sales;

  late final PrintPDFConfig _pdfColors;
  late final IssuerCompany _company;

  String get _reportTitle => title.toUpperAll;

  /// Generate PDF-Doc [build]
  Future<Uint8List> build(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();
    _pdfColors = await PrintPDFConfig.create();
    _company = _pdfColors.company;

    // Report or Receipt: Add page to the PDF
    await _addSRPage(doc, pageFormat, _pdfColors.footerColor);

    return doc.save();

    /*Load Assets Images
    ({Uint8List logo, String bg}) img = await LoadPrintAsset.loadImg();
    _logo = img.logo;
    _bgShape = img.bg;*/
  }

  /// PDF-Generator Theme [_buildTheme]
  Future<pw.PageTheme> _buildTheme(PdfPageFormat pageFormat) async {
    return await FontManager.loadTheme(
      pageFormat,
      buildBackground: (context) =>
          _pdfColors.isDenseLayout ? _buildFooterBg() : pw.SizedBox.shrink(),
    );
  }

  /// Report: First page to the PDF [_buildReport]
  _addSRPage(pw.Document doc, PdfPageFormat pageFormat, PdfColor fColor) async {
    doc.addPage(
      pw.MultiPage(
        pageTheme: await _buildTheme(pageFormat),
        header: _buildReportHeader,
        footer: _buildPdfFooter,
        build: (context) => [
          pw.Divider(color: fColor, thickness: 0.3, height: 10),
          pw.SizedBox(height: 20),
          _reportContentTable(context),
          pw.SizedBox(height: 20),
          pw.Divider(color: fColor, thickness: 0.3, height: 20),
          _buildSignature(),
          pw.SizedBox(height: 20),
          _computerGenerated(),
        ],
      ),
    );
  }

  /// Computer Generate Notice [_computerGenerated]
  pw.Center _computerGenerated() => pw.Center(
    child: pw.Text(
      'Electronic version - $_reportTitle',
      textAlign: pw.TextAlign.center,
    ),
  );

  /// PDF-Doc Header [_buildReportHeader]
  pw.Widget _buildReportHeader(pw.Context context) {
    return pw.Expanded(child: pw.Column(children: [_contentHeader(context)]));
  }

  /// Company Logo [_buildCompanyLogo]
  _buildCompanyLogo() {
    return (_pdfColors.logo != null)
        ? pw.Container(
            alignment: pw.Alignment.topLeft,
            height: 40,
            padding: pw.EdgeInsets.zero,
            child: pw.Image(pw.MemoryImage(_pdfColors.logo!)),
            // _logo != null ? pw.SvgImage(svg: _logo!) : pw.PdfLogo(),
          )
        : pw.SizedBox.shrink();
  }

  /// PDF-Doc Footer [_buildPdfFooter]
  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          height: 20,
          width: 100,
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.pdf417(),
            data: '$_reportTitle # purchaseOrderNumber',
            drawText: false,
          ),
        ),
        pw.Text(
          'Page ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
        ),
      ],
    );
  }

  /// PDF-Doc Footer background-Img [_buildFooterBg]
  pw.FullPage _buildFooterBg() {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.SvgImage(svg: _pdfColors.footerImg),
    );
  }

  /// Company's info: name, email, phone, address & Report Title & Number [_contentHeader]
  pw.Widget _contentHeader(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildCompanyInfo(),
        pw.SizedBox(width: 20),
        pw.Expanded(child: _buildDateAndReference()),
      ],
    );
  }

  /// date, Total Report & StoreNumber [_buildDateAndReference]
  _buildDateAndReference() {
    var hColor = _pdfColors.headerColor;
    return pw.Container(
      height: 70,
      alignment: pw.Alignment.topRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        textAlign: pw.TextAlign.end,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              title.toUpperAll,
              style: pw.TextStyle(color: hColor, fontSize: 14),
            ),
            pw.SizedBox(height: 2.0),
            pw.RichText(
              text: pw.TextSpan(
                text: 'Date: ',
                children: [
                  pw.TextSpan(
                    text: PrintItem.formatDate(DateTime.now()),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 2.0),
            pw.RichText(
              text: pw.TextSpan(
                text: 'Total Report: ',
                children: [
                  pw.TextSpan(
                    text: sales.length.toString(),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 2.0),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Store #: ',
                  textAlign: pw.TextAlign.end,
                  style: pw.TextStyle(color: hColor),
                ),
                pw.Text(
                  storeNumber,
                  textAlign: pw.TextAlign.end,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Customer Name & Address [_buildCompanyInfo]
  _buildCompanyInfo() {
    return pw.Expanded(
      child: pw.Container(
        height: 70,
        alignment: pw.Alignment.topLeft,
        child: pw.DefaultTextStyle(
          softWrap: false,
          style: const pw.TextStyle(fontSize: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (_pdfColors.logo != null) ...{_buildCompanyLogo()},
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _company.name,
                    softWrap: true,
                    textAlign: pw.TextAlign.start,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    _company.address,
                    softWrap: true,
                    textAlign: pw.TextAlign.start,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Tel: ${_company.phone}',
                    softWrap: true,
                    textAlign: pw.TextAlign.start,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Fax:  ${_company.fax}',
                    softWrap: true,
                    textAlign: pw.TextAlign.start,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Email:  ${_company.email}',
                    softWrap: true,
                    textAlign: pw.TextAlign.start,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// PDF Report Content: Table-labels & contents [_reportContentTable]
  pw.Widget _reportContentTable(pw.Context context) {
    const tableHeaders = [
      '#',
      'sales date',
      'total sales',
      'total orders',
      'total items sold',
      'total discounts',
      'total taxes',
    ];

    return _buildContentCard(tableHeaders);
  }

  pw.Table _buildContentCard(List<String> tableHeaders) {
    return pw.TableHelper.fromTextArray(
      cellPadding: const pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(color: _pdfColors.footerColor, width: 0.2),
      cellAlignment: pw.Alignment.center,
      headerDecoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        color: _pdfColors.headerColor,
      ),
      headerHeight: 20,
      cellHeight: 20,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
      headerStyle: pw.TextStyle(
        color: _pdfColors.baseTextColor,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.normal),
      rowDecoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _pdfColors.footerColor, width: .5),
        ),
      ),
      headers: List<String>.generate(
        tableHeaders.length,
        (col) => tableHeaders[col].toTitle,
      ),
      data: List<List<String>>.generate(
        sales.length,
        (row) => List<String>.generate(
          tableHeaders.length,
          (col) => sales[row].getIndex(tableHeaders[col], row),
        ),
      ),
    );
  }

  pw.Widget _buildSignature() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(child: pw.SizedBox()),
        pw.Expanded(child: _buildSignatureBlock()),
      ],
    );
  }

  /// Append Signature [_buildSignatureBlock]
  pw.Container _buildSignatureBlock() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      alignment: pw.Alignment.bottomRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: pw.TextStyle(color: _pdfColors.footerColor, fontSize: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(kSignatureLine),
            pw.SizedBox(height: 4),
            pw.Text(
              createdBy, // approvedBy
              textAlign: pw.TextAlign.end,
              style: pw.TextStyle(
                color: _pdfColors.footerColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*static const _darkColor = PdfColors.blueGrey800;
  static const _lightColor = PdfColors.white;
  PdfColor get _baseTextColor => baseColor.isLight ? _lightColor : _darkColor;
  Uint8List? _logo;
  String? _bgShape;*/
