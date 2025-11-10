import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/constants/tax_mode.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:assign_erp/features/procurement/presentation/screen/widget/rfq_printer.dart';
import 'package:flutter/material.dart';
/*import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';*/

extension RFQDetails on BuildContext {
  Future openRFQDetails({
    required Supplier supplier,
    required RequestForQuote quote,
  }) async => await openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: FormBottomSheet(
      isDetails: true,
      isExpanded: true,
      title: quote.title.toTitle,
      subtitle: quote.rfqNumber.toUpperAll,
      body: _RFQInfoPage(quote: quote, supplier: supplier.name),
      onPrint: () async => await _printRFQ(this, quote, supplier),
    ),
  );

  Future<void> openCompareRFQ({
    required List<RequestForQuote> quotes,
    required List<Supplier> suppliers,
  }) async => await openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: FormBottomSheet(
      isExpanded: true,
      title: 'Compare Suppliers Quotes',
      subtitle: 'AI-powered cost-value analysis',
      body: _CompareTwoRFQ(quotes: quotes, suppliers: suppliers),
    ),
  );

  _printRFQ(BuildContext cxt, quote, supplier) async {
    await cxt.progressBarDialog(
      request: Future.delayed(
        kRProgressDelay,
        () async =>
            await RFQPrinter(quote: quote, supplier: supplier).printRFQ(),
      ),
      onSuccess: (_) => cxt.showAlertOverlay('RFQ successfully created'),
      onError: (e) =>
          cxt.showAlertOverlay('RFQ printout failed', bgColor: kDangerColor),
    );
  }
}

class _CompareTwoRFQ extends StatefulWidget {
  final List<RequestForQuote> _quotes;
  final List<Supplier> _suppliers;

  const _CompareTwoRFQ({
    required List<RequestForQuote> quotes,
    required List<Supplier> suppliers,
  }) : _quotes = quotes,
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

