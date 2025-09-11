import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/features/system_admin/data/models/supplier_model.dart';
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
      child: FormBottomSheet(
        isDetails: true,
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
        // await RFQPrinter(quote: quote, supplier: supplier).printRFQ(),
      ),
      onSuccess: (_) => cxt.showAlertOverlay('RFQ successfully created'),
      onError: (e) =>
          cxt.showAlertOverlay('RFQ printout failed', bgColor: kDangerColor),
    );
  }
}

class _SupplierInfoPage extends StatelessWidget {
  final Supplier? _supplier;

  const _SupplierInfoPage({Supplier? supplier}) : _supplier = supplier;

  List<SupplierContactPerson> get _contactPersons =>
      _supplier?.contactPersons ?? [];

  String? get _updatedBy =>
      _supplier!.updatedBy.isNullOrEmpty ? 'N/A' : _supplier.updatedBy;

  String? get _createdBy =>
      _supplier!.createdBy.isNullOrEmpty ? 'N/A' : _supplier.createdBy;

  @override
  Widget build(BuildContext context) {
    if (_supplier == null) {
      return const Center(child: Text("No Supplier data available."));
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
        children: [
          _buildItem('Name', flex: 1),
          _buildItem('Email'),
          _buildItem('Phone'),
          _buildItem('Department'),
          _buildItem('Position'),
          _buildItem('Date', flex: 1),
        ],
      ),
    );
  }

  Widget _buildItemRow(SupplierContactPerson person, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildItem(person.name.toTitle, flex: 1, isBold: false),
          _buildItem(person.email.toLowerAll, isBold: false),

          _buildItem(person.phone, isBold: false),
          _buildItem(person.department.toTitle, isBold: false),
          _buildItem(person.position.toTitle, isBold: false),
          _buildItem(person.getCreatedAt, flex: 1, isBold: false),
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
            separator: ':\n',
            title: 'Address',
            value: _supplier!.address.toSentence,
          ),
          _buildInfoRow(
            context,
            separator: ':\n',
            title: 'Bank Details',
            value: _supplier.bankDetails.toSentence,
          ),
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
            title: 'Products / Services',
            separator: ':\n',
            value: _supplier!.items.splitMapJoin(
              ',',
              onMatch: (m) => '\n',
              onNonMatch: (m) => m.toTitle.trim(),
            ),
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
            value: '${_supplier?.getCreatedAt} - By: [ ${_createdBy.toTitle} ]',
          ),
          _buildInfoRow(
            context,
            title: 'Last Updated',
            value: '${_supplier?.getUpdatedAt} - By: [ ${_updatedBy.toTitle} ]',
          ),
        ],
      ),
    );
  }
}
