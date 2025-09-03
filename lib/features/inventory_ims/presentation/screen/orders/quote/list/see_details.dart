import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/constants/tax_methods_enum.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/request_for_quotation_model.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

extension RFQDetails on BuildContext {
  Future openSeeDetails({
    String supplier = '',
    required RequestForQuote quote,
  }) => openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: FormBottomSheet(
      isDetails: true,
      title: quote.title.toTitle,
      subtitle: quote.rfqNumber.toUpperAll,
      body: RFQPrintoutPage(quote: quote, supplier: supplier),
      onPrint: () async => _generatePdf(),
    ),
  );

  void _generatePdf() async {
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
}

class RFQPrintoutPage extends StatelessWidget {
  final String supplier;
  final RequestForQuote? quote;

  const RFQPrintoutPage({super.key, this.quote, this.supplier = ''});

  List<RFQLineItem> get _items => quote?.lineItems ?? [];

  double get _subtotal => quote?.subTotal ?? 0.0;
  double get _totalTax => quote?.taxAmount ?? 0.0;
  double get _discount => quote?.discountAmount ?? 0.0;
  double get _grandTotal => quote?.netTotal ?? 0.0;
  TaxMethodToApply? get _taxMethod => quote?.taxMethod;
  bool get _isPerLineTax => (_taxMethod?.isPerLineTax ?? false);

  String? get _currency => getCurrencySign(quote?.currency ?? 'GHC');

  @override
  Widget build(BuildContext context) {
    if (quote == null) {
      return const Center(child: Text("No RFQ data available."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
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
          children: [_buildExtra(context), _buildSummary(context)],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  _buildInfoRow(BuildContext context, {String title = '', String value = ''}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          text: '$title: ',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.secondaryColor,
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
          value: quote?.rfqNumber ?? 'N/A',
        ),
        _buildInfoRow(
          context,
          title: 'Store ID',
          value: quote?.storeNumber.toUpperAll ?? 'N/A',
        ),
        _buildInfoRow(
          context,
          title: 'Status',
          value: quote?.status.toSentence ?? 'N/A',
        ),
        if (quote?.department.isNotEmpty ?? false)
          _buildInfoRow(
            context,
            title: 'Department',
            value: quote!.department.toTitle,
          ),
        if (quote?.taxMethod.label.isNotEmpty ?? false)
          _buildInfoRow(
            context,
            title: 'Tax Method',
            value: (_taxMethod?.label.separateWord).toTitle,
          ),
        _buildInfoRow(context, title: 'Vendor', value: supplier.toUpperAll),
        _buildInfoRow(
          context,
          title: 'Date',
          value: quote?.getCreatedAt ?? 'N/A',
        ),
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
          _buildItem('No. Item', flex: 2),
          _buildItem('Qty'),
          _buildItem('Unit Price'),
          _buildItem('Discount'),
          if (_isPerLineTax) ...[
            // _buildItem('Tax Rate %'),
            _buildItem('Tax Amount'),
            _buildItem('Tax Codes'),
          ],
          _buildItem('Total'),
        ],
      ),
    );
  }

  Widget _buildItemRow(RFQLineItem item, int index) {
    final total = item.subTotal - item.discountAmount + item.taxAmount;

    /*final taxCodes = isPerLineTax ? item.taxCodesList : quote?.taxCodes;
    final taxAmt = (item.taxAmount > 0 ? item.taxAmount : totalTax).toCurrency;*/

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildItem(
            '${index + 1} - ${item.itemName.toTitle}',
            flex: 2,
            isBold: false,
          ),
          _buildItem('${item.quantity}', isBold: false),

          _buildItem('$_currency${item.unitPrice.toCurrency}', isBold: false),
          _buildItem(
            '$_currency${item.discountAmount.toCurrency}',
            isBold: false,
          ),

          if (_isPerLineTax) ...[
            _buildItem('$_currency${item.taxAmount.toCurrency}', isBold: false),
            _buildItem(item.taxNames.toTitle, isBold: false),
          ],
          _buildItem('$_currency${total.toCurrency}', isBold: false),
        ],
      ),
    );
  }

  Widget _buildExtra(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context,
            title: 'Deadline',
            value: quote!.getDeadlineDate,
          ),
          _buildInfoRow(
            context,
            title: 'Delivery',
            value: quote!.getDeliveryDate,
          ),
          if (!_isPerLineTax) ...{
            _buildInfoRow(
              context,
              title: 'Applied Taxes',
              value: quote?.taxNames.toTitle ?? 'N/A',
            ),
          },
          if (quote?.deliveryAddress?.isNotEmpty ?? false)
            _buildInfoRow(
              context,
              title: 'Delivery Address',
              value: quote!.deliveryAddress.toSentence,
            ),
          if (quote?.notes?.isNotEmpty ?? false)
            _buildInfoRow(
              context,
              title: 'Additional Notes',
              value: quote!.notes.toSentence,
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildInfoRow(
            context,
            title: 'Subtotal',
            value: '$_currency${_subtotal.toCurrency}',
          ),
          _buildInfoRow(
            context,
            title: 'Discount',
            value: '-$_currency${_discount.toCurrency}',
          ),
          _buildInfoRow(
            context,
            title: 'Tax',
            value: '$_currency${_totalTax.toCurrency}',
          ),
          const SizedBox(height: 8),
          Text(
            'Grand Total: $_currency${_grandTotal.toCurrency}',
            style: context.textTheme.titleLarge?.copyWith(color: kDangerColor),
          ),
        ],
      ),
    );
  }
}
