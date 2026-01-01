import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class FormGroupCard extends StatefulWidget {
  final String title;
  final String subTitle;
  final bool isExpanded;
  final Color? bgColor;
  final Color? textColor;
  final List<Widget> children;
  final Axis? scrollDirection;
  final bool showCollapseButton;
  final GlobalKey<FormState>? formKey;
  final CrossAxisAlignment? crossAlignment;
  final EdgeInsetsGeometry? contentMargin;
  final EdgeInsetsGeometry? contentPadding;

  const FormGroupCard({
    super.key,
    this.formKey,
    this.bgColor,
    this.textColor,
    this.title = '',
    this.subTitle = '',
    this.contentMargin,
    this.crossAlignment,
    this.contentPadding,
    this.scrollDirection,
    this.isExpanded = true,
    required this.children,
    this.showCollapseButton = true,
  });

  @override
  State<FormGroupCard> createState() => _FormGroupCardState();
}

class _FormGroupCardState extends State<FormGroupCard> {
  // Initialize cardVisibility in initState
  late Map<String, bool> cardVisibility;

  bool get _isExpanded => widget.isExpanded;

  String get _title => widget.title;

  String get _subTitle => widget.subTitle;

  // Generate a unique key for each card based on the title
  String get _collapseKey => _title.isEmpty ? '' : _title.replaceAll(' ', '_');

  List<Widget> get _children => widget.children;

  Color? get _textColor => widget.textColor;

  Color get _bgColor => widget.bgColor ?? context.onSecondaryColor;

  Axis get _scrollDirection => widget.scrollDirection ?? Axis.horizontal;

  bool get _showCollapseButton => widget.showCollapseButton;

  EdgeInsetsGeometry get _contentPadding =>
      widget.contentPadding ?? const EdgeInsets.all(10);

  CrossAxisAlignment get _crossAlignment =>
      widget.crossAlignment ?? CrossAxisAlignment.start;

  EdgeInsetsGeometry get _contentMargin =>
      widget.contentMargin ?? const EdgeInsets.symmetric(vertical: 8);

  @override
  void initState() {
    super.initState();
    // Initialize visibility map with the title as the key and true as the default visibility
    cardVisibility = {_collapseKey: _isExpanded};
  }

  // Toggle visibility based on the card title
  void toggleCardVisibility(String title) {
    setState(() {
      cardVisibility[title] = !(cardVisibility[title] ?? _isExpanded);
    });
  }

  // 1340826115
  (String?, String?) get _getTitleInfo {
    if (_title.isEmpty) return ('', '');

    // Match leading number (without dot) and capture the remaining title
    final match = RegExp(r'^(\d+)\.\s*(.+)$').firstMatch(_title);

    if (match == null) return ('', _title);

    final prefix = match.group(1)?.trim(); // "3."
    final suffix = match.group(2)?.trim(); // "Title"

    return (prefix, suffix);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // elevation: 2.0,
      color: _bgColor, // context.scaffoldBgColor
      margin: _contentMargin,
      child: Padding(
        padding: _contentPadding,
        child: Column(
          crossAxisAlignment: _crossAlignment,
          children: [
            if (_title.isNotEmpty) ...{
              _buildHeader(context),
              const SizedBox(height: 10.0),
            },
            Visibility(
              visible: cardVisibility[_collapseKey] ?? true,
              maintainState: true,
              // KEEP the state of children
              maintainAnimation: false,
              maintainSize: false,
              // Prevent layout jump
              child: Wrap(
                runSpacing: 14.0,
                direction: _scrollDirection,
                children: _children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final (count, title) = _getTitleInfo;

    final header = Padding(
      padding: EdgeInsets.all(3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildTitle(context, count, title)),

          // Only show the collapse button if showCollapseButton is true
          if (_showCollapseButton) ...{_buildExpandIcon()},
        ],
      ),
    );

    return _showCollapseButton
        ? InkWell(
            onTap: () => toggleCardVisibility(_collapseKey),
            borderRadius: BorderRadius.circular(10),
            child: header,
          )
        : header;
  }

  RichText _buildTitle(BuildContext context, String? count, String? title) {
    return RichText(
      text: TextSpan(
        style: context.textTheme.titleMedium?.copyWith(
          color: _textColor ?? context.onPrimaryContainer.toAlpha(0.8),
        ),
        children: [
          if (count != null && count.isNotEmpty) ...{
            _buildNumber(count, context),
          },
          TextSpan(text: '$title'),
          if (_subTitle.isNotEmpty) ...{
            TextSpan(
              text: _subTitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: _textColor ?? context.onSecondaryContainer,
              ),
            ),
          },
        ],
      ),
    );
  }

  // Numbering: Add a badge to the title if count is provided
  WidgetSpan _buildNumber(String count, BuildContext context) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      baseline: TextBaseline.alphabetic,
      child: Padding(
        padding: EdgeInsets.only(right: 5),
        child: Badge.count(
          count: int.parse(count),
          backgroundColor: context.onPrimaryContainer.toAlpha(0.2),
          textColor: context.onSurfaceColor,
        ),
      ),
    );
  }

  Tooltip _buildExpandIcon() {
    return Tooltip(
      message: (cardVisibility[_collapseKey] ?? true) ? 'Collapse' : 'Expand',
      child: Icon(
        cardVisibility[_collapseKey] ?? true
            ? Icons.keyboard_arrow_up
            : Icons.keyboard_arrow_down,
      ),
    );
  }
}

/*// Helper widget to automatically keep alive the widget in its tree
class AutomaticKeepAlive extends StatefulWidget {
  final Widget child;

  const AutomaticKeepAlive({super.key, required this.child});

  @override
  State<AutomaticKeepAlive> createState() => _AutomaticKeepAliveState();
}

class _AutomaticKeepAliveState extends State<AutomaticKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}*/
