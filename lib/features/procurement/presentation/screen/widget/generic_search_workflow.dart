import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';

/// Generic Workflow Search Widget for PR / RFQ / Others
class SearchWorkflow<T> extends StatefulWidget {
  final Future<List<T>> Function(String term) onSearch;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final void Function(T value) onValueSelected;

  final String searchLabel;
  final String helperText;
  final String searchButtonText;
  final String emptyResultText;
  final String actionButtonText;

  final VoidCallback? onActionPressed;
  final ValueChanged<String>? onChanged;

  const SearchWorkflow({
    super.key,
    required this.onSearch,
    required this.itemBuilder,
    required this.onValueSelected,
    required this.searchLabel,
    required this.helperText,
    required this.searchButtonText,
    required this.emptyResultText,
    required this.actionButtonText,
    this.onActionPressed,
    this.onChanged,
  });

  @override
  State<SearchWorkflow<T>> createState() => _SearchWorkflowState<T>();
}

class _SearchWorkflowState<T> extends State<SearchWorkflow<T>> {
  final _controller = TextEditingController();
  Future<List<T>>? _future;

  void _runSearch() {
    final term = _controller.text.trim();
    if (term.isEmpty) return;

    setState(() {
      _future = widget.onSearch(term);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          controller: _controller,
          onChanged: widget.onChanged,
          onFieldSubmitted: (_) => _runSearch(),
          inputDecoration: InputDecoration(
            labelText: widget.searchLabel,
            helperText: widget.helperText,
            suffixIcon: _searchButton(context),
          ),
          keyboardType: TextInputType.none,
          validator: (_) => null,
        ),
        HorizontalDivider(),
        _buildResults(),
        HorizontalDivider(isORSeparator: true, space: 16, color: kDangerColor),
        SizedBox(
          width: double.infinity,
          child: context.outlinedButton(
            widget.actionButtonText,
            onPressed: widget.onActionPressed,
          ),
        ),
      ],
    );
  }

  Widget _searchButton(BuildContext context) {
    return context.elevatedButton(
      widget.searchButtonText,
      bgColor: kPrimaryLightColor,
      txtColor: kWhiteColor,
      onPressed: _runSearch,
    );
  }

  Widget _buildResults() {
    return FutureBuilder<List<T>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return context.loader;
        }

        if (snapshot.hasError) {
          return context.buildError(snapshot.error.toString());
        }

        final data = snapshot.data ?? [];

        if (data.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(widget.emptyResultText, textAlign: TextAlign.center),
          );
        }

        return _buildList(context, data);
      },
    );
  }

  Widget _buildList(BuildContext context, List<T> data) {
    // Measure available height to determine rows per view
    final maxVisible = context.getMaxVisibleHeight(itemCount: data.length);

    return SizedBox(
      height: maxVisible,
      child: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, i) {
          return InkWell(
            onTap: () => widget.onValueSelected(data[i]),
            child: Column(
              children: [
                widget.itemBuilder(context, data[i]),
                HorizontalDivider(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/*class SearchPurchaseRequisitions<T> extends StatefulWidget {
  final void Function()? onPressed;
  final ValueChanged<String>? onChanged;
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
        HorizontalDivider(isORSeparator: true, space: 16),
        SizedBox(
          width: double.infinity,
          child: context.outlinedButton(
            'Create New Quote',
            onPressed: widget.onPressed,
          ),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
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
                      '| Priority',
                      '${pr.getPriority.toUpperAll} (${pr.lineItems.first.getTypeLabel.toSentence})',
                    ),
                  ],
                ),
                onTap: () => widget.onValueChanged(pr.toMap()),
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
}*/
