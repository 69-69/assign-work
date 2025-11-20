import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/printout_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Printout for Purchase Requisition [PRPrinter]
class PRPrinter {
  final Employee employee;
  final PurchaseRequisition requisite;

  PRPrinter({required this.requisite, required this.employee});

  Future<void> printPR() async {
    Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async =>
          await _generatePdf(format: PdfPageFormat.a4),
    );
  }

  Future<Uint8List> _generatePdf({
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final req = requisite;
    List<_PrintPRItem> lineItems = _PrintPRItem.fromPR(req);

    final history = _prHistory(req);

    final pr = _PRPdfBuilder(
      items: lineItems,
      status: req.getPRStatus,
      priority: req.getPriority,
      prNumber: req.prNumber,
      departmentCode: req.departmentCode,
      storeNumber: req.storeNumber,
      requestedBy: employee,
      purpose: req.purpose,
      approvedBy: history.$1,
      approvedDate: history.$2,
      requestDate: req.getRequestDate,
      neededByDate: req.getNeededByDate,
    );

    // Now you can use the `pr` object as needed, e.g., to print or display it
    return await pr.build(format);
  }

  /// Get the last approved PR entry and the date it was approved [_prHistory]
  (String?, String?) _prHistory(PurchaseRequisition req) {
    // Find the most recent approved PR entry
    final lastApproved = req.history.lastWhere(
      (h) => h.getAction.toLowerAll == AuditAction.approved.getLabel,
      orElse: () => AuditLog.empty,
    );

    // If none found, return null for both
    if (lastApproved.isEmpty) return (null, null);

    return (lastApproved.performedBy, lastApproved.getPerformedAt);
  }
}

/// Print Purchase Requisition Item [_PrintPRItem]
class _PrintPRItem {
  const _PrintPRItem({
    required this.itemName,
    required this.quantity,
    required this.category,
    required this.unitOfMeasure,
    required this.notes,
  });

  final String itemName;
  final int quantity;
  final String category;
  final String unitOfMeasure;
  final String notes;

  /*String getIndex(String label, int index) {
    final normalized = label.toLowerAll;

    final values = <String, String>{
      '#': '${index + 1}',
      'item': itemName,
      'status': status,
      'priority': priority,
      'qty': quantity.toString(),
      'category': category,
      'UOM': unitOfMeasure,
      'purpose': purpose,
      'request date': requestDate,
      'required date': requiredDate,
      'notes': notes ?? '',
    };

    return values[normalized] ?? 'NA';
  }*/

  /// Convert [PurchaseRequisition] to List<[_PrintPRItem]>
  static List<_PrintPRItem> fromPR(PurchaseRequisition req) {
    return req.lineItems.map((item) {
      return _PrintPRItem(
        itemName: item.itemName,
        quantity: item.quantity,
        category: item.getCategory,
        notes: item.notes,
        unitOfMeasure: item.getUnitOfMeasure,
      );
    }).toList();
  }

  /// For UI Table Content display only
  List<String> get itemAsList => [
    itemName.toTitle,
    quantity.toString(),
    category.toTitle,
    unitOfMeasure.toTitle,
    notes.toSentence,
  ];

  /// For UI Table Header display only
  static List<String> get tableHeaders => [
    'Item',
    'Qty',
    'Category',
    'UOM',
    'Notes',
  ];
}

/// Purchase Requisition PDF Builder [PRPdfBuilder]
class _PRPdfBuilder {
  _PRPdfBuilder({
    required this.status,
    required this.priority,
    required this.items,
    required this.prNumber,
    required this.storeNumber,
    required this.departmentCode,
    required this.requestedBy,
    required this.purpose,
    this.approvedBy,
    this.approvedDate,
    required this.requestDate,
    required this.neededByDate,
  });

  final String status;
  final String priority;
  final String prNumber;
  final String storeNumber;
  final String departmentCode;
  final String purpose;
  final String? approvedBy;
  final String? approvedDate;
  final String requestDate;
  final Employee requestedBy;
  final String neededByDate;
  final List<_PrintPRItem> items;

  String get _prTitle => 'Purchase Requisition';

  late final PrintPDFConfig _pdfColors;
  late final IssuerCompany _company;

