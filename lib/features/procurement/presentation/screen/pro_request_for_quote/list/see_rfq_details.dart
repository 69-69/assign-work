import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
import 'package:assign_erp/core/widgets/see_detail/see_details.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/widget/rfq_printer.dart';
import 'package:flutter/material.dart';
/*import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';*/

extension RFQDetails on BuildContext {
  Future openRFQDetails({
    required Supplier supplier,
    required RequestForQuote rfq,
    required Function(bool) onPrint,
    // required ProRequestForQuoteBloc bloc,
  }) async => await openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetailMode: true,
      title: 'Request for Quotation (RFQ)',
      subtitle: '${rfq.rfqNumber.toUpperAll} (${rfq.lineItems.first.getType})',
      secondaryWidget: _showHistory(rfq),
      body: _RFQInfoPage(rfq: rfq, supplier: supplier.name),
      onPrint: () async => await _printRFQ(supplier, onPrint, rfq),
    ),
  );

  Future<void> openCompareRFQ({
    required List<RequestForQuote> rfqs,
    required List<Supplier> suppliers,
  }) async => await openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetailMode: true,
      title: 'Compare Suppliers RFQ',
      subtitle: 'AI-powered cost-value analysis',
      body: _CompareTwoRFQ(rfqs: rfqs, suppliers: suppliers),
    ),
  );

  _printRFQ(
    Supplier supplier,
    Function(bool) onPrint,
    RequestForQuote rfq,
    // ProRequestForQuoteBloc bloc,
  ) async {
    await progressBarDialog(
      request: Future.delayed(kRProgressDelay, () async {
        await RFQPrinter(rfq: rfq, supplier: supplier).printRFQ();
        onPrint(true);
        // bloc.add(_updateHistory(rfq));
      }),
      onSuccess: (_) => showAlertOverlay('RFQ printout successful'),
      onError: (e) =>
          showAlertOverlay('RFQ printout failed', bgColor: kDangerColor),
    );
  }

  Widget _showHistory(RequestForQuote? rfq) {
    return iconButton(
      Icons.history,
      iconColor: kPrimaryAccentColor,
      bgColor: kPrimaryAccentColor.toAlpha(0.1),
      // borderColor: kPrimaryAccentColor.toAlpha(0.1),
      tooltip: 'View RFQ History',
      onPressed: () async => await _onOpenHistory(rfq),
    );
  }

  Future<void> _onOpenHistory(RequestForQuote? rfq) async {
    if (rfq == null) return;

    await showHistoryBottomSheet<AuditLog>(
      title: 'Workflow History',
      columnLabels: AuditLog.dataTableHeader,
      items: rfq.history, // list of RFQ history
      rowBuilder: (entry) {
        return DataRow(
          cells: entry.itemAsList.map((cell) => DataCell(Text(cell))).toList(),
        );
      },
    );
  }

  /* Audit Log Entry (Tracking actions)
  AuditProcurement<RequestForQuote> _updateHistory(RequestForQuote rfq) {
    return AuditProcurement<RequestForQuote>(
      documentId: rfq.id,
      log: AuditLog.logScaffold(
        oldLogs: rfq.history,
        newLog: AuditLog(
          action: AuditAction.printed,
          actionBy: employee!.employeeId,
          statusAfterAction: rfq.getRFQStatus,
        ),
      ),
    );
  }*/
}

class _CompareTwoRFQ extends StatefulWidget {
  final List<RequestForQuote> _rfqs;
  final List<Supplier> _suppliers;

  const _CompareTwoRFQ({
    required List<RequestForQuote> rfqs,
    required List<Supplier> suppliers,
  }) : _rfqs = rfqs,
       _suppliers = suppliers;

  @override
  State<_CompareTwoRFQ> createState() => _CompareTwoRFQState();
}

class _CompareTwoRFQState extends State<_CompareTwoRFQ> {
  // Width ratio between first and second panel (0.0 - 1.0)
  double _firstPanelRatio = 0.5;
  final double _minRatio = 0.2;
  final double _maxRatio = 0.8;
  bool isHover = false;
  final _dragHandleWidth = 16.0;

