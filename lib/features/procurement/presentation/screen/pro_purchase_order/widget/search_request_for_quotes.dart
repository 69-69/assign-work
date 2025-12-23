import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/procurement/data/data_sources/remote/get_request_for_quote.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/presentation/screen/widget/generic_search_workflow.dart';
import 'package:flutter/material.dart';

/// Search Request For Quotes [SearchRFQs]
/// For Converting [RequestForQuote] to [Purchase Order]: RFQ -> PO
class SearchRFQs extends StatelessWidget {
  final void Function(Map<String, dynamic>) onValueChanged;
  final void Function() onActionPressed;
  final String actionButtonText;

  const SearchRFQs({
    super.key,
    required this.actionButtonText,
    required this.onValueChanged,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SearchWorkflow<RequestForQuote>(
      searchLabel: 'Search RFQ',
      helperText: 'e.g. RFQ number, supplier or department',
      searchButtonText: 'Find RFQ',
      emptyResultText: 'No RFQs available to convert to a PO',
      actionButtonText: actionButtonText,

      onSearch: (term) => GetRequestForQuote.byAnyTerm(term),

      onValueSelected: (rfq) => onValueChanged(rfq.toMap()),

      itemBuilder: (context, rfq) {
        return ListTile(
          // dense: true,
          title: Text(
            'RFQ#: ${rfq.rfqNumber} | ${rfq.departmentCode.toUpperAll}',
          ),
          subtitle: Wrap(
            spacing: 5,
            children: [
              _buildMiniLabel(context, 'Status', rfq.getRFQStatus.toTitle),
              _buildMiniLabel(
                context,
                '| Expected',
                '${rfq.getExpectedDate} (${rfq.lineItems.first.getTypeLabel.toSentence})',
              ),
            ],
          ),
        );
      },
      onActionPressed: onActionPressed,
    );
  }

  RichText _buildMiniLabel(BuildContext context, String label, String value) {
    return RichText(
      text: TextSpan(
        text: '$label: ',
        style: TextStyle(
          color: context.secondaryColor,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              color: context.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }
}
