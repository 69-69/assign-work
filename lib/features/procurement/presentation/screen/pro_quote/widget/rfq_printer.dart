import 'dart:typed_data';

import 'package:assign_erp/core/constants/app_drop_options.dart';
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
  final RequestForQuote quote;

  RFQPrinter({required this.quote, required this.supplier});

  Future<void> printRFQ() async {
    Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async =>
          await _generatePdf(format: PdfPageFormat.a4),
    );
  }

  List<PrintItem> _buildLineItems() {
    final currencySign = getCurrencySign(quote.currency);

    return quote.lineItems.asMap().entries.map((entry) {
      // final index = entry.key;
      final item = entry.value;

      return PrintItem(
        currencySign: currencySign,
        itemName: item.itemName,
        quantity: item.quantity,
        discount: item.discount,
        unitPrice: item.unitPrice,
        taxAmount: item.taxAmount,
        paymentTerms: quote.paymentTerm,
        taxNames: item.taxNames.toUpperAll,
        validityDate: quote.getDeadlineDate,
      );
    }).toList();
  }

  Future<Uint8List> _generatePdf({
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    List<PrintItem> lineItems = _buildLineItems();

    SupplierContactPerson? contactPerson = supplier.contactPersons
        .firstWhereOrNull((i) => i.id == quote.supplierRepId);
    // prettyPrint('supplier.contactPersons', '$contactPerson');

    final rfq = _RFQPdfBuilder(
      rfqNumber: quote.rfqNumber,
      items: lineItems,
      supplier: supplier,
      contactPerson: contactPerson,
      validityDate: quote.getDeadlineDate,
      deliveryDate: quote.getDeliveryDate,
      altDeliveryAddress: quote.deliveryAddress,
    );

    // Now you can use the `rfq` object as needed, e.g., to print or display it
    return await rfq.build(format);
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

  final List<PrintItem> items;
  final String rfqNumber;
  final Supplier supplier;
  final SupplierContactPerson? contactPerson;
  final String? deliveryDate;
  final String? validityDate;
  final String? altDeliveryAddress;

  String get _rfqTitle => 'Request For Quotation';

  late final PrintPDFConfig _pdfColors;
  late final IssuerCompany _company;

  /// Generate PDF-Doc [build]
  Future<Uint8List> build(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();
    _pdfColors = await PrintPDFConfig.create();
    _company = _pdfColors.company;

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
          pw.SizedBox(height: 20),
          _buildItemTable(context),
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

  /// PDF-Doc Header [_buildPdfHeader]
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
            _buildText(
              'Supplier:',
              style: pw.TextStyle(
                color: _pdfColors.headerColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            _buildText(
              supplier.name.toTitle,
              textAlign: pw.TextAlign.start,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
            ),
            pw.SizedBox(height: 2),
            _buildText(
              supplier.address.toSentence,
              textAlign: pw.TextAlign.start,
            ),
            pw.SizedBox(height: 2),
            _buildText('Tel: ${supplier.phone}', textAlign: pw.TextAlign.start),
            pw.SizedBox(height: 2),
            _buildText(
              'Email:  ${supplier.email.toLowerAll}',
              textAlign: pw.TextAlign.start,
            ),
            pw.SizedBox(height: 10),
            pw.RichText(
              softWrap: true,
              textAlign: pw.TextAlign.start,
              text: pw.TextSpan(
                text: 'Contact Person: ',
                style: pw.TextStyle(
                  color: _pdfColors.footerColor,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  _buildTextSpan(
                    '\n${contactPerson?.name.toTitle ?? 'N/A'} - ${contactPerson?.position.toTitle ?? ''}\n',
                  ),
                  _buildTextSpan('Phone: ${contactPerson?.phone ?? 'N/A'}\n'),
                  _buildTextSpan(
                    'Email: ${contactPerson?.email.toLowerAll ?? 'N/A'}\n',
                  ),
                  _buildTextSpan(
                    'Department: ${contactPerson?.department.toTitle ?? 'N/A'}\n',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ship-To info: name, email, phone, address [_buildShipToInfo]
  pw.Container _buildShipToInfo() {
    return pw.Container(
      alignment: pw.Alignment.topRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: const pw.TextStyle(fontSize: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildText(
              'Ship To:',
              textAlign: pw.TextAlign.start,
              style: pw.TextStyle(
                color: _pdfColors.headerColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            _buildText(
              _company.name,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
            ),
            pw.SizedBox(height: 2),
            _buildText((altDeliveryAddress ?? _company.address).toSentence),
            pw.SizedBox(height: 2),
            _buildText('Tel: ${_company.phone}'),
            pw.SizedBox(height: 2),
            _buildText('Fax:  ${_company.fax}'),
            pw.SizedBox(height: 2),
            _buildText('Email:  ${_company.email}'),
          ],
        ),
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

  pw.TextSpan _buildTextSpan(String label, {pw.TextStyle? style}) {
    return pw.TextSpan(
      text: label,
      style:
          style ??
          pw.TextStyle(
            fontWeight: pw.FontWeight.normal,
            color: _pdfColors.blackColor,
            // fontSize: 10,
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
            data: 'Request For Quote #: $rfqNumber',
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
                _buildText(
                  'Delivery: ',
                  style: pw.TextStyle(color: _pdfColors.headerColor),
                ),
                _buildText(
                  deliveryDate ?? '',
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

  /// PDF PO Content: Table-labels & contents [_buildItemTable]
  pw.Widget _buildItemTable(pw.Context context) {
    const tableHeaders = [
      '#',
      'item description',
      'quantity',
      'unit price',
      'discount',
      'tax amount',
      'tax codes',
      'line total',
    ];

    return _buildTableLayout(tableHeaders);
  }

  pw.Table _buildTableLayout(List<String> tableHeaders) {
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
                _buildText(
                  'Buyer Contact:',
                  style: pw.TextStyle(
                    color: hColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                _buildText(
                  '${contactPerson?.name.toTitle ?? 'N/A'} - ${contactPerson?.position.toTitle ?? ''}',
                  textAlign: pw.TextAlign.start,
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    _buildText(
                      'Deadline: ',
                      textAlign: pw.TextAlign.start,
                      style: pw.TextStyle(
                        color: hColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    _buildText(
                      validityDate ?? '',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.Expanded(child: _buildSignatureBlock()),
      ],
    );
  }

  /// Append Signature [_buildSignatureBlock]
  pw.Container _buildSignatureBlock() {
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
            _buildText(
              'Authorized Signatory',
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

  /*final PdfColor baseColor;
    final PdfColor accentColor;
    static const _darkColor = PdfColors.blueGrey800;
    static const _lightColor = PdfColors.white;
    PdfColor get _baseTextColor => baseColor.isLight ? _lightColor : _darkColor;
    Uint8List? _logo;
    String? _bgShape;*/
}
