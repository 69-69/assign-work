import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/procurement/data/data_sources/remote/get_purchase_requisitions.dart';
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/procurement/presentation/screen/widget/generic_search_workflow.dart';
import 'package:flutter/material.dart';

/// Search Purchase Requisitions [SearchPRs]
/// For Converting [PurchaseRequisition] to [Request for Quote]: PR -> RFQ
class SearchPRs extends StatelessWidget {
  final void Function(Map<String, dynamic>) onValueChanged;
  final void Function() onActionPressed;
  final String actionButtonText;

  const SearchPRs({
    super.key,
    required this.actionButtonText,
    required this.onValueChanged,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SearchWorkflow<PurchaseRequisition>(
      searchLabel: 'Search Approved PR',
      helperText: 'e.g. PR number, status or department',
      searchButtonText: 'Find PR',
      emptyResultText: 'No PRs available to convert to a RFQ',
      actionButtonText: actionButtonText,

      onSearch: (term) => GetPurchaseRequisitions.byAnyTerm(term),

      onValueSelected: (pr) => onValueChanged(pr.toMap()),

      itemBuilder: (context, pr) {
        return ListTile(
          // dense: true,
          title: Text('PR#: ${pr.prNumber} | ${pr.departmentCode.toUpperAll}'),
          subtitle: Wrap(
            spacing: 5,
            children: [
              _buildMiniLabel(context, 'Status', pr.getPRStatus.toTitle),
              _buildMiniLabel(
                context,
                'Priority',
                '${pr.getPriority.toUpperAll} (${pr.lineItems.first.getType.toSentence})',
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
