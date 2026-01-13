import 'dart:typed_data';

import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/network/data_sources/models/contact_person_model.dart';
import 'package:assign_erp/core/network/data_sources/models/printout_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:collection/collection.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Printout for Request For Quotation [RFQPrinter]
class RFQPrinter {
  final Supplier supplier;
  final RequestForQuote rfq;

  RFQPrinter({required this.rfq, required this.supplier});

  Future<void> printRFQ() async {
    Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async =>
          await _generatePdf(format: PdfPageFormat.a4),
    );
  }

  List<PrintItem> _buildLineItems() {
    final currencySign = getCurrencySign(rfq.currencyCode);

    return rfq.lineItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return PrintItem(
        sku: '${index + 1}',
        currencySign: currencySign,
        itemName: item.description,
        quantity: item.quantity,
        discount: item.discountPercent,
        unitPrice: item.unitPrice,
        taxAmount: item.taxAmount,
        paymentTerms: rfq.buyerContactPersonId,
        taxNames: item.taxNames.toUpperAll,
        validityDate: rfq.getDeadlineDate,
      );
    }).toList();
  }

  Future<Uint8List> _generatePdf({
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    List<PrintItem> lineItems = _buildLineItems();

    ContactPerson? contactPerson = supplier.contactPersons.firstWhereOrNull(
      (i) => i.id == rfq.supplierLinks.first.supplierRepId,
    );

    final quote = _RFQPdfBuilder(
      items: lineItems,
      supplier: supplier,
      rfqNumber: rfq.rfqNumber,
      contactPerson: contactPerson,
      validityDate: rfq.getDeadlineDate,
      deliveryDate: rfq.getExpectedDate,
      altDeliveryAddress: rfq.shippingAddress?.address ?? '',
    );

    // Now you can use the `rfq` object as needed, e.g., to print or display it
    return await quote.build(format);
  }
}

/// Printout for Request For Quotation [RFQPdfBuilder]
class _RFQPdfBuilder {
  _RFQPdfBuilder({
    required this.items,
    required this.rfqNumber,
    required this.supplier,
    this.contactPerson,
    this.altDeliveryAddress,
    this.deliveryDate,
    this.validityDate,
  });

  final String rfqNumber;
  final Supplier supplier;
  final String? deliveryDate;
  final String? validityDate;
  final List<PrintItem> items;
  final String? altDeliveryAddress;
  final ContactPerson? contactPerson;

  String get _rfqTitle => 'Request For Quotation';

  late final PrintPDFConfig _pdfColors;

  late final IssuerCompany _company;

  /// Body Font Size = 11 [_bodyFontSize]
  late double _bodyFontSize;

  /// Header Font Size = 13 [_headerFontSize]
  late final double _headerFontSize;

  /// Sub-header Font Size = 12 [_subHeaderFontSize]
  late final double _subHeaderFontSize;

  /// Table Font Size = 10 [_tableFontSize]
  late final double _tableFontSize;

