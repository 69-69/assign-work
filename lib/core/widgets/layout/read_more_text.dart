import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ReadMoreAutoText extends StatefulWidget {
  final dynamic text; // String OR TextSpan
  final int maxLines;
  final TextStyle? style;
  final bool isRichText;

  const ReadMoreAutoText({
    super.key,
    this.isRichText = false,
    required this.text,
    this.maxLines = 2,
    this.style,
  });

  @override
  State<ReadMoreAutoText> createState() => _ReadMoreAutoTextState();
}

class _ReadMoreAutoTextState extends State<ReadMoreAutoText> {
  bool _isExpanded = false;
  bool _isOverflowing = false;

  int get _maxLines => widget.maxLines;

  TextStyle? get _style => widget.style;

  void _checkOverflow(double maxWidth) {
    final TextSpan span = widget.isRichText
        ? widget.text as TextSpan
        : TextSpan(text: widget.text as String, style: _style);

    final textPainter = TextPainter(
      text: span,
      maxLines: _maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    _isOverflowing = textPainter.didExceedMaxLines;
    // setState(() => isOverflowing = textPainter.didExceedMaxLines);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _checkOverflow(constraints.maxWidth);

        return Wrap(
          children: [
            widget.isRichText ? _buildRichText() : _buildText(),

            if (_isOverflowing)
              InkWell(
                onTap: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
                child: Text(
                  _isExpanded ? 'See less' : '...See more',
                  style: TextStyle(
                    color: kPrimaryAccentColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Text _buildText() {
    return Text(
      widget.text.toString(),
      style: _style,
      maxLines: _isExpanded ? null : _maxLines,
      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

  RichText _buildRichText() {
    return RichText(
      text: widget.text as TextSpan,
      maxLines: _isExpanded ? null : _maxLines,
      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }
}
