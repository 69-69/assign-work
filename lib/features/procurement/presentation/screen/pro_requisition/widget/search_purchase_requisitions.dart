import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/procurement/data/data_sources/remote/get_purchase_requisitions.dart';
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:flutter/material.dart';

/// Search Purchase Requisitions [SearchPurchaseRequisitions]
class SearchPurchaseRequisitions extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final void Function()? onPressed;
  final Function(Map<String, dynamic>) onValueChanged;

  const SearchPurchaseRequisitions({
    super.key,
    this.onChanged,
    this.onPressed,
    required this.onValueChanged,
  });

  @override
  State<SearchPurchaseRequisitions> createState() =>
      _SearchPurchaseRequisitionsState();
}

class _SearchPurchaseRequisitionsState
    extends State<SearchPurchaseRequisitions> {
  final _searchController = TextEditingController();
  Future<List<PurchaseRequisition>>? _futureResults;

  void _runSearch() {
    final term = _searchController.text.trim();
    if (term.isEmpty) return;

    setState(() {
      _futureResults = GetPurchaseRequisitions.byAnyTerm(term);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _searchController,
          onChanged: (value) => widget.onChanged?.call(value),
          onFieldSubmitted: (_) => _runSearch(),
          inputDecoration: InputDecoration(
            labelText: 'Search Approve PR...',
            helperText: 'e.g., Enter PR-number, status or department code',
            suffixIcon: _searchButton(context),
          ),
          keyboardType: TextInputType.none,
          validator: (s) => null,
        ),

        HorizontalDivider(),
        _buildResults(),
        HorizontalDivider(isORSeparator: true),
      ],
    );
  }

  /// Render results list
  Widget _buildResultsList(
    BuildContext context,
    List<PurchaseRequisition> data,
  ) {
    final rowHeight = 56.0;
    final availableHeight = context.screenHeight * 0.5;
    final maxVisibleRows = (availableHeight ~/ rowHeight).clamp(1, data.length);

    return SizedBox(
      height: maxVisibleRows * rowHeight,
      child: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, i) {
          final pr = data[i];
          return Column(
            children: [
              ListTile(
                dense: true,
                title: Text(
                  'PR#: ${pr.prNumber} | ${pr.departmentCode.toUpperAll}',
                ),
                subtitle: Wrap(
                  spacing: 5,
                  children: [
                    _buildMiniLabel(context, 'Status', pr.getPRStatus.toTitle),
                    _buildMiniLabel(
                      context,
                      ' | Priority',
                      pr.getPriority.toUpperAll,
                    ),
                  ],
                ),
                onTap: () {
                  // prettyPrint('changes', pr.toMap());
                  widget.onValueChanged(pr.toMap());
                },
              ),
              HorizontalDivider(),
            ],
          );
        },
      ),
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

  /// Search Button
  Widget _searchButton(BuildContext context) {
    return context.elevatedButton(
      'Find PR',
      tooltip: 'Find Purchase Requisition',
      bgColor: kPrimaryLightColor,
      txtColor: kWhiteColor,
      onPressed: _runSearch,
    );
  }

  FutureBuilder<List<PurchaseRequisition>> _buildResults() {
    return FutureBuilder<List<PurchaseRequisition>>(
      future: _futureResults,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return context.loader;
        }

        if (snapshot.hasError) {
          return context.buildError(snapshot.error.toString());
        }

        List<PurchaseRequisition> data = snapshot.data ?? [];

        if (data.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No Approved PR found with the search term.'),
          );
        }

        return _buildResultsList(context, data);
      },
    );
  }
}
