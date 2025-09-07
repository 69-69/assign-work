import 'dart:typed_data';

import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/print_theme_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum SalesDocType { invoice, proforma, delivery }

/// Print Sales Invoice / Proforma / Delivery Note documents (Way-Bill) [SalesDocPdfBuilder]
class SalesDocPdfBuilder {
  SalesDocPdfBuilder({
    required this.title,
    required this.products,
    required this.customerId,
    required this.customerName,
    required this.customerAddress,
    required this.invoiceNumber,
    this.termsAndConditions,
    // required this.baseColor,
    // required this.accentColor,
  });

  final String title;
  final List<PrintItem> products;
  final String customerId;
  final String customerName;
  final String customerAddress;
  final String invoiceNumber;
  final String? termsAndConditions;
  /*final PdfColor baseColor;
  final PdfColor accentColor;

  static const _darkColor = PdfColors.blueGrey800;
  static const _lightColor = PdfColors.white;

  PdfColor get _baseTextColor => baseColor.isLight ? _lightColor : _darkColor;
  Uint8List? _logo;
  String? _bgShape;*/

  double get _subTotal =>
      products.map<double>((p) => p.totalNetPrice).reduce((a, b) => a + b);

  int get _totalItemQty =>
      products.map<int>((p) => p.quantity).reduce((a, b) => a + b);

  double get _tax =>
      products.map<double>((p) => p.taxPercent).reduce((a, b) => a + b);

  double get _taxAmount => (_tax / 100) * (_subTotal + _deliveryAmt);

  double get _deliveryAmt =>
      products.map<double>((p) => p.deliveryAmt).reduce((a, b) => a + b);

  String? get _paymentTerms =>
      products.map<String?>((p) => p.paymentTerms).reduce((a, b) => a ?? b);

  double get _grandTotalPrice => (_subTotal + _deliveryAmt) + _taxAmount;

  String? get _validity =>
      products.map<String?>((p) => p.validityDate).reduce((a, b) => a ?? b);

  String get _title => title.toTitle;

  bool _isDocType(SalesDocType s) => _title.toLowerAll.contains(s.name);

  late final PrintPDFConfig _pdfColors;
  late final IssuerCompany _company;

  /// Generate PDF-Doc [build]
  Future<Uint8List> build(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();
    _pdfColors = await PrintPDFConfig.create();
    _company = _pdfColors.company;

    // Invoice or Receipt: Add page to the PDF
    await _addDocPage(doc, pageFormat, _pdfColors.footerColor);

    if (_isDocType(SalesDocType.delivery)) {
      // Way-Bill: Add Second page to the PDF
      await _buildDeliveryNotePDF(doc, pageFormat, _pdfColors.footerColor);
    }
    // Return the PDF file content
    return doc.save();
  }

  /// PDF-Generator Theme [_buildTheme]
  Future<pw.PageTheme> _buildTheme(PdfPageFormat pageFormat) async {
    return await FontManager.loadTheme(
      pageFormat,
      buildBackground: (context) =>
          _pdfColors.isDenseLayout ? _buildFooterBg() : pw.SizedBox.shrink(),
    );
  }

  /// Invoice or Receipt: First page to the PDF [_addDocPage]
  _addDocPage(
    pw.Document doc,
    PdfPageFormat pageFormat,
    PdfColor fColor,
  ) async {
    doc.addPage(
      pw.MultiPage(
        pageTheme: await _buildTheme(pageFormat),
        header: _buildPdfHeader,
        footer: _buildFooter,
        build: (context) => [
          pw.Divider(color: fColor, thickness: 0.3, height: 20),
          _invoiceContentHeader(context),
          pw.SizedBox(height: 20),
          _invoiceContentTable(context),
          pw.SizedBox(height: 20),
          _invoiceContentFooter(context),
          pw.Divider(color: fColor, thickness: 0.3, height: 30),
          if (!_isDocType(SalesDocType.proforma)) ...{
            _termsAndConditions(context),
            pw.SizedBox(height: 20),
          },
          _buildSignatureBlock(),
          pw.SizedBox(height: 20),
          _buildThankYou(),
          pw.SizedBox(height: 20),
          _computerGenerated(),
        ],
      ),
    );
  }

  /// Delivery-Note / Way-Bill: Second page to the PDF [_buildDeliveryNotePDF]
  _buildDeliveryNotePDF(
    pw.Document doc,
    PdfPageFormat pageFormat,
    PdfColor fColor,
  ) async {
    doc.addPage(
      pw.MultiPage(
        pageTheme: await _buildTheme(pageFormat),
        header: _buildDeliveryNoteHeader,
        footer: _buildFooter,
        build: (context) => [
          pw.Divider(color: fColor, height: 20),
          _deliveryNoteContentHeader(context),
          pw.SizedBox(height: 3),
          _deliveryNoteContentTable(context),
          pw.SizedBox(height: 20),
          _deliveryNoteContentFooter(context),
          pw.SizedBox(height: 20),
          _buildSignatureBlock(),
          pw.SizedBox(height: 20),
          _computerGenerated(),
        ],
      ),
    );
  }

