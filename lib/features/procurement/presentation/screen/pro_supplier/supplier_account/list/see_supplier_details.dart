import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/contact_person_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:flutter/material.dart';
/*import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';*/

extension SupplierDetails on BuildContext {
  Future openSupplierDetails({required Supplier supplier}) async {
    if (supplier.isEmpty) return;

    return await openBottomSheet(
      isExpand: true,
      showZoomIcon: false,
      child: BottomSheetScaffold(
        isDetailMode: true,
        title: supplier.name.toTitle,
        subtitle: supplier.businessType.toUpperAll,
        body: _SupplierInfoPage(supplier: supplier),
        onPrint: () async => await _printRFQ(this, supplier),
      ),
    );
  }

  _printRFQ(BuildContext cxt, quote) async {
    await cxt.progressBarDialog(
      request: Future.delayed(
        kRProgressDelay,
        () async => null,
        // @TODO Implement printout
        //  await RFQPrinter(quote: quote, supplier: supplier).printRFQ(),
      ),
      onSuccess: (_) => cxt.showAlertOverlay('RFQ printout successful'),
      onError: (e) =>
          cxt.showAlertOverlay('RFQ printout failed', bgColor: kDangerColor),
    );
  }
}

Widget _buildInfoRow(
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

class _SupplierInfoPage extends StatelessWidget {
  final Supplier? _supplier;

  const _SupplierInfoPage({Supplier? supplier}) : _supplier = supplier;

  List<ContactPerson> get _contactPersons => _supplier?.contactPersons ?? [];
  List<String> get _headerItems => [
    'Name',
    'Email',
    'Phone',
    'Department',
    'Position',
    'Date',
  ];

  @override
  Widget build(BuildContext context) {
    if (_supplier == null) {
      return const Center(child: Text("No Supplier data available."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBody(context),
        _Footer(supplier: _supplier),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),

        /// Table Headers
        Align(
          alignment: Alignment.center,
          child: Text(
            'Contact Persons (${_contactPersons.length})',
            style: context.textTheme.titleLarge?.copyWith(
              color: context.secondaryColor,
            ),
          ),
        ),
        HorizontalDivider(),
        _buildItemTableHeader(context),

        /// Item Rows: generate index too
        /// ...items.map((item, index) => _buildItemRow(item, index)),
        ..._contactPersons.asMap().entries.map(
          (entry) => _buildItemRow(entry.value, entry.key),
        ),

        HorizontalDivider(),
        const SizedBox(height: 12),

        AdaptiveLayout(
          children: [
            _LeftSummary(supplier: _supplier),
            _RightSummary(supplier: _supplier),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Expanded _buildItem(String text, {bool isBold = true}) => Expanded(
    child: Text(
      text,
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
        Text('Supplier (Vendor) Info', style: context.textTheme.headlineSmall),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          title: 'Supplier ID',
          value: _supplier?.code.toUpperAll ?? 'N/A',
        ),
        _buildInfoRow(
          context,
          title: 'Supplier',
          value: _supplier?.name.toSentence ?? 'N/A',
        ),
        _buildInfoRow(context, title: 'Phone', value: _supplier!.phone),
        _buildInfoRow(
          context,
          title: 'Email',
          value: _supplier.email.toLowerAll,
        ),
        _buildInfoRow(
          context,
          title: 'Business Type',
          value: _supplier.getBusinessType.toTitle,
        ),
        _buildInfoRow(
          context,
          title: 'Industry Type',
          value: _supplier.getIndustryType.toTitle,
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
        children: _headerItems.map((item) => _buildItem(item)).toList(),
      ),
    );
  }

  Widget _buildItemRow(ContactPerson person, int index) {
    final rowItems = [
      person.name.toTitle,
      person.email.toLowerAll,
      person.phone,
      person.department.toTitle,
      person.position.toTitle,
      person.getCreatedAt,
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
  }
}

class _LeftSummary extends StatelessWidget {
  final Supplier? supplier;

  const _LeftSummary({this.supplier});

  /// List of title-value pairs to render in the summary.
  List<(String, String)> get summaryItems {
    final s = supplier;
    if (s == null) return const [];

    return [
      ('Address', s.address.toSentence),
      ('Bank Details', s.bankDetails.toSentence),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: supplier == null
          ? Text("No supplier data available.")
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: summaryItems
                  .map(
                    (item) => _buildInfoRow(
                      context,
                      separator: ':\n',
                      title: item.$1,
                      value: item.$2,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _RightSummary extends StatelessWidget {
  final Supplier? supplier;

  const _RightSummary({this.supplier});

  @override
  Widget build(BuildContext context) {
    return _buildRightSummary(context);
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
            title: 'Products / Services',
            separator: ':\n',
            value: supplier!.items.splitMapJoin(
              ',',
              onMatch: (m) => '\n',
              onNonMatch: (m) => m.toTitle.trim(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final Supplier? supplier;

  const _Footer({this.supplier});

  String? get _updatedBy =>
      supplier!.updatedBy.isNullOrEmpty ? 'N/A' : supplier?.updatedBy;

  String? get _createdBy =>
      supplier!.createdBy.isNullOrEmpty ? 'N/A' : supplier?.createdBy;

  @override
  Widget build(BuildContext context) {
    return _buildFooter(context);
  }

  Container _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: context.secondaryContainerColor,
      child: AdaptiveLayout(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _buildInfoRow(
              context,
              title: 'Created',
              value:
                  '${supplier?.getCreatedAt} - By: [ ${_createdBy.toTitle} ]',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _buildInfoRow(
              context,
              title: 'Updated',
              value:
                  '${supplier!.getUpdatedAt} - By: [ ${_updatedBy.toTitle} ]',
            ),
          ),
        ],
      ),
    );
  }
}