  @override
  Widget build(BuildContext context) {
    final isTwoRFQs = widget._rfqs.length == 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = _isSmallLayout(context);
        final totalWidth = _calculateTotalWidth(constraints, isTwoRFQs);
        final (firstPanelWidth, secondPanelWidth) = _calculatePanelWidths(
          isSmall,
          totalWidth,
          constraints,
        );

        final children = _buildPanels(
          context,
          isSmall,
          firstPanelWidth,
          secondPanelWidth,
        );

        return isSmall ? Column(children: children) : Row(children: children);
      },
    );
  }

  bool _isSmallLayout(BuildContext context) {
    return context.isMobile || (context.isTablet && context.isPortraitMode);
  }

  double _calculateTotalWidth(BoxConstraints constraints, bool isTwoRFQs) {
    return constraints.maxWidth - (isTwoRFQs ? _dragHandleWidth : 0);
  }

  (double, double) _calculatePanelWidths(
    bool isSmall,
    double totalWidth,
    BoxConstraints constraints,
  ) {
    if (isSmall) {
      return (constraints.maxWidth, constraints.maxWidth);
    }
    return (totalWidth * _firstPanelRatio, totalWidth * (1 - _firstPanelRatio));
  }

  List<Widget> _buildPanels(
    BuildContext context,
    bool isSmall,
    double firstPanelWidth,
    double secondPanelWidth,
  ) {
    return [
      _buildPanel(
        context: context,
        width: firstPanelWidth,
        index: 0,
        padding: isHover ? const EdgeInsets.only(right: 4) : null,
      ),
      isSmall
          ? SizedBox(height: _dragHandleWidth)
          : _buildDragHandleContainer(context),
      _buildPanel(
        context: context,
        width: secondPanelWidth,
        index: 1,
        padding: isHover ? const EdgeInsets.only(left: 4) : null,
      ),
    ];
  }

  Widget _buildPanel({
    required BuildContext context,
    required double width,
    required int index,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding,
      width: width,
      child: _buildRFQ(context, index),
    );
  }

  Widget _buildDragHandleContainer(BuildContext context) {
    return Container(
      width: _dragHandleWidth,
      height: context.screenHeight * 0.78,
      color: isHover ? context.outlineColor.toAlpha(0.2) : kTransparentColor,
      child: _buildDragHandle(),
    );
  }

  /// Drag handle to resize
  Widget _buildDragHandle() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        setState(() {
          _firstPanelRatio += details.delta.dx / context.size!.width;
          _firstPanelRatio = _firstPanelRatio.clamp(_minRatio, _maxRatio);
          isHover = true;
        });
      },
      onHorizontalDragEnd: (_) => setState(() => isHover = false),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Icon(
          Icons.drag_indicator,
          size: _dragHandleWidth,
          color: context.onSurfaceColor,
          semanticLabel: 'Resize',
        ),
      ),
    );
  }

  /// Build single quote widget
  Widget _buildRFQ(BuildContext context, int index) {
    final rfq = widget._rfqs[index];
    final supplier = widget._suppliers[index];
    final maxNetTotal = widget._rfqs
        .map((q) => q.netTotal)
        .reduce((a, b) => a > b ? a : b);

    final rowColor = (rfq.netTotal == maxNetTotal)
        ? kWarningColor
        : kSuccessColor;
    final icon = (rfq.netTotal == maxNetTotal)
        ? Icons.warning_amber_rounded
        : Icons.check_circle;
    final currencySign = getCurrencySign(rfq.currencyCode);
    final adjective = (rfq.netTotal == maxNetTotal) ? 'Worst' : 'Best';
    final textColor = (rfq.netTotal == maxNetTotal)
        ? kDarkWarningColor
        : kDarkSuccessColor;

    return _buildBody(
      rowColor,
      adjective,
      currencySign,
      rfq,
      icon,
      supplier,
      textColor,
    );
  }

  Container _buildBody(
    Color rowColor,
    String adjective,
    String? currencySign,
    RequestForQuote rfq,
    IconData icon,
    Supplier supplier,
    Color textColor,
  ) {
    final radius = BorderRadius.circular(borderRadius);
    final bSide = BorderSide(color: rowColor.toAlpha(0.6), width: 0.6);

    return Container(
      padding: EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border(bottom: bSide, right: bSide, left: bSide, top: bSide),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
        decoration: BoxDecoration(
          color: rowColor.toAlpha(0.06),
          borderRadius: radius,
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Tooltip(
                message:
                    'AI: $adjective choice based on price ($currencySign${rfq.netTotal})',
                child: Icon(icon, color: rowColor),
              ),
            ),
            _RFQInfoPage(
              rfq: rfq,
              supplier: supplier.name,
              textColor: textColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _RFQInfoPage extends StatelessWidget {
  final String _supplier;
  final RequestForQuote? _rfq;
  final Color? _textColor;

  const _RFQInfoPage({
    RequestForQuote? rfq,
    String supplier = '',
    Color? textColor,
  }) : _rfq = rfq,
       _supplier = supplier,
       _textColor = textColor;

  List<LineItem> get _items => _rfq?.lineItems ?? [];

  String? get _currencySign =>
      getCurrencySign(_rfq?.currencyCode ?? ghanaCedis);

  SummaryItem get _approval {
    ApprovalInfo? item = _rfq?.getApproval;

    return (
      title: 'Approved By',
      value:
          '\n${item?.by ?? 'Not yet approved'}\n${item?.at ?? '-----------------'}',
    );
  }

  List<SummaryItem> get _leftSummaryItems => [
    (title: 'Currency', value: '${_rfq?.currencyCode} ($_currencySign)'),
    (title: 'Deadline', value: _rfq?.getDeadlineDate ?? 'N/A'),
    (title: 'Delivery', value: _rfq?.getExpectedDate ?? 'N/A'),
  ];

  @override
  Widget build(BuildContext context) {
    if (_rfq == null) {
      return const Center(child: Text("No RFQ data available."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBody(context),
        DetailsFooter(
          created: (by: _rfq.createdBy, at: _rfq.getCreatedAt),
          updated: (by: _rfq.updatedBy, at: _rfq.getUpdatedAt),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        SortableHistoryTable<LineItem>(
          title: 'Line Items (${_items.length})',
          // headingRowColor: context.primaryContainer,
          columnLabels: _items.first.dataTableHeader(false),
          items: _items, // list of Quotes
          rowBuilder: (entry) {
            return DataRow(
              cells: entry
                  .itemAsList(false)
                  .map((cell) => DataCell(Text(cell)))
                  .toList(),
            );
          },
          sortAccessors: [
            (entry) => entry.description,
            (entry) => entry.quantity,
            (entry) => entry.unitPrice,
          ],
        ),

        const SizedBox(height: 12),
        AdaptiveLayout(
          children: [
            DetailsSummary(
              textColor: _textColor,
              items: _leftSummaryItems,
              alignment: Alignment.centerLeft,
            ),
            DetailsSummary(textColor: kDangerColor, items: [_approval]),
          ],
        ),
        const SizedBox(height: 20),
        _addressAndNotes(context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Build the list of header entries first
    List<SummaryItem> headerItems = [
      (title: 'RFQ#', value: _rfq?.rfqNumber ?? 'N/A'),
      (title: 'Store ID', value: _rfq?.storeNumber.toUpperAll ?? 'N/A'),
      (title: 'Status', value: _rfq?.getRFQStatus.toSentence ?? 'N/A'),
      if (_rfq?.departmentCode.isNotEmpty ?? false) ...{
        (title: 'Department', value: _rfq!.departmentCode.toTitle),
      },
      (title: 'Supplier', value: _supplier.toUpperAll),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_rfq?.title.toTitle.isNotEmpty ?? false) ...{
          Text(_rfq!.title.toTitle, style: context.textTheme.headlineSmall),
          const SizedBox(height: 8),
        },
        DetailsSummary(
          textColor: _textColor,
          items: headerItems,
          alignment: Alignment.topLeft,
        ),
      ],
    );
  }

  Widget _addressAndNotes(BuildContext context) {
    List<SummaryItem> items = [
      (title: 'Additional Notes', value: _rfq?.notes.toSentence ?? 'N/A'),
      (
        title: 'Shipping Address',
        value: _rfq?.shippingAddress?.street.toSentence ?? 'N/A',
      ),
    ];

    return AdaptiveLayout(
      children: [
        ...items.map(
          (item) => detailsRow(
            context,
            isReadMore: true,
            title: item.title,
            value: item.value,
            textColor: _textColor,
          ),
        ),
      ],
    );
  }
}

/* Expanded _buildItem(String text, {bool isBold = true}) => Expanded(
    child: Text(
      text,
      style: TextStyle(
        overflow: TextOverflow.ellipsis,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
   Widget _buildItemTableHeader(BuildContext context) {
    final headerItems = [
      '#',
      'Item',
      'Qty',
      'Unit Price',
      'Discount',
      if (_isPerLineTax) ...[
        // 'Tax Rate %',
        'Tax Amount',
        'Tax Codes',
      ],
      'Line Total',
    ];

    return Container(
      color: context.primaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: headerItems.map((item) => _buildItem(item)).toList(),
      ),
    );
  }

  Widget _buildItemRow(RFQLineItem item, int index) {
    List rowItems = [
      '${index + 1}',
      (item.itemName.toTitle),
      '${item.quantity}',
      '$_currencySign${item.unitPrice.toCurrency}',
      '$_currencySign${item.discountAmount.toCurrency}',
      if (_isPerLineTax) ...[
        '$_currencySign${item.taxAmount.toCurrency}',
        item.taxNames.toUpperAll,
      ],
      '$_currencySign${item.perLineTotal.toCurrency}',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: rowItems
            .map((item) => _buildItem(item, isBold: false))
            .toList(),
      ),
    );
  }*/

/*void _generatePdf() async {
    final List<Map<String, dynamic>> items = [
      {
        'description': 'Hotel Booking',
        'qty': 1,
        'unitPrice': 1000.0,
        'taxAmount': 250.0,
        'Taxes': ['VAT', 'Tourism', 'Service'],
      },
      {
        'description': 'Consulting Fee',
        'qty': 1,
        'unitPrice': 500.0,
        'taxAmount': 90.0,
        'Taxes': ['VAT', 'Service'],
      },
    ];

    final pdf = pw.Document();
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
    );

    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + item['qty'] * item['unitPrice'],
    );
    final totalTax = items.fold<double>(
      0,
      (sum, item) => sum + item['taxAmount'],
    );
    final grandTotal = subtotal + totalTax;

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        build: (context) => [
          // Header
          pw.Text(
            'Request for Quotation (RFQ)',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text('RFQ#: RFQ-2025-0098'),
          pw.Text('Date: 2025-08-30'),
          pw.Text('Vendor: ABC Supplies Ltd.'),
          pw.SizedBox(height: 10),

          // Contact and Delivery Info
          pw.Text(
            'Delivery Address:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('123 Procurement Lane, Business City, ZIP 10101'),
          pw.SizedBox(height: 5),
          pw.Text(
            'Contact Person:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('John Doe - Procurement Officer'),
          pw.Text('Phone: +1 555 123 4567'),
          pw.Text('Email: john.doe@example.com'),
          pw.SizedBox(height: 20),

          // Table
          pw.TableHelper.fromTextArray(
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: [
              'Item',
              'Qty',
              'Unit Price',
              'Tax',
              'Tax Types',
              'Line Total',
            ],
            data: items.map((item) {
              final lineTotal =
                  item['qty'] * item['unitPrice'] + item['taxAmount'];
              return [
                item['description'],
                item['qty'].toString(),
                '\$${item['unitPrice'].toCurrency}',
                '\$${item['taxAmount'].toCurrency}',
                item['Taxes'].join(', '),
                '\$${lineTotal.toCurrency}',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 20),

          // Summary
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Subtotal: \$${subtotal.toCurrency}'),
                  pw.Text('Total Tax: \$${totalTax.toCurrency}'),
                  pw.Text(
                    'Grand Total: \$${grandTotal.toCurrency}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 40),

          // Signature Section
          pw.Text(
            'Signatures',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 20),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(height: 1, width: 150, color: PdfColors.black),
                  pw.SizedBox(height: 5),
                  pw.Text('Vendor Signature'),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(height: 1, width: 150, color: PdfColors.black),
                  pw.SizedBox(height: 5),
                  pw.Text('Authorized Person'),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  class _CompareTwoRFQ2 extends StatelessWidget {
  final List<RequestForQuote> _quotes;
  final List<Supplier> _suppliers;

  const _CompareTwoRFQ2({
    required List<RequestForQuote> quotes,
    required List<Supplier> suppliers,
  }) : _quotes = quotes,
       _suppliers = suppliers;

  double get _maxNetTotal =>
      _quotes.map((q) => q.netTotal).reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      children: _quotes.asMap().entries.map((q) {
        final index = q.key;
        final quote = q.value;

        // The Quote with cheaper price will be highlighted Green background
        Color rowColor = (quote.netTotal == _maxNetTotal)
            ? kWarningColor
            : kSuccessColor;
        IconData icon = (quote.netTotal == _maxNetTotal)
            ? Icons.warning_amber_rounded
            : Icons.check_circle;
        final currencySign = getCurrencySign(quote.currency);
        final adjective = (quote.netTotal == _maxNetTotal) ? 'Worst' : 'Best';
        final textColor = (quote.netTotal == _maxNetTotal)
            ? kDarkWarningColor
            : kDarkSuccessColor;

        return Container(
          padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
          decoration: BoxDecoration(
            color: rowColor.toAlpha(0.1),
            border: Border(
              bottom: BorderSide(color: rowColor, width: 10),
              // right: _borderSide(index, 0, rowColor),
              // left: _borderSide(index, 1, rowColor),
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Tooltip(
                  message:
                      'AI: $adjective choice based on price ($currencySign${quote.netTotal})',
                  child: Icon(icon, color: rowColor),
                ),
              ),
              _RFQInfoPage(
                quote: quote,
                supplier: _suppliers[index].name,
                textColor: textColor,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // BorderSide _borderSide(int i, int count, Color color) =>
  //     i == count ? BorderSide(color: color, width: 0.2) : BorderSide.none;
}*/
