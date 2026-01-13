import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/read_more_text.dart';
import 'package:flutter/material.dart';

/// Helper to build info row
Widget detailsRow(
  BuildContext context, {
  Color? textColor,
  String title = '',
  String value = '',
  String? separator,
  bool isReadMore = false,
}) {
  separator ??= ': ';

  return Padding(
    padding: EdgeInsets.symmetric(vertical: 2.0),
    child: RichText(
      text: TextSpan(
        text: '$title$separator',
        style: context.textTheme.titleMedium?.copyWith(
          color: textColor ?? context.secondaryColor,
          fontWeight: FontWeight.w600,
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

typedef ApprovalInfo = ({String? by, String? at});
typedef SummaryItem = ({String title, String value});

class DetailsSummary extends StatelessWidget {
  final AlignmentGeometry alignment;
  final List<SummaryItem> items;
  final Color? textColor;
  final bool isReadMore;
  final bool isAlign;
  final Widget? anyWidget;
  final String? separator;
  final CrossAxisAlignment crossAxisAlignment;

  const DetailsSummary({
    super.key,
    this.textColor,
    this.anyWidget,
    this.separator,
    required this.items,
    this.isAlign = true,
    this.isReadMore = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,

    /// [alignment] defaults to [Alignment.topRight]
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return isAlign
        ? Align(alignment: alignment, child: _buildColumn(context))
        : _buildColumn(context);
  }

  Column _buildColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        // const SizedBox(height: 8),
        ...items.map(
          (item) => detailsRow(
            context,
            textColor: item.title.toLowerAll.contains('grand total')
                ? kDangerColor
                : textColor,
            separator: separator,
            title: item.title,
            value: item.value,
            isReadMore: isReadMore,
          ),
        ),
        if (anyWidget != null) ...{const SizedBox(height: 8), anyWidget!},
      ],
    );
  }
}

class DetailsFooter extends StatelessWidget {
  final ApprovalInfo created;
  final ApprovalInfo updated;

  const DetailsFooter({
    super.key,
    required this.created,
    required this.updated,
  });

  String _by(String? v) => v.isNullOrEmpty ? 'N/A' : v!.toTitle;

  String _at(String? v) => v.isNullOrEmpty ? 'N/A' : v!;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: context.secondaryContainerColor,
      child: AdaptiveLayout(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: detailsRow(
              context,
              title: 'Created',
              textColor: kDarkTextColor,
              value: '${_at(created.at)} - By: [ ${_by(created.by)} ]',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: detailsRow(
              context,
              title: 'Updated',
              textColor: kDarkTextColor,
              value: '${_at(updated.at)} - By: [ ${_by(updated.by)} ]',
            ),
          ),
        ],
      ),
    );
  }
}
