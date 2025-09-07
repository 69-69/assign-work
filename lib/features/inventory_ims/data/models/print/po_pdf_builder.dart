import 'dart:typed_data';

import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/print_theme_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class POPdfBuilder {
  POPdfBuilder({
    required this.items,
    required this.supplierEmail,
    required this.supplierName,
    required this.supplierAddress,
    this.supplierPhone = '',
    this.contactName = '',
    this.approvedBy = 'Authorized Signatory',
    required this.poNumber,
    this.termsAndConditions,
    // required this.baseColor,
    // required this.accentColor,
  });

  final List<PrintItem> items;
  final String approvedBy;
  final String? supplierEmail;
  final String supplierName;
  final String supplierAddress;
  final String supplierPhone;
  final String contactName;
  final String poNumber;
  final String? termsAndConditions;

  /*final PdfColor baseColor;
  final PdfColor accentColor;
  static const _darkColor = PdfColors.blueGrey800;
  static const _lightColor = PdfColors.white;
  PdfColor get _baseTextColor => baseColor.isLight ? _lightColor : _darkColor;
  Uint8List? _logo;
  String? _bgShape;*/

  double get _subTotal =>
      items.map<double>((p) => p.totalNetPrice).reduce((a, b) => a + b);

  double get _tax =>
      items.map<double>((p) => p.taxPercent).reduce((a, b) => a + b);

  double get _taxAmount => (_tax / 100) * _subTotal;

  String? get _paymentTerms =>
      items.map<String?>((p) => p.paymentTerms).reduce((a, b) => a ?? b);

  double get _grandTotalPrice => _subTotal + _taxAmount;

  String? get _deliveryDate =>
      items.map<String?>((p) => p.validityDate).reduce((a, b) => a ?? b);

  String get _poTitle => 'Purchase Order';

  late final PrintPDFConfig _pdfColors;
  late final IssuerCompany _company;

  /// Generate PDF-Doc [build]
  Future<Uint8List> build(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();
    _pdfColors = await PrintPDFConfig.create();
    _company = _pdfColors.company;

    // PO or Receipt: Add page to the PDF
    await _addPOPage(doc, pageFormat, _pdfColors.footerColor);

    // Return the PDF file content
    return doc.save();

    /*// Load Assets Images
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

  /// PO: First page to the PDF [_buildPO]
  _addPOPage(pw.Document doc, PdfPageFormat pageFormat, PdfColor fColor) async {
    doc.addPage(
      pw.MultiPage(
        pageTheme: await _buildTheme(pageFormat),
        header: _buildPOHeader,
        footer: _buildFooter,
        build: (context) => [
          pw.Divider(color: fColor, thickness: 0.3, height: 10),
          pw.SizedBox(height: 20),
          _poContentTable(context),
          pw.SizedBox(height: 20),
          _contentFooter(context),
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
      'Electronic version - $_poTitle',
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
                    text: contactName,
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
            data: 'Purchase Order # $poNumber',
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

  /// Company's info: name, email, phone, address & PO Title & Number [_contentHeader]
  pw.Widget _contentHeader(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _companyInfo(),
        pw.SizedBox(width: 20),
        pw.Expanded(child: _dateAndPONumber()),
      ],
    );
  }

  /// date & Purchase order Number [_dateAndPONumber]
  _dateAndPONumber() {
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
              _poTitle.toUpperAll,
              style: pw.TextStyle(color: hColor, fontSize: 14),
            ),
            pw.SizedBox(height: 3.0),
            pw.RichText(
              text: pw.TextSpan(
                text: '#: ',
                children: [
                  pw.TextSpan(
                    text: poNumber,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                  ),
                ],
              ),
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
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Delivery Date: ',
                  textAlign: pw.TextAlign.end,
                  style: pw.TextStyle(color: hColor),
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

  /// ThankYou, Payment-Terms, SubTotal & total Amount-Bottom [_contentFooter]
  pw.Widget _contentFooter(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [..._paymentTermsAndValidity()],
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.DefaultTextStyle(
            style: pw.TextStyle(fontSize: 12, color: _pdfColors.blackColor),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSubTotal(),
                pw.SizedBox(height: 5),
                _buildTax(),
                pw.Divider(color: _pdfColors.footerColor),
                _totalAmountBottom(),
              ],
            ),
          ),
        ),
      ],
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
    var fColor = _pdfColors.footerColor;
    return pw.TableHelper.fromTextArray(
      cellPadding: const pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(color: fColor, width: 0.2),
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
        border: pw.Border(bottom: pw.BorderSide(color: fColor, width: .5)),
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

  /// Total Amount Bottom-Section [_totalAmountBottom]
  pw.DefaultTextStyle _totalAmountBottom() {
    return pw.DefaultTextStyle(
      style: pw.TextStyle(
        color: _pdfColors.headerColor,
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Total:'),
          pw.Text(PrintItem.formatCurrency(_grandTotalPrice)),
        ],
      ),
    );
  }

  /// Tax Percent [_buildTax]
  pw.Row _buildTax() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Tax:'),
        pw.Text('($_tax%) $ghanaCedis${_taxAmount.toStringAsFixed(2)}'),
        // pw.Text('${(tax * 100).toStringAsFixed(1)}%'),
      ],
    );
  }

  /// Sub Total [_buildSubTotal]
  pw.Row _buildSubTotal() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Sub Total:'),
        pw.Text(PrintItem.formatCurrency(_subTotal)),
      ],
    );
  }

  /// Payment Info [_paymentTermsAndValidity]
  Set<pw.Widget> _paymentTermsAndValidity() {
    return {
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          'Payment Terms:',
          style: pw.TextStyle(
            color: _pdfColors.headerColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.Text(
        _paymentTerms ?? '',
        style: pw.TextStyle(
          fontSize: 12,
          lineSpacing: 5,
          color: _pdfColors.blackColor,
        ),
      ),
    };
  }

  /// Send Invoice & And Approved-By Signature to [_invoiceToAndApprovedBy]
  pw.Widget _invoiceToAndApprovedBy(pw.Context context) {
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
                  'Invoice To:',
                  style: pw.TextStyle(
                    color: _pdfColors.headerColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _company.name,
                  softWrap: true,
                  textAlign: pw.TextAlign.start,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Tel: ${_company.phone}',
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
          ),
        ),
        pw.Expanded(child: _appendSignature()),
      ],
    );
  }

  /// Append Signature [_appendSignature]
  pw.Container _appendSignature() {
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
            pw.Text(kSignatureLine),
            pw.SizedBox(height: 4),
            pw.Text(
              approvedBy,
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

/*
Future<Uint8List> buildPdf(PdfPageFormat format) async {
  // Create the Pdf document
  final pw.Document doc = pw.Document();

  // Add one page with centered text "Hello World"
  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (pw.Context context) {
        return pw.ConstrainedBox(
          constraints: pw.BoxConstraints.expand(),
          child: pw.FittedBox(
            child: pw.Text('Hello World'),
          ),
        );
      },
    ),
  );

  // Build and return the final Pdf file data
  return await doc.save();
}

Future<Uint8List> buildPdf(PdfPageFormat format) async {
  // Create the Pdf document
  final pw.Document doc = pw.Document();

  // Add one page with centered text "Hello World"
  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (pw.Context context) {
        return pw.ConstrainedBox(
          constraints: pw.BoxConstraints.expand(),
          child: pw.FittedBox(
            child: pw.Text('Hello World'),
          ),
        );
      },
    ),
  );

  // Build and return the final Pdf file data
  return await doc.save();
}
*/