  @override
  Widget build(BuildContext context) {
    final isTwoQuotes = widget._quotes.length == 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        const dragHandleWidth = 18.0;
        // Reduce the total width by the drag handle width
        final totalWidth =
            constraints.maxWidth - (isTwoQuotes ? dragHandleWidth : 0);

        final firstPanelWidth = totalWidth * _firstPanelRatio;
        final secondPanelWidth = totalWidth * (1 - _firstPanelRatio);

        return Row(
          children: [
            SizedBox(width: firstPanelWidth, child: _buildQuote(context, 0)),
            Container(
              width: dragHandleWidth,
              height: context.screenHeight * 0.78,
              color: isHover
                  ? context.outlineColor.toAlpha(0.3)
                  : kTransparentColor,
              child: _buildDragHandle(),
            ),
            SizedBox(width: secondPanelWidth, child: _buildQuote(context, 1)),
          ],
        );
      },
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
          size: 18,
          color: kGrayBlueColor,
          semanticLabel: 'Resize',
        ),
      ),
    );
  }

  /// Build single quote widget
  Widget _buildQuote(BuildContext context, int index) {
    final quote = widget._quotes[index];
    final supplier = widget._suppliers[index];
    final maxNetTotal = widget._quotes
        .map((q) => q.netTotal)
        .reduce((a, b) => a > b ? a : b);

    final rowColor = (quote.netTotal == maxNetTotal)
        ? kWarningColor
        : kSuccessColor;
    final icon = (quote.netTotal == maxNetTotal)
        ? Icons.warning_amber_rounded
        : Icons.check_circle;
    final currencySign = getCurrencySign(quote.currency);
    final adjective = (quote.netTotal == maxNetTotal) ? 'Worst' : 'Best';
    final textColor = (quote.netTotal == maxNetTotal)
        ? kDarkWarningColor
        : kDarkSuccessColor;

    return _buildBody(
      rowColor,
      adjective,
      currencySign,
      quote,
      icon,
      supplier,
      textColor,
    );
  }

  Container _buildBody(
    Color rowColor,
    String adjective,
    String? currencySign,
    RequestForQuote quote,
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
                    'AI: $adjective choice based on price ($currencySign${quote.netTotal})',
                child: Icon(icon, color: rowColor),
              ),
            ),
            _RFQInfoPage(
              quote: quote,
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
  final RequestForQuote? _quote;
  final Color? _textColor;

  const _RFQInfoPage({
    RequestForQuote? quote,
    String supplier = '',
    Color? textColor,
  }) : _quote = quote,
       _supplier = supplier,
       _textColor = textColor;

  List<RFQLineItem> get _items => _quote?.lineItems ?? [];

  double get _subtotal => _quote?.subTotal ?? 0.0;

  double get _totalTax => _quote?.taxAmount ?? 0.0;

  double get _totalDiscount => _quote?.discountAmount ?? 0.0;

  double get _grandTotal => _quote?.netTotal ?? 0.0;

  TaxMode? get _taxMode => _quote?.taxMode;

  bool get _isPerLineTax => (_taxMode?.isPerLineTax ?? false);

  String? get _currencySign => getCurrencySign(_quote?.currency ?? ghanaCedis);

  String? get _updatedBy =>
      _quote!.updatedBy.isNullOrEmpty ? 'N/A' : _quote.updatedBy;

  String? get _createdBy =>
      _quote!.createdBy.isNullOrEmpty ? 'N/A' : _quote.createdBy;

  @override
  Widget build(BuildContext context) {
    if (_quote == null) {
      return const Center(child: Text("No RFQ data available."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildBody(context), _buildFooter(context)],
    );
  }

  _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),

        /// Table Headers
        Align(
          alignment: Alignment.center,
          child: Text(
            'Line Items (${_items.length})',
            style: context.textTheme.titleLarge?.copyWith(
              color: _textColor ?? kSuccessColor,
            ),
          ),
        ),
        HorizontalDivider(),

        /// Table Headers
        _buildItemTableHeader(context),

        /// Item Rows: generate index too
        /// ...items.map((item, index) => _buildItemRow(item, index)),
        ..._items.asMap().entries.map(
          (entry) => _buildItemRow(entry.value, entry.key),
        ),

        HorizontalDivider(),
        const SizedBox(height: 12),

        AdaptiveLayout(
          children: [_buildLeftSummary(context), _buildRightSummary(context)],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  _buildInfoRow(
    BuildContext context, {
    String title = '',
    String value = '',
    String separator = ': ',
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          text: '$title$separator',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: _textColor ?? context.secondaryColor,
          ),
          children: [
            TextSpan(
              text: value,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _buildItem(String text, {int? flex, bool isBold = true}) => Expanded(
    flex: flex ?? 1,
    child: Text(
      text,
      textAlign: flex == null ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        overflow: TextOverflow.ellipsis,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );

  Widget _buildHeader(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Request for Quotation (RFQ)',
          style: context.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          title: 'RFQ #',
          value: _quote?.rfqNumber ?? 'N/A',
        ),
        _buildInfoRow(
          context,
          title: 'Store ID',
          value: _quote?.storeNumber.toUpperAll ?? 'N/A',
        ),
        _buildInfoRow(
          context,
          title: 'Status',
          value: _quote?.status.toSentence ?? 'N/A',
        ),
        if (_quote?.department.isNotEmpty ?? false)
          _buildInfoRow(
            context,
            title: 'Department',
            value: _quote!.department.toTitle,
          ),
        if (_quote?.taxMode.getValue.isNotEmpty ?? false)
          _buildInfoRow(
            context,
            title: 'Tax Mode',
            value: (_taxMode?.getValue.separateWord).toTitle,
          ),
        _buildInfoRow(context, title: 'Vendor', value: _supplier.toUpperAll),
      ],
    );
  }

  Widget _buildItemTableHeader(BuildContext context) {
    return Container(
      color: context.primaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildItem('#', flex: 1),
          _buildItem('Item', flex: 2),
          _buildItem('Qty'),
          _buildItem('Unit Price'),
          _buildItem('Discount'),
          if (_isPerLineTax) ...[
            // _buildItem('Tax Rate %'),
            _buildItem('Tax Amount'),
            _buildItem('Tax Codes'),
          ],
          _buildItem('Line Total'),
        ],
      ),
    );
  }

  Widget _buildItemRow(RFQLineItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildItem('${index + 1}', flex: 1, isBold: false),
          _buildItem(item.itemName.toTitle, flex: 2, isBold: false),
          _buildItem('${item.quantity}', isBold: false),

          _buildItem(
            '$_currencySign${item.unitPrice.toCurrency}',
            isBold: false,
          ),
          _buildItem(
            '-$_currencySign${item.discountAmount.toCurrency}',
            isBold: false,
          ),

          if (_isPerLineTax) ...[
            _buildItem(
              '$_currencySign${item.taxAmount.toCurrency}',
              isBold: false,
            ),
            _buildItem(item.taxNames.toUpperAll, isBold: false),
          ],
          _buildItem(
            '$_currencySign${item.perLineTotal.toCurrency}',
            isBold: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSummary(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context,
            title: 'Deadline',
            value: _quote!.getDeadlineDate,
          ),
          _buildInfoRow(
            context,
            title: 'Delivery',

            value: _quote.getDeliveryDate,
          ),
          if (!_isPerLineTax) ...{
            _buildInfoRow(
              context,
              title: 'Applied Taxes',

              value: _quote.lineItems.first.taxNames.toUpperAll,
            ),
          },
          if (_quote.deliveryAddress?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              separator: ':\n',
              title: 'Delivery Address',

              value: _quote.deliveryAddress.toSentence,
            ),
          ],
          if (_quote.notes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              separator: ':\n',
              title: 'Additional Notes',
              value: _quote.notes.toSentence,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRightSummary(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildInfoRow(
            context,
            title: 'Subtotal',
            value: '$_currencySign${_subtotal.toCurrency}',
          ),
          _buildInfoRow(
            context,
            title: 'Discount',
            value: '-$_currencySign${_totalDiscount.toCurrency}',
          ),
          _buildInfoRow(
            context,
            title: 'Tax',
            value: '$_currencySign${_totalTax.toCurrency}',
          ),
          const SizedBox(height: 8),
          Text(
            'Grand Total: $_currencySign${_grandTotal.toCurrency}',
            style: context.textTheme.titleLarge?.copyWith(color: kDangerColor),
          ),
        ],
      ),
    );
  }

  Container _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: context.secondaryContainerColor,
      child: AdaptiveLayout(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoRow(
            context,
            title: 'Created',
            value: '${_quote?.getCreatedAt} - By: [ ${_createdBy.toTitle} ]',
          ),
          _buildInfoRow(
            context,
            title: 'Last Updated',
            value: '${_quote!.getUpdatedAt} - By: [ ${_updatedBy.toTitle} ]',
          ),
        ],
      ),
    );
  }
}

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
          pw.Text('RFQ #: RFQ-2025-0098'),
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