  /// Generate PDF-Doc [build]
  Future<Uint8List> build(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();
    _pdfColors = await PrintPDFConfig.create();
    _company = _pdfColors.company;

    // Request For Quotation: Add page to the PDF
    await _addPRPage(doc, pageFormat, _pdfColors.footerColor);

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

  /// RFQ: First page to the PDF [_addPRPage]
  _addPRPage(pw.Document doc, PdfPageFormat pageFormat, PdfColor fColor) async {
    doc.addPage(
      pw.MultiPage(
        pageTheme: await _buildTheme(pageFormat),
        header: _buildPdfHeader,
        footer: _buildPdfFooter,
        build: (context) => [
          pw.Divider(color: fColor, thickness: 0.3, height: 10),
          pw.SizedBox(height: 10),
          _buildItemTable(context),
          _buildPurpose(),
          pw.Divider(color: fColor, thickness: 0.3, height: 20),
          _buildApprovedSignature(context),
          pw.SizedBox(height: 20),
          _computerGenerated(),
        ],
      ),
    );
  }

  /// Purpose / Reason for PR [_buildPurpose]
  pw.Column _buildPurpose() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        pw.SizedBox(height: 5),
        _buildText(
          'Purpose / Reason:',
          textAlign: pw.TextAlign.start,
          style: pw.TextStyle(
            fontSize: 10,
            color: _pdfColors.headerColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        _buildText(purpose.toSentence, style: pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  /// Computer Generate Notice [_computerGenerated]
  pw.Center _computerGenerated() => pw.Center(
    child: pw.Text(
      'Electronic version - $_prTitle',
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontSize: 11),
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
            _requestByInfo(),
            pw.SizedBox(width: 100),

            /// ShipTo Info
            pw.Expanded(child: _buildPRClass()),
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

  /// Requester Info: name, department, role [_requestByInfo]
  pw.Container _requestByInfo() {
    return pw.Container(
      alignment: pw.Alignment.topRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: const pw.TextStyle(fontSize: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildText(
              'Request By:',
              style: pw.TextStyle(
                color: _pdfColors.headerColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            _buildText(
              requestedBy.fullName.toTitle,
              textAlign: pw.TextAlign.start,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
            ),
            pw.SizedBox(height: 2),
            _buildText(
              requestedBy.departmentCode.toUpperAll,
              textAlign: pw.TextAlign.start,
            ),
            pw.SizedBox(height: 2),
            _buildText(requestedBy.role.toTitle, textAlign: pw.TextAlign.start),
          ],
        ),
      ),
    );
  }

  /// PR Class: status, priority [_buildPRClass]
  pw.Container _buildPRClass() {
    return pw.Container(
      alignment: pw.Alignment.topRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildText(
              'PR Classification:',
              textAlign: pw.TextAlign.start,
              style: pw.TextStyle(color: _pdfColors.headerColor),
            ),
            pw.RichText(
              text: pw.TextSpan(
                text: 'Status: ',
                children: [
                  pw.TextSpan(
                    text: status.toTitle,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 2),

            pw.RichText(
              text: pw.TextSpan(
                text: 'Priority: ',
                children: [
                  pw.TextSpan(
                    text: priority.toUpperAll,
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

  pw.Text _buildText(
    String label, {
    pw.TextAlign textAlign = pw.TextAlign.end,
    pw.TextStyle? style,
  }) {
    return pw.Text(label, softWrap: true, textAlign: textAlign, style: style);
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
            data: 'Request For Quote #: $prNumber',
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
        pw.Expanded(child: _buildPRDates()),
      ],
    );
  }

  /// PR number, Request & Needed date [_buildPRDates]
  _buildPRDates() {
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
              _prTitle.toUpperAll,
              style: pw.TextStyle(color: _pdfColors.headerColor, fontSize: 14),
            ),
            pw.SizedBox(height: 3.0),
            pw.RichText(
              text: pw.TextSpan(
                text: 'Store ID: ',
                children: [
                  pw.TextSpan(
                    text: storeNumber.toUpperAll,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 3.0),
            pw.RichText(
              text: pw.TextSpan(
                text: 'PR#: ',
                children: [
                  pw.TextSpan(
                    text: prNumber.toUpperAll,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 3.0),
            pw.RichText(
              text: pw.TextSpan(
                text: 'Date: ',
                children: [
                  pw.TextSpan(
                    text: requestDate,
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
                  'Needed By: ',
                  style: pw.TextStyle(color: _pdfColors.headerColor),
                ),
                _buildText(
                  neededByDate,
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
    List<String> tableHeaders = _PrintPRItem.tableHeaders;

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
      headers: tableHeaders,
      /*List<String>.generate(
        tableHeaders.length,
        (col) => tableHeaders[col].toTitle,
      ),*/
      data: _list(tableHeaders),
    );
  }

  List<List<String>> _list(List<String> tableHeaders) {
    /*return List<List<String>>.generate(
      items.length,
      (row) => List<String>.generate(
        tableHeaders.length,
        (col) => items[row].itemAsList.elementAt(col),
        // (col) => items[row].getIndex(tableHeaders[col], row),
      ),
    );*/
    final headerLength = tableHeaders.length;

    return items.map((i) => i.itemAsList.take(headerLength).toList()).toList();
  }

  /// Approved & Signature [_buildApprovedSignature]
  pw.Widget _buildApprovedSignature(pw.Context context) {
    var hColor = _pdfColors.headerColor;
    var fColor = _pdfColors.footerColor;

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        border: pw.Border.all(color: fColor, width: 0.2),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      alignment: pw.Alignment.bottomRight,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildApprovedBy(hColor),
          pw.Expanded(child: _buildSignatureBlock(fColor)),
        ],
      ),
    );
  }

  /// Approved By: name, date & Signature [_buildApprovedBy]
  pw.Expanded _buildApprovedBy(PdfColor hColor) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildText(
            'Approved By:',
            style: pw.TextStyle(
              color: hColor,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          _buildText(
            approvedBy?.toTitle ?? 'N/A',
            textAlign: pw.TextAlign.start,
            style: pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 2),
          _buildText(
            approvedDate ?? 'N/A',
            textAlign: pw.TextAlign.start,
            style: pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Append Signature [_buildSignatureBlock]
  pw.DefaultTextStyle _buildSignatureBlock(PdfColor fColor) {
    return pw.DefaultTextStyle(
      softWrap: false,
      style: pw.TextStyle(color: fColor, fontSize: 11),
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
              fontSize: 11,
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