  /// Generate PDF-Doc [build]
  Future<Uint8List> build(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();
    _pdfColors = await PrintPDFConfig.create();
    _company = _pdfColors.company;
    _bodyFontSize = _pdfColors.bodyFontSize;
    _tableFontSize = _pdfColors.tableFontSize;
    _headerFontSize = _pdfColors.bodyFontSize;
    _subHeaderFontSize = _pdfColors.subHeaderFontSize;

    // Request For Quotation: Add page to the PDF
    await _addRfqPage(doc, pageFormat, _pdfColors.footerColor);

    // Return the PDF file content
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

  /// RFQ: First page to the PDF [_addRfqPage]
  _addRfqPage(
    pw.Document doc,
    PdfPageFormat pageFormat,
    PdfColor fColor,
  ) async {
    doc.addPage(
      pw.MultiPage(
        pageTheme: await _buildTheme(pageFormat),
        header: _buildPdfHeader,
        footer: _buildPdfFooter,
        build: (context) => [
          pw.Divider(color: fColor, thickness: 0.3, height: 10),
          pw.SizedBox(height: 10),
          _buildItemTable(context),
          pw.Divider(color: fColor, thickness: 0.3, height: 20),
          _invoiceToAndApprovedBy(),
          pw.SizedBox(height: 20),
          // _computerGenerated(),
        ],
      ),
    );
  }

  /*/// Computer Generate Notice
  pw.Center _computerGenerated() => pw.Center(
    child: pw.Text(
      'Electronic Version - $_rfqTitle',
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontSize: 11),
    ),
  );*/

  /// PDF-Doc Header
  pw.Widget _buildPdfHeader(pw.Context context) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          _buildDocHeaderInfo(context),
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
            pw.Expanded(child: _buildShipToInfo()),
          ],
        ),
        if (context.pageNumber > 1) pw.SizedBox(height: 20),
      ],
    );
  }

  /// Company Logo
  _buildCompanyLogo() {
    return (_pdfColors.logo != null)
        ? pw.Container(
            alignment: pw.Alignment.topLeft,
            height: 40,
            padding: pw.EdgeInsets.zero,
            margin: pw.EdgeInsets.zero,
            child: pw.Image(pw.MemoryImage(_pdfColors.logo!)),
            // _logo != null ? pw.SvgImage(svg: _logo!) : pw.PdfLogo(),
          )
        : pw.SizedBox.shrink();
  }

  /// Supplier's info: name, email, phone, address
  pw.Container _supplierInfo() {
    final supList = [
      'Supplier:',
      supplier.name.toTitle,
      supplier.address.toSentence,
    ];

    final supListSub = [
      ('Tel', supplier.phone),
      ('Email', supplier.email.toLowerAll),
    ];

    final contactList = [
      'Contact Person: ',
      '${contactPerson?.name ?? ''} - ${contactPerson?.position ?? ''}'.toTitle,
    ];

    final contactListSub = [
      ('Phone', contactPerson?.phone ?? 'N/A'),
      ('Email', contactPerson?.email.toLowerAll ?? 'N/A'),
      ('Department', contactPerson?.department.toTitle ?? 'N/A'),
    ];

    return pw.Container(
      alignment: pw.Alignment.topRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: pw.TextStyle(fontSize: _bodyFontSize),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            /// Supplier Info
            ..._buildSection(supList),
            ..._buildSubSection(supListSub),
            pw.SizedBox(height: 10),

            /// Supplier's Contact Person
            ..._buildSection(contactList),
            ..._buildSubSection(contactListSub),
          ],
        ),
      ),
    );
  }

  /// Ship-To info: name, email, phone, address [_buildShipToInfo]
  pw.Container _buildShipToInfo() {
    final shipList = [
      'Ship To:',
      _company.name,
      (altDeliveryAddress ?? _company.address).toSentence,
    ];
    final shipListSub = [
      ('Tel', _company.phone),
      ('Fax', _company.fax),
      ('Email', _company.email),
    ];

    return pw.Container(
      alignment: pw.Alignment.topRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: pw.TextStyle(
          fontSize: _bodyFontSize,
          fontWeight: pw.FontWeight.bold,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            ..._buildSection(shipList),
            ..._buildSubSection(shipListSub),
          ],
        ),
      ),
    );
  }

  // Helper function to create the styled text (e.g. Supplier Name)
  Iterable<pw.Text> _buildSection(List<dynamic> list) {
    return list.map(
      (i) => _buildText(
        i,
        textAlign: pw.TextAlign.start,
        style: pw.TextStyle(
          fontWeight: list.first == i ? pw.FontWeight.bold : null,
          color: list.first == i ? _pdfColors.headerColor : null,
        ),
      ),
    );
  }

  // Helper function to create rich text for sub items (e.g. Tel: 23242, Email: em@you.com)
  Iterable<pw.RichText> _buildSubSection(List<dynamic> list) {
    return list.map(
      (i) => _buildRichText(
        '${i.$1}: ',
        i.$2,
        style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
      ),
    );
  }

  pw.Text _buildText(
    String label, {
    pw.TextAlign textAlign = pw.TextAlign.end,
    pw.TextStyle? style,
  }) {
    return pw.Text(label, softWrap: true, textAlign: textAlign, style: style);
  }

  pw.RichText _buildRichText(String title, String desc, {pw.TextStyle? style}) {
    return pw.RichText(
      softWrap: true,
      textAlign: pw.TextAlign.start,
      text: pw.TextSpan(
        text: title,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        children: [
          pw.TextSpan(
            text: desc,
            style: style ?? pw.TextStyle(fontWeight: pw.FontWeight.normal),
          ),
        ],
      ),
    );
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
            data: '$_rfqTitle #: $rfqNumber',
            drawText: false,
          ),
        ),
        pw.Text(
          'Electronic Version - Page ${context.pageNumber}/${context.pagesCount}',
          style: pw.TextStyle(fontSize: _tableFontSize, color: PdfColors.white),
        ),
      ],
    );
  }

  /// PDF-Doc Footer background-Img [_buildFooterBg]
  pw.FullPage _buildFooterBg() => pw.FullPage(
    ignoreMargins: true,
    child: pw.SvgImage(svg: _pdfColors.footerImg),
  );

  /// Company's info: name, email, phone, address & PO Title & Number [_buildDocHeaderInfo]
  pw.Widget _buildDocHeaderInfo(pw.Context context) {
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

  /// date & Request For Quotation Number [_buildDateAndReference]
  _buildDateAndReference() {
    final topList = [
      ('RFQ#', rfqNumber.toUpperAll),
      ('Date', PrintItem.formatDate(DateTime.now())),
      ('Delivery', deliveryDate),
    ];

    return pw.Container(
      height: 70,
      alignment: pw.Alignment.topRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        textAlign: pw.TextAlign.end,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: _bodyFontSize,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              _rfqTitle.toUpperAll,
              style: pw.TextStyle(
                color: _pdfColors.headerColor,
                fontSize: _headerFontSize,
              ),
            ),
            ..._buildSubSection(topList),
          ],
        ),
      ),
    );
  }

  /// Customer Name & Address
  _buildCompanyInfo() {
    final companyList = [
      ('Tel', _company.phone),
      ('Fax', _company.fax),
      ('Email', _company.email),
    ];

    return pw.Expanded(
      child: pw.Container(
        height: 70,
        alignment: pw.Alignment.topLeft,
        child: pw.DefaultTextStyle(
          softWrap: false,
          textAlign: pw.TextAlign.start,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: _bodyFontSize,
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (_pdfColors.logo != null) ...{_buildCompanyLogo()},
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _company.name.toTitle,
                    textAlign: pw.TextAlign.start,
                    style: pw.TextStyle(
                      color: _pdfColors.headerColor,
                      fontSize: _headerFontSize,
                    ),
                  ),
                  ..._buildSection([_company.address]),
                  ..._buildSubSection(companyList),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// PDF PO Content: Table-labels & contents [_buildItemTable]
  pw.Widget _buildItemTable(pw.Context context) {
    const tableHeaders = [
      '#',
      'item',
      'Qty',
      'unit price',
      'discount',
      'tax amount',
      'tax codes',
      'line total',
    ];

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
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
      headerStyle: pw.TextStyle(
        color: _pdfColors.baseTextColor,
        fontSize: _tableFontSize,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(
        color: _pdfColors.blackColor,
        fontSize: _tableFontSize,
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
          // (col) => items[row].itemAsList.elementAt(col),
          (col) => items[row].getIndex(tableHeaders[col], row),
        ),
      ),
    );
  }

  /// Send Invoice & Approved-By Signature
  pw.Widget _invoiceToAndApprovedBy() {
    var hColor = _pdfColors.headerColor;
    var fColor = _pdfColors.footerColor;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _buildInvoiceTo(hColor),
        pw.Expanded(child: _buildSignatureBlock(fColor)),
      ],
    );
  }

  pw.Expanded _buildInvoiceTo(PdfColor hColor) {
    return pw.Expanded(
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: pw.TextStyle(fontSize: _bodyFontSize),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildText(
              'Buyer Contact:',
              style: pw.TextStyle(
                color: hColor,
                fontSize: _bodyFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            _buildText(
              '${contactPerson?.name.toTitle ?? 'N/A'} - ${contactPerson?.position.toTitle ?? ''}',
            ),
            ..._buildSubSection([('Deadline: ', validityDate ?? '')]),
          ],
        ),
      ),
    );
  }

  /// Append Signature
  pw.DefaultTextStyle _buildSignatureBlock(PdfColor fColor) {
    return pw.DefaultTextStyle(
      softWrap: false,
      style: pw.TextStyle(color: fColor, fontSize: _bodyFontSize),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(kSignatureLine),
          pw.SizedBox(height: 4),
          _buildText(
            'Authorized Signatory',
            style: pw.TextStyle(
              color: fColor,
              fontSize: _bodyFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /*final PdfColor baseColor;
    final PdfColor accentColor;
    static const _darkColor = PdfColors.blueGrey800;
    static const _lightColor = PdfColors.white;
    PdfColor get _baseTextColor => baseColor.isLight ? _lightColor : _darkColor;
    Uint8List? _logo;
    String? _bgShape;*/
}
