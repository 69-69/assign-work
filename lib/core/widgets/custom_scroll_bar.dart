import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:flutter/material.dart';

class CustomScrollBar extends StatefulWidget {
  final Widget child;
  final Axis? scrollDirection;
  final EdgeInsetsGeometry? padding;
  final ScrollController controller;
  final bool isAlwaysShown;
  // show scroll to top button
  final bool showScrollUpButton;

  const CustomScrollBar({
    super.key,
    required this.child,
    required this.controller,
    this.scrollDirection,
    this.padding,
    this.isAlwaysShown = false, // always show the scrollbar
    this.showScrollUpButton = true, // show scroll to top button
  });

  @override
  State<CustomScrollBar> createState() => _CustomScrollBarState();
}

class _CustomScrollBarState extends State<CustomScrollBar> {
  late ScrollController _scrollController;
  bool _isAtBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller;

    _scrollController.addListener(() {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final currentScrollPosition = _scrollController.offset;

      // Check if the user has scrolled to the bottom
      if (mounted) {
        setState(() {
          _isAtBottom =
              currentScrollPosition >=
              maxScrollExtent - 10; // Tolerance for precision issues
        });
      }
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: kAnimateDuration,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrollDir = widget.scrollDirection ?? Axis.vertical;
    var isVertical = scrollDir == Axis.vertical;
    final icon = isVertical ? Icons.arrow_upward : Icons.arrow_back;
    final toolTip = isVertical ? 'Scroll to top' : 'Scroll to left';

    return SizedBox(
      height: context.screenHeight,
      child: Stack(
        children: [
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: widget.isAlwaysShown,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: scrollDir,
              padding:
                  widget.padding ??
                  EdgeInsets.only(
                    top: 20.0,
                    bottom: context.bottomInsetPadding,
                  ),
              child: widget.child,
            ),
          ),
          if (_isAtBottom && widget.showScrollUpButton)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.small(
                backgroundColor: kDangerColor,
                onPressed: _scrollToTop,
                tooltip: toolTip,
                child: Icon(icon, color: kWhiteColor),
              ),
            ),
        ],
      ),
    );
  }
}

/*class CustomScrollBar extends StatelessWidget {
  final Widget child;
  final Axis? scrollDirection;
  final EdgeInsetsGeometry? padding;
  final ScrollController controller;

  const CustomScrollBar({
    super.key,
    required this.child,
    required this.controller,
    this.scrollDirection,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,

      /// Ensure the scrollbar is visible
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: scrollDirection ?? Axis.vertical,
        padding: padding ??
            EdgeInsets.only(
              top: 20.0,
              bottom: context.bottomInsetPadding,
            ),
        child: child,
      ),
    );
  }
}*/
