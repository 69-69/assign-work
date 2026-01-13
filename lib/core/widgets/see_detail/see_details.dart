import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/workflow_status.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
import 'package:assign_erp/core/widgets/layout/read_more_text.dart';
import 'package:assign_erp/features/procurement/data/model/pro_purchase_order_model.dart';
import 'package:flutter/material.dart';

/// Helper to build info row
Widget _buildInfoRow(
  BuildContext context, {
  Color? textColor,
  String title = '',
  String value = '',
  String separator = ': ',
  bool isReadMore = false,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 2.0),
    child: RichText(
      text: TextSpan(
        text: '$title$separator',
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor ?? context.secondaryColor,
        ),
        children: [
          isReadMore
              ? WidgetSpan(child: ReadMoreAutoText(text: value))
              : TextSpan(
                  text: value,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.normal,
                  ),
                ),
        ],
      ),
    ),
  );
}

class _POInfoPage extends StatelessWidget {
  final String _requestedBy;
  final ProPurchaseOrder? _po;
  final Color? _textColor;

  const _POInfoPage({
    ProPurchaseOrder? po,
    String employee = '',
    Color? textColor,
  }) : _po = po,
       _requestedBy = employee,
       _textColor = textColor;

  List<LineItem> get _items => _po?.lineItems ?? [];

  @override
  Widget build(BuildContext context) {
    if (_po == null) {
      return const Center(child: Text("PO not available."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBody(context),
        _Footer(po: _po),
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
          columnLabels: _items.first.dataTableHeader,
          items: _items,
          // list of POs
          rowBuilder: (entry) {
            return DataRow(
              cells: entry.itemAsList
                  .map((cell) => DataCell(Text(cell)))
                  .toList(),
            );
          },
          sortAccessors: [
            (entry) => entry.description,
            (entry) => entry.quantity,
            (entry) => entry.getCategory,
          ],
        ),
        const SizedBox(height: 12),

        AdaptiveLayout(
          children: [
            _LeftSummary(po: _po, textColor: _textColor),
            _RightSummary(po: _po, textColor: _textColor),
          ],
        ),
        const SizedBox(height: 12),
        _addressesAndNotes(context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Build the list of header entries first
    final headerItems = <(String, String)>[
      ('PO#', _po?.poNumber ?? 'N/A'),
      ('Store ID', _po?.storeNumber.toUpperAll ?? 'N/A'),
      ('Status', _po?.status.getLabel.toSentence ?? 'N/A'),
      ('Payment Terms', _po?.paymentTerm.toTitle ?? 'N/A'),
      ('Payment Method', _po!.paymentMethod.toTitle),
      ('Requested By', _requestedBy.toTitle),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Text('Purchase Order', style: context.textTheme.headlineSmall),
        // const SizedBox(height: 8),
        ...headerItems.map(
          (item) => _buildInfoRow(
            context,
            textColor: _textColor,
            title: item.$1,
            value: item.$2,
          ),
        ),
      ],
    );
  }

  Widget _addressesAndNotes(BuildContext context) {
    return AdaptiveLayout(
      children: [
        if (_po!.addresses.isNotNullNorEmpty) ...{
          ...?_po.addresses?.map((a) {
            return _buildInfoRow(
              context,
              separator: '\n',
              title: '${a.getType.toSentence} address:',
              isReadMore: true,
              value: a.address.toSentence,
            );
          }),
        },
        _buildInfoRow(
          context,
          separator: '\n',
          title: 'Terms:',
          isReadMore: true,
          value: _po.termsAndConditions.isNullOrEmpty
              ? 'N/A'
              : _po.termsAndConditions.toSentence,
        ),
        _buildInfoRow(
          context,
          separator: '\n',
          isReadMore: true,
          title: 'Additional Notes:',
          value: _po.notes.isNullOrEmpty ? 'N/A' : _po.notes.toSentence,
        ),
      ],
    );
  }
}

class _LeftSummary extends StatelessWidget {
  final ProPurchaseOrder? po;
  final Color? textColor;

  const _LeftSummary({this.po, required this.textColor});

  get _summaryItems => <(String, String)>[
    ('Delivery Date', '${po?.getDeliveryDate}'),
    ('Contact Person', '${po?.buyerContactPersonId}'),
  ];

  @override
  Widget build(BuildContext context) {
    return _buildLeftSummary(context);
  }

  // Helper for optional multiline sections (adds spacing automatically)
  List<Widget> buildOptionalSection(
    BuildContext context,
    String title,
    String? value,
  ) {
    return (value == null || value.isEmpty)
        ? []
        : [
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              separator: ':\n',
              title: title,
              value: value.toSentence,
            ),
          ];
  }

  Widget _buildLeftSummary(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*_buildInfoRow(
            context,
            separator: '\n',
            textColor: textColor,
            title: 'Purpose / Reason:',
            value: po!.purpose.toSentence,
          ),*/
          // HorizontalDivider(),
          ..._summaryItems.map(
            (item) => _buildInfoRow(
              context,
              textColor: textColor,
              title: item.$1,
              value: item.$2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RightSummary extends StatelessWidget {
  final ProPurchaseOrder? po;
  final Color? textColor;

  const _RightSummary({this.po, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return _buildRightSummary(context);
  }

  Widget _buildRightSummary(BuildContext context) {
    final history = _getApprovals(po!);

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            separator: '\n',
            textColor: kDangerColor,
            title: 'Approved By:',
            value:
                '${history.$1 ?? 'Not yet approved'}\n${history.$2 ?? '-----------------'}',
          ),
        ],
      ),
    );
  }

  /// Get the last approved PO entry and the date it was approved [_getApprovals]
  (String?, String?) _getApprovals(ProPurchaseOrder? req) {
    if (req == null) return (null, null);

    // Find the most recent approved PO entry
    final lastApproved = req.history.lastWhere(
      (h) => h.getAction.toLowerAll == AuditAction.approved.getLabel,
      orElse: () => AuditLog.empty,
    );

    // If none found, return null for both
    if (lastApproved.isEmpty) return (null, null);

    return (lastApproved.actionBy, lastApproved.getActionAt);
  }
}

class _Footer extends StatelessWidget {
  final ProPurchaseOrder? po;

  const _Footer({this.po});

  String? get _updatedBy => po!.updatedBy.isNullOrEmpty ? 'N/A' : po?.updatedBy;

  String? get _createdBy => po!.createdBy.isNullOrEmpty ? 'N/A' : po?.createdBy;

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
              value: '${po?.getCreatedAt} - By: [ ${_createdBy.toTitle} ]',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _buildInfoRow(
              context,
              title: 'Updated',
              value: '${po!.getUpdatedAt} - By: [ ${_updatedBy.toTitle} ]',
            ),
          ),
        ],
      ),
    );
  }
}
