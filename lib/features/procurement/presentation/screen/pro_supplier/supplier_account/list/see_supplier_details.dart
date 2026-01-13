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
import 'package:assign_erp/core/widgets/see_detail/see_details.dart';
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

class _SupplierInfoPage extends StatelessWidget {
  final Supplier? _supplier;

  const _SupplierInfoPage({Supplier? supplier}) : _supplier = supplier;

  List<ContactPerson> get _contactPersons => _supplier?.contactPersons ?? [];

  List<SummaryItem> get _summaryItems => [
    (title: 'Supplier ID', value: _supplier?.code.toUpperAll ?? 'N/A'),
    (title: 'Supplier', value: _supplier?.name.toSentence ?? 'N/A'),
    (title: 'Phone', value: _supplier!.phone),
    (title: 'Email', value: _supplier.email.toLowerAll),
    (title: 'Business', value: _supplier.getBusinessType.toTitle),
    (title: 'Industry', value: _supplier.getIndustryType.toTitle),
  ];

  List<SummaryItem> get _rightSummaryItems => [
    (title: 'Address', value: _supplier?.address.toSentence ?? 'None'),
    (title: 'Bank Details', value: _supplier?.bankDetails.toSentence ?? 'None'),
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
        DetailsFooter(
          created: (by: _supplier.createdBy, at: _supplier.getCreatedAt),
          updated: (by: _supplier.updatedBy, at: _supplier.getUpdatedAt),
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
        const SizedBox(height: 16),

        /// Table Headers
        Align(
          alignment: Alignment.center,
          child: Text(
            'Contact Persons (${_contactPersons.length})',
            style: context.textTheme.titleLarge,
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
            DetailsSummary(
              items: _rightSummaryItems,
              alignment: Alignment.centerLeft,
            ),
            DetailsSummary(
              items: [
                (
                  title: 'Products / Services',
                  value:
                      '\n${_supplier!.items.splitMapJoin(',', onMatch: (m) => '\n', onNonMatch: (m) => m.toTitle.trim())}',
                ),
              ],
            ),
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
    return DetailsSummary(items: _summaryItems, alignment: Alignment.topLeft);
  }

  Widget _buildItemTableHeader(BuildContext context) {
    return Container(
      color: context.primaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ContactPerson.dataTableHeader
            .map((item) => _buildItem(item))
            .toList(),
      ),
    );
  }

  Widget _buildItemRow(ContactPerson person, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: person.itemAsList
            .map((item) => _buildItem(item, isBold: false))
            .toList(),
      ),
    );
  }
}
