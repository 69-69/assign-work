import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/print_util_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintRFQ2 {
  PrintRFQ2({
    required this.items,
    required this.supplierEmail,
    required this.supplierName,
    required this.supplierAddress,
    this.supplierPhone = '',
    this.contactPerson = '',
    required this.rfqNumber,
    // required this.baseColor,
    // required this.accentColor,
  });

  final List<PrintItem> items;
  final String? supplierEmail;
  final String supplierName;
  final String supplierAddress;
  final String supplierPhone;
  final String contactPerson;
  final String rfqNumber;

  /*final PdfColor baseColor;
  final PdfColor accentColor;
  static const _darkColor = PdfColors.blueGrey800;
  static const _lightColor = PdfColors.white;
  PdfColor get _baseTextColor => baseColor.isLight ? _lightColor : _darkColor;
  Uint8List? _logo;
  String? _bgShape;*/

  String? get _deliveryDate =>
      items.map<String?>((p) => p.validityDate).reduce((a, b) => a ?? b);

  String get _rfqTitle => 'Request For Quotation';

  late final PrintPDFColors _pdfColors;
  late final IssuerCompany _company;

  /// Generate PDF-Doc [buildPdf]
  Future<Uint8List> buildPdf(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();
    _pdfColors = await PrintPDFColors.create();
    _company = _pdfColors.company;

    /*Load Assets Images
    ({Uint8List logo, String bg}) img = await LoadPrintAsset.loadImg();
    _logo = img.logo;
    _bgShape = img.bg;*/

    // Request For Quotation: Add page to the PDF
    await _requestForQuotePDF(doc, pageFormat, _pdfColors.footerColor);

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

  /// RFQ: First page to the PDF [_requestForQuotePDF]
  _requestForQuotePDF(
    pw.Document doc,
    PdfPageFormat pageFormat,
    PdfColor fColor,
  ) async {
    doc.addPage(
      pw.MultiPage(
        pageTheme: await _buildTheme(pageFormat),
        header: _buildPOHeader,
        footer: _buildFooter,
        build: (context) => [
          pw.Divider(color: fColor, thickness: 0.3, height: 10),
          pw.SizedBox(height: 20),
          _poContentTable(context),
          pw.Divider(color: fColor, thickness: 0.3, height: 20),
          _invoiceToAndApprovedBy(context),
          pw.SizedBox(height: 20),
          _computerGenerated(),
        ],
      ),
    );
  }

  /// Computer Generate Notice [_computerGenerated]
  pw.Center _computerGenerated() => pw.Center(
    child: pw.Text(
      'Electronic version - $_rfqTitle',
      textAlign: pw.TextAlign.center,
    ),
  );

  /// PDF-Doc Header [_buildPOHeader]
  pw.Widget _buildPOHeader(pw.Context context) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          _contentHeader(context),
          pw.Divider(color: _pdfColors.footerColor, height: 20),
          _buildHeaderCard(context),
        ],
      ),
    );
  }

  pw.Column _buildHeaderCard(pw.Context context) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            /// Supplier Info
            _supplierInfo(),
            pw.SizedBox(width: 100),

            /// ShipTo Info
            pw.Expanded(child: _shipToInfo()),
          ],
        ),
        if (context.pageNumber > 1) pw.SizedBox(height: 20),
      ],
    );
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

  /// Supplier's info: name, email, phone, address [_supplierInfo]
  pw.Container _supplierInfo() {
    return pw.Container(
      alignment: pw.Alignment.topRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: const pw.TextStyle(fontSize: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Supplier:',
              style: pw.TextStyle(
                color: _pdfColors.headerColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              supplierName,
              softWrap: true,
              textAlign: pw.TextAlign.start,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              supplierAddress,
              softWrap: true,
              textAlign: pw.TextAlign.start,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Tel: $supplierPhone',
              softWrap: true,
              textAlign: pw.TextAlign.start,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Email:  $supplierEmail',
              softWrap: true,
              textAlign: pw.TextAlign.start,
            ),
            pw.SizedBox(height: 2),
            pw.RichText(
              softWrap: true,
              textAlign: pw.TextAlign.end,
              text: pw.TextSpan(
                text: 'Contact Person: ',
                style: pw.TextStyle(
                  color: _pdfColors.footerColor,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  pw.TextSpan(
                    text: contactPerson,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ship-To info: name, email, phone, address [_shipToInfo]
  pw.Container _shipToInfo() {
    return pw.Container(
      alignment: pw.Alignment.topRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: const pw.TextStyle(fontSize: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Ship To:',
              textAlign: pw.TextAlign.start,
              style: pw.TextStyle(
                color: _pdfColors.headerColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              _company.name,
              softWrap: true,
              textAlign: pw.TextAlign.end,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              _company.address,
              softWrap: true,
              textAlign: pw.TextAlign.end,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Tel: ${_company.phone}',
              softWrap: true,
              textAlign: pw.TextAlign.end,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Fax:  ${_company.fax}',
              softWrap: true,
              textAlign: pw.TextAlign.end,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Email:  ${_company.email}',
              softWrap: true,
              textAlign: pw.TextAlign.end,
            ),
          ],
        ),
      ),
    );
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
            data: 'Purchase Order # $rfqNumber',
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

  /// Company's info: name, email, phone, address & PO Title & Number [_contentHeader]
  pw.Widget _contentHeader(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _companyInfo(),
        pw.SizedBox(width: 20),
        pw.Expanded(child: _dateAndRFQNumber()),
      ],
    );
  }

  /// date & Request For Quotation Number [_dateAndRFQNumber]
  _dateAndRFQNumber() {
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
              _rfqTitle.toUpperAll,
              style: pw.TextStyle(color: _pdfColors.headerColor, fontSize: 14),
            ),
            pw.SizedBox(height: 3.0),
            pw.Text(rfqNumber),
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
            pw.SizedBox(height: 4.0),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Delivery Date: ',
                  textAlign: pw.TextAlign.end,
                  style: pw.TextStyle(color: _pdfColors.headerColor),
                ),
                pw.Text(
                  _deliveryDate ?? '',
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

  /// PDF PO Content: Table-labels & contents [_poContentTable]
  pw.Widget _poContentTable(pw.Context context) {
    const tableHeaders = [
      '#',
      'item description',
      'quantity',
      'unit price',
      'discount',
      'net price',
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
      },
      headerStyle: pw.TextStyle(
        color: _pdfColors.baseTextColor,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(
        color: _pdfColors.blackColor,
        fontSize: 10,
        fontWeight: pw.FontWeight.normal,
      ),
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
        items.length,
        (row) => List<String>.generate(
          tableHeaders.length,
          (col) => items[row].getIndex(tableHeaders[col], row),
        ),
      ),
    );
  }

  /// Send Invoice & And Approved-By Signature to [_invoiceToAndApprovedBy]
  pw.Widget _invoiceToAndApprovedBy(pw.Context context) {
    var hColor = _pdfColors.headerColor;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _pdfColors.footerColor),
            ),
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Buyer Contact:',
                  style: pw.TextStyle(
                    color: hColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  contactPerson,
                  softWrap: true,
                  textAlign: pw.TextAlign.start,
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Deadline Date: ',
                      textAlign: pw.TextAlign.start,
                      style: pw.TextStyle(
                        color: hColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _deliveryDate ?? '',
                      textAlign: pw.TextAlign.end,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.Expanded(child: _appendSignature()),
      ],
    );
  }

  /// Append Signature [_appendSignature]
  pw.Container _appendSignature() {
    const signatureLine = '__________________________';

    var fColor = _pdfColors.footerColor;
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        border: pw.Border.all(color: fColor, width: 0.2),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      alignment: pw.Alignment.bottomRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: pw.TextStyle(color: fColor, fontSize: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(signatureLine),
            pw.SizedBox(height: 4),
            pw.Text(
              'Authorized Signatory',
              textAlign: pw.TextAlign.end,
              style: pw.TextStyle(
                color: fColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
