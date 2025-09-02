import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/print_util_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Print POS Sales Reports Model [PrintPOSReport]
class PrintPOSReport {
  PrintPOSReport({
    required this.title,
    required this.sales,
    required this.storeNumber,
  });

  final String title;
  final String storeNumber;
  final List<ReportItem> sales;

  /*final PrintoutSetupService _printoutSetupService = PrintoutSetupService();
  static bool _isDenseLayout = true;
  static const _blackColor = PdfColors.black;
  static PdfColor _headerColor = PdfColors.teal;
  static PdfColor _footerColor = PdfColors.blueGrey900;
  PdfColor get _baseTextColor => headerColor.isLight ? PdfColors.white : _blackColor;
  Uint8List? _logo;
  String? _bgShape;*/

  late final PrintPDFColors _pdfColors;
  late final IssuerCompany _company;

  String get _reportTitle => title.toUpperAll;

  /// Generate PDF-Doc [buildPdf]
  Future<Uint8List> buildPdf(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();
    _pdfColors = await PrintPDFColors.create();
    _company = _pdfColors.company;

    /*var setup = await _printoutSetupService.getSettings();
    if (setup != null && !setup.isColorsEmpty) {
      _isDenseLayout = setup.layout == 'dense';
      _headerColor = PdfColor.fromHex(setup.headerColor);
      _footerColor = PdfColor.fromHex(setup.footerColor);
    }

    // Load Assets Images
    ({Uint8List logo, String bg}) img = await LoadPrintAsset.loadImg(
      replaceSvgColorHex: _pdfColors.footerColorStr,
    );

    _logo = img.logo;
    _bgShape = img.bg;*/

    // Report: Add page to the PDF
    await _reportPDF(doc, pageFormat, _pdfColors.footerColor);

    // Return the PDF file content
    return doc.save();
  }

  /// PDF-Generator Theme [_buildTheme]
  Future<pw.PageTheme> _buildTheme(PdfPageFormat pageFormat) async {
    return pw.PageTheme(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.robotoRegular(),
        bold: await PdfGoogleFonts.robotoBold(),
        italic: await PdfGoogleFonts.robotoItalic(),
      ),
      buildBackground: (context) =>
          _pdfColors.isDenseLayout ? _buildFooterBg() : pw.SizedBox.shrink(),
    );
  }

  /// Report: First page to the PDF [_reportPDF]
  _reportPDF(pw.Document doc, PdfPageFormat pageFormat, PdfColor fColor) async {
    doc.addPage(
      pw.MultiPage(
        pageTheme: await _buildTheme(pageFormat),
        header: _buildReportHeader,
        footer: _buildFooter,
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

  /// PDF-Doc Footer [_buildFooter]
  pw.Widget _buildFooter(pw.Context context) {
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
  pw.FullPage _buildFooterBg() => pw.FullPage(
    ignoreMargins: true,
    child: pw.SvgImage(svg: _pdfColors.footerImg),
  );

  /// Company's info: name, email, phone, address & Report Title & Number [_contentHeader]
  pw.Widget _contentHeader(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _companyInfo(),
        pw.SizedBox(width: 20),
        pw.Expanded(child: _dateAndStoreNumber()),
      ],
    );
  }

  /// date, Total Report & StoreNumber [_dateAndStoreNumber]
  _dateAndStoreNumber() {
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
            pw.SizedBox(height: 3.0),
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

  /// Customer Name & Address [_companyInfo]
  _companyInfo() {
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
    var fColor = _pdfColors.footerColor;
    var isDense = _pdfColors.isDenseLayout;

    return pw.TableHelper.fromTextArray(
      cellPadding: const pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(color: fColor, width: 0.2),
      cellAlignment: pw.Alignment.center,
      headerDecoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        color: isDense ? _pdfColors.headerColor : null,
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
        color: isDense ? _pdfColors.baseTextColor : _pdfColors.blackColor,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.normal),
      rowDecoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: fColor, width: .5)),
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
        pw.Expanded(child: _appendSignature()),
      ],
    );
  }

  /// Append Signature [_appendSignature]
  pw.Container _appendSignature() {
    const signatureLine = '__________________________';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      alignment: pw.Alignment.bottomRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: pw.TextStyle(color: _pdfColors.blackColor, fontSize: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(signatureLine),
            pw.SizedBox(height: 4),
            pw.Text(
              'Authorized Signatory',
              textAlign: pw.TextAlign.end,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
