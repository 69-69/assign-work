import 'dart:typed_data';

import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/printout_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Printout for Purchase Requisition
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
      requestedBy: employee,
      purpose: req.purpose,
      prNumber: req.prNumber,
      status: req.getPRStatus,
      priority: req.getPriority,
      storeNumber: req.storeNumber,
      requestDate: req.getRequestDate,
      expectedDate: req.getExpectedDate,
      departmentCode: req.departmentCode,
      approvedBy: history.$1,
      approvedDate: history.$2,
    );

    // Now you can use the `pr` object as needed, e.g., to print or display it
    return await pr.build(format);
  }

  /// Get the last approved PR entry and the date it was approved
  (String?, String?) _prHistory(PurchaseRequisition req) {
    // Find the most recent approved PR entry
    final lastApproved = req.history.lastWhere(
      (h) => h.getAction.toLowerAll == AuditAction.approved.getLabel.toLowerAll,
      orElse: () => AuditLog.empty,
    );

    // If none found, return null for both
    if (lastApproved.isEmpty) return (null, null);

    return (lastApproved.actionBy, lastApproved.getActionAt);
  }
}

/// Print Purchase Requisition Item
class _PrintPRItem {
  const _PrintPRItem({
    required this.itemName,
    required this.quantity,
    required this.category,
    required this.unitOfMeasure,
    required this.notes,
  });

  final String itemName;
  final double quantity;
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
    return req.lineItems
        .map(
          (item) => _PrintPRItem(
            itemName: item.description,
            quantity: item.quantity,
            category: item.getCategory,
            unitOfMeasure: item.getUnitOfMeasure,
            notes: item.notes,
          ),
        )
        .toList();
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

/// Purchase Requisition PDF Builder
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
    required this.expectedDate,
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
  final String expectedDate;
  final List<_PrintPRItem> items;

  String get _prTitle => 'Purchase Requisition';

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
    await _addPRPage(doc, pageFormat, _pdfColors.footerColor);

    // Return the PDF file content
    return doc.save();
  }

  /// PDF-Generator Theme
  Future<pw.PageTheme> _buildTheme(PdfPageFormat pageFormat) async {
    return await FontManager.loadTheme(
      pageFormat,
      buildBackground: (context) =>
          _pdfColors.isDenseLayout ? _buildFooterBg() : pw.SizedBox.shrink(),
    );
  }

  /// RFQ: First page to the PDF
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
          // _computerGenerated(),
        ],
      ),
    );
  }

  /// Purpose / Reason for PR
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
            fontSize: _tableFontSize,
            color: _pdfColors.headerColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        _buildText(
          purpose.toSentence,
          style: pw.TextStyle(fontSize: _tableFontSize),
        ),
      ],
    );
  }

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

  /// Requester Info: name, department, role
  pw.Container _requestByInfo() {
    final reqList = [
      'Requested By:',
      requestedBy.fullName.toTitle,
      requestedBy.departmentCode.toUpperAll,
      requestedBy.role.toTitle,
    ];

    return pw.Container(
      alignment: pw.Alignment.topRight,
      child: pw.DefaultTextStyle(
        softWrap: false,
        style: pw.TextStyle(fontSize: _bodyFontSize),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: _buildSection(reqList).toList(),
        ),
      ),
    );
  }

  /// PR Class: status, priority
  pw.Container _buildPRClass() {
    final classList = [
      ('Priority', priority.toUpperAll),
      ('Status', status.toTitle),
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
            _buildText(
              'PR Classification:',
              textAlign: pw.TextAlign.start,
              style: pw.TextStyle(color: _pdfColors.headerColor),
            ),
            ..._buildSubSection(classList),
          ],
        ),
      ),
    );
  }

  // Helper function to create the styled text
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

  // Helper function to create rich text for sub items (e.g. Tel, Email)
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

  /// PDF-Doc Footer
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
            data: '$_prTitle #: $prNumber',
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

  /// PDF-Doc Footer background-Img
  pw.FullPage _buildFooterBg() => pw.FullPage(
    ignoreMargins: true,
    child: pw.SvgImage(svg: _pdfColors.footerImg),
  );

  /// Company's info: name, email, phone, address & PO Title & Number
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

  /// PR number, Request & Needed date
  _buildPRDates() {
    final topList = [
      ('Store ID', storeNumber.toUpperAll),
      ('PR#', prNumber.toUpperAll),
      ('Date', requestDate),
      ('Expected By', expectedDate),
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
              _prTitle.toUpperAll,
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

  /// PDF PO Content: Table-labels & contents
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
      headers: tableHeaders,
      data: _list(tableHeaders),
    );
  }

  List<List<String>> _list(List<String> tableHeaders) {
    final headerLength = tableHeaders.length;

    return items.map((i) => i.itemAsList.take(headerLength).toList()).toList();
  }

  /// Approved & Signature
  pw.Widget _buildApprovedSignature(pw.Context context) {
    var hColor = _pdfColors.headerColor;
    var fColor = _pdfColors.footerColor;

    return pw.Row(
      children: [
        _buildApprovedBy(hColor),
        pw.Expanded(child: _buildSignatureBlock(fColor)),
      ],
    );
  }

  /// Approved By: name, date & Signature
  pw.Expanded _buildApprovedBy(PdfColor hColor) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildText(
            'Approved By:',
            style: pw.TextStyle(
              color: hColor,
              fontSize: _bodyFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          _buildText(
            approvedBy?.toTitle ?? 'N/A',
            textAlign: pw.TextAlign.start,
            style: pw.TextStyle(fontSize: _bodyFontSize),
          ),
          pw.SizedBox(height: 2),
          _buildText(
            approvedDate ?? 'N/A',
            textAlign: pw.TextAlign.start,
            style: pw.TextStyle(fontSize: _bodyFontSize),
          ),
        ],
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
