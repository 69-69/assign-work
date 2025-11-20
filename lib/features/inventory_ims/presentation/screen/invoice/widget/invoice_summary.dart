import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// Invoice Summary - PrintOut
class InvoiceSummary extends StatefulWidget {
  final String title;
  final Map<String, dynamic> data;
  final List? keysToRemove;

  const InvoiceSummary({
    super.key,
    required this.data,
    this.keysToRemove,
    required this.title,
  });

  @override
  State<InvoiceSummary> createState() => _InvoiceSummaryState();
}

class _InvoiceSummaryState extends State<InvoiceSummary> {
  String? _getInvoiceID;
  String? _selectedInvoiceType;
  DateTime? _selectedValidityDate;

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
  }

  List get _keysToRemove => [
    'itemId',
    'customerId',
    'status',
    'barcode',
    'discountPercent',
    'taxPercent',
    'updatedAt',
    'updatedBy',
    'createdAt',
    'createdBy',
  ];

  void _generateInvoiceNumber() async {
    await DocType.invoice.getShortUID(
      onChanged: (s) => setState(() => _getInvoiceID = s),
    );
  }

  @override
  Widget build(BuildContext context) {
    var fTheme = context.textTheme;
    var curDate = (DateTime.now()).toStandardDT;

    prettyPrint('InvoiceType', '$_selectedInvoiceType');
    prettyPrint('InvoiceType', '$_selectedValidityDate');

    return buildBody(fTheme, context, curDate);
  }

  buildBody(TextTheme fTheme, BuildContext context, String curDate) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: _InvoiceTypeAndValidityDropdown(
            onInvoiceChange: (s) => setState(() => _selectedInvoiceType = s),
            onDateChanged: (date) =>
                setState(() => _selectedValidityDate = date),
          ),
        ),
        ExpansionTile(
          dense: true,
          title: Text(widget.title.toTitle, style: fTheme.titleLarge),
          subtitle: Text(
            'see summary: $_getInvoiceID'.toTitle,
            style: fTheme.labelMedium?.copyWith(color: kDangerColor),
          ),
          childrenPadding: const EdgeInsets.only(bottom: 20.0),
          children: [
            _buildHeader(context),
            DataTable(
              headingRowColor: const WidgetStatePropertyAll(kGrayBlueColor),
              columns: [
                _buildDataColumn('Description'),
                _buildDataColumn('Amount'),
              ],
              rows: _createRows(),
              border: TableBorder.all(width: 0.2),
            ),
            Text('Date: $curDate', textAlign: TextAlign.left),
          ],
        ),
      ],
    );
  }

  ListTile _buildHeader(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        '${widget.data['orderType'] ?? '0000'}'.toTitle,
        textAlign: TextAlign.center,
        style: context.textTheme.titleLarge,
      ),
      subtitle: Text(
        'Customer ID: ${widget.data['customerId'] ?? '0000'}',
        textAlign: TextAlign.center,
      ),
    );
  }

  List<DataRow> _createRows() {
    /* keysToRemove: Remove certain key-value pairs from map */
    return widget.data.entries
        .where((entry) => !_keysToRemove.contains(entry.key))
        .map((data) {
          /// prefix a minus sign (-) in front of discountAmount
          var val =
              (data.key.contains('discountAmount')
                  ? '- '
                  : (data.key.contains('totalAmount') ? ghanaCedis : '')) +
              '${data.value}'.toTitle;

          return DataRow(
            cells: [
              _buildDataCell(data.key.separateWord.toTitle),
              _buildDataCell(val),
            ],
          );
        })
        .toList();
  }

  DataCell _buildDataCell(dynamic title) => DataCell(Text('$title'));

  DataColumn _buildDataColumn(String title) => DataColumn(
    tooltip: title,
    label: Text(title.toUpperAll, style: const TextStyle(color: kWhiteColor)),
  );
}

/// Invoice Type & Validity [_InvoiceTypeAndValidityDropdown]
class _InvoiceTypeAndValidityDropdown extends StatelessWidget {
  final void Function(dynamic s) onInvoiceChange;
  final void Function(dynamic s) onDateChanged;

  const _InvoiceTypeAndValidityDropdown({
    required this.onInvoiceChange,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: StaticDropdown<String>(
              key: key,
              items: invoiceType,
              label: 'invoice type',
              getValue: (type) => type,
              getDisplayText: (type) => type,
              onChanged: (String? v) => onInvoiceChange(v),
            ),
          ),
          const SizedBox(width: 20.0),
          Expanded(
            child: DatePicker(
              label: 'Validity date',
              restorationId: 'Validity date',
              selectedDate: onDateChanged,
            ),
          ),
        ],
      ),
    );
  }
}