  /// Computer Generate Notice [_computerGenerated]
  pw.Center _computerGenerated() => pw.Center(
    child: pw.Text(
      'Electronic version - $_title',
      textAlign: pw.TextAlign.center,
    ),
  );

  /// PDF-Doc Header [_buildPdfHeader]
  pw.Widget _buildPdfHeader(pw.Context context) {
    final label = _isDocType(SalesDocType.delivery) ? 'Invoice' : _title;
    return _buildDocHeaderInfo(
      context,
      _dateAndInvoiceNumber(title: label, idNumber: invoiceNumber),
    );
  }

  /// PDF-Doc Header [_buildDeliveryNoteHeader]
  pw.Widget _buildDeliveryNoteHeader(pw.Context context) {
    return _buildDocHeaderInfo(
      context,
      _dateAndDeliveryNumber(
        title: 'Delivery Note',
        idNumber: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    );
  }

  _buildDocHeaderInfo(pw.Context context, pw.Widget child) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildCompanyInfo(),
            pw.SizedBox(width: 20),
            pw.Expanded(child: child),
          ],
        ),
        if (context.pageNumber > 1) pw.SizedBox(height: 20),
      ],
    );
  }

  /// Company Logo [_buildCompanyLogo]
  _buildCompanyLogo() {
    return pw.Container(
      alignment: pw.Alignment.topLeft,
      height: 40,
      padding: pw.EdgeInsets.zero,
      child: pw.Image(pw.MemoryImage(_pdfColors.logo!)),
      // _logo != null ? pw.SvgImage(svg: _logo!) : pw.PdfLogo(),
    );
  }

  /// Company's info: name, email, phone, address [_buildCompanyInfo]
  _buildCompanyInfo() {
    return pw.Expanded(
      child: pw.Container(
        // height: 70,
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

  /// Invoice Number & Date [_dateAndInvoiceNumber]
  _dateAndInvoiceNumber({String title = '', String idNumber = ''}) {
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
                text: '#: ',
                children: [
                  pw.TextSpan(
                    text: idNumber,
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
            if (_isDocType(SalesDocType.proforma) &&
                !_validity.isNullOrEmpty) ...{
              pw.SizedBox(height: 2.0),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Validity: ',
                    textAlign: pw.TextAlign.end,
                    style: pw.TextStyle(color: hColor),
                  ),
                  pw.Text(
                    _validity ?? '',
                    textAlign: pw.TextAlign.end,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                  ),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }

  /// Delivery Number & Date [_dateAndDeliveryNumber]
  _dateAndDeliveryNumber({String title = '', String idNumber = ''}) {
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
              style: pw.TextStyle(color: _pdfColors.headerColor, fontSize: 14),
            ),
            pw.SizedBox(height: 3.0),
            pw.RichText(
              text: pw.TextSpan(
                text: '#: ',
                children: [
                  pw.TextSpan(
                    text: idNumber,
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
            data: 'Invoice# $invoiceNumber',
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

  /// Customer Name, Address & total Amount-Top [_invoiceContentHeader]
  pw.Widget _invoiceContentHeader(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [_totalAmountTop(), _customerNameAndAddress()],
    );
  }

  pw.Widget _deliveryNoteContentHeader(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [_customerNameAndAddress()],
    );
  }

  /// Customer Name & Address [_customerNameAndAddress]
  _customerNameAndAddress() {
    var fColor = _pdfColors.footerColor;
    return pw.Expanded(
      child: pw.Container(
        height: 70,
        alignment: pw.Alignment.topRight,
        margin: const pw.EdgeInsets.only(right: 20),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.RichText(
                softWrap: true,
                textAlign: pw.TextAlign.end,
                text: pw.TextSpan(
                  text: 'Buyer: ',
                  style: pw.TextStyle(
                    color: _pdfColors.headerColor,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    pw.TextSpan(
                      text: '$customerName\n',
                      style: pw.TextStyle(
                        color: fColor,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                    const pw.TextSpan(
                      text: '\n',
                      style: pw.TextStyle(fontSize: 5),
                    ),
                    pw.TextSpan(
                      text: customerAddress,
                      style: pw.TextStyle(
                        color: fColor,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ThankYou, Payment-Terms, SubTotal & total Amount-Bottom [_invoiceContentFooter]
  pw.Widget _invoiceContentFooter(pw.Context context) {
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
                _buildDeliveryAmt(),
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

  /// ThankYou, Payment-Terms & total Item Quantity -Bottom [_deliveryNoteContentFooter]
  pw.Widget _deliveryNoteContentFooter(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 2, child: pw.SizedBox.shrink()),
        pw.Expanded(
          flex: 1,
          child: pw.DefaultTextStyle(
            style: pw.TextStyle(fontSize: 12, color: _pdfColors.blackColor),
            child: _deliveryTotalQtyBottom(),
          ),
        ),
      ],
    );
  }

  /// Terms & Conditions [_termsAndConditions]
  pw.Widget _termsAndConditions(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                /*decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: accentColor)),
                ),*/
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  'Terms & Conditions',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: _pdfColors.headerColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                termsAndConditions ??
                    'GOODS ONCE SOLID AND SUPPLIED ARE NOT RETURNABLE',
                textAlign: pw.TextAlign.justify,
                style: pw.TextStyle(fontSize: 10, color: _pdfColors.blackColor),
              ),
            ],
          ),
        ),
        pw.Expanded(child: pw.SizedBox()),
      ],
    );
  }

  /// PDF Invoice Content: Table-labels & contents [_invoiceContentTable]
  pw.Widget _invoiceContentTable(pw.Context context) {
    const tableHeaders = [
      '#',
      'item description',
      'quantity',
      'unit price',
      'discount',
      'net price',
    ];

    return _buildContentCard(
      tableHeaders,
      cellAlign: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
    );
  }

  /// PDF Way-Bill Content: Table-labels & contents [_deliveryNoteContentTable]
  pw.Widget _deliveryNoteContentTable(pw.Context context) {
    const tableHeaders = ['#', 'item description', 'quantity'];

    return _buildContentCard(
      tableHeaders,
      cellAlign: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
      },
    );
  }

  pw.Table _buildContentCard(
    List<String> tableHeaders, {
    Map<int, pw.AlignmentGeometry>? cellAlign,
  }) {
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
      cellAlignments: cellAlign,
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
        products.length,
        (row) => List<String>.generate(
          tableHeaders.length,
          (col) => products[row].getIndex(tableHeaders[col], row),
        ),
      ),
    );
  }

  /// total Amount Top-Section [_totalAmountTop]
  pw.Expanded _totalAmountTop() {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 20),
        height: 70,
        alignment: pw.Alignment.topLeft,
        child: pw.FittedBox(
          child: pw.Text(
            'Total: ${PrintItem.formatCurrency(_grandTotalPrice)}',
            style: pw.TextStyle(
              color: _pdfColors.headerColor,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
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

  /// Total Items Quantity Bottom-Section [_deliveryTotalQtyBottom]
  pw.DefaultTextStyle _deliveryTotalQtyBottom() {
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
          pw.Text(
            '$_totalItemQty Piece(s)',
            style: pw.TextStyle(
              color: _pdfColors.footerColor,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
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

  /// delivery Amount [_buildDeliveryAmt]
  pw.Row _buildDeliveryAmt() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Delivery Fee:'),
        pw.Text(ghanaCedis + _deliveryAmt.toStringAsFixed(2)),
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
        margin: const pw.EdgeInsets.only(top: 20, bottom: 8),
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
          fontSize: 10,
          lineSpacing: 5,
          color: _pdfColors.blackColor,
        ),
      ),
    };
  }

  /// Thank you note[_buildThankYou]
  pw.Text _buildThankYou() {
    return pw.Text(
      'Thank you for your business',
      style: pw.TextStyle(
        color: _pdfColors.blackColor,
        fontWeight: pw.FontWeight.normal,
      ),
    );
  }

  /// Append Signature [_buildSignatureBlock]
  pw.Container _buildSignatureBlock() {
    var fColor = _pdfColors.footerColor;

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        border: pw.Border.all(width: 0.2, color: fColor),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      alignment: pw.Alignment.bottomRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: pw.TextStyle(color: fColor, fontSize: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(kSignatureLine),
                pw.Text(
                  'for ${_company.name}',
                  textAlign: pw.TextAlign.end,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 20.0),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(kSignatureLine),
                pw.Text(
                  'Authorized Signatory',
                  textAlign: pw.TextAlign.end,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/*
pw.Container _dateAndDeliveryNumber2(String label, String idNumber) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        color: accentColor,
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      alignment: pw.Alignment.topRight,
      height: 50,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: pw.TextStyle(color: _accentTextColor, fontSize: 12),
        child: pw.GridView(
          crossAxisCount: 2,
          children: [
            pw.Text('$label #: '),
            pw.Text(idNumber),
            pw.Text('Date: '),
            pw.Text(PrintItem.formatDate(DateTime.now())),
          ],
        ),
      ),
    );
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
}*/
