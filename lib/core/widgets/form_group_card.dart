import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class FormGroupCard extends StatefulWidget {
  final String title;
  final String subTitle;
  final Color? bgColor;
  final Color? textColor;
  final List<Widget> children;
  final bool showCollapseButton;
  final GlobalKey<FormState>? formKey;

  const FormGroupCard({
    super.key,
    this.bgColor,
    this.textColor,
    this.title = '',
    this.subTitle = '',
    required this.children,
    this.showCollapseButton = true,
    this.formKey,
  });

  @override
  State<FormGroupCard> createState() => _FormGroupCardState();
}

class _FormGroupCardState extends State<FormGroupCard> {
  // Initialize cardVisibility in initState
  late Map<String, bool> cardVisibility;

  String get _title => widget.title;
  String get _subTitle => widget.subTitle;

  // Generate a unique key for each card based on the title
  String get _collapseKey => _title.isEmpty ? '' : _title.replaceAll(' ', '_');
  List<Widget> get _children => widget.children;
  Color? get _bgColor => widget.bgColor;
  Color? get _textColor => widget.textColor;
  bool get _showCollapseButton => widget.showCollapseButton;

  @override
  void initState() {
    super.initState();
    // Initialize visibility map with the title as the key and true as the default visibility
    cardVisibility = {_collapseKey: true};
  }

  // Toggle visibility based on the card title
  void toggleCardVisibility(String title) {
    setState(() {
      cardVisibility[title] = !(cardVisibility[title] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // elevation: 2.0,
      color: _bgColor ?? context.onSecondaryColor, // context.scaffoldBgColor
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            if (_title.isNotEmpty) ...{_buildHeader(context)},
            Visibility(
              visible: cardVisibility[_collapseKey] ?? true,
              maintainState: true, // KEEP the state of children
              maintainAnimation: false,
              maintainSize: false, // Prevent layout jump
              child: Wrap(runSpacing: 14.0, children: _children),
            ),
          ],
        ),
      ),
    );
  }

  Row _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              text: _title,
              children: _subTitle.isEmpty
                  ? null
                  : [
                      TextSpan(
                        text: _subTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: _textColor ?? context.onSecondaryContainer,
                        ),
                      ),
                    ],
              style: context.textTheme.titleMedium?.copyWith(
                color: _textColor ?? context.onPrimaryContainer.toAlpha(0.8),
              ),
            ),
          ),
        ),

        // Only show the collapse button if showCollapseButton is true
        if (_showCollapseButton) ...{
          IconButton(
            tooltip: (cardVisibility[_collapseKey] ?? true)
                ? 'Collapse'
                : 'Expand',
            onPressed: () => toggleCardVisibility(_collapseKey),
            icon: Icon(
              cardVisibility[_collapseKey] ?? true
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
            hoverColor: kLightBlueColor.toAlpha(0.3),
          ),
        },
      ],
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
