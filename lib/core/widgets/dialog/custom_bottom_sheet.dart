import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/neumorphism.dart';
import 'package:flutter/material.dart';

/*extension ShowBottomSheet<T> on BuildContext {
  Future<T?> openBottomSheet({required Widget child, bool isExpand = true}) {
    var num = isMobile ? 1 : 0.9;

    return showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      backgroundColor: kTransparentColor,
      constraints:
          isExpand ? BoxConstraints(maxWidth: screenWidth * num) : null,
      builder: (context) => child,
    );
  }
}*/

extension ShowBottomSheet<T> on BuildContext {
  Future<T?> openBottomSheet({
    required Widget child,
    bool isExpand = true,
    bool showZoomIcon = true,
    BoxConstraints? constraints,
  }) {
    // Initialize zoom level
    final ValueNotifier<double> zoomLevel = ValueNotifier<double>(
      isExpand ? 1.0 : 0.5,
    );

    return showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      backgroundColor: kTransparentColor,
      constraints: constraints ?? BoxConstraints(maxWidth: screenWidth),

      // isDismissible: false,
      // ❗ disables tap outside dismiss
      enableDrag: false,

      // ❗ disables swipe-down dismiss
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context),
        child: _buildZoom(zoomLevel, child, showZoomIcon: showZoomIcon),
      ),
    );
  }

  ValueListenableBuilder<double> _buildZoom(
    ValueNotifier<double> zoomLevel,
    Widget child, {
    bool showZoomIcon = true,
  }) {
    var isSmall = isMobile || isTablet;

    return ValueListenableBuilder<double>(
      valueListenable: zoomLevel,
      builder: (context, value, child) {
        return Container(
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          constraints: BoxConstraints(
            maxWidth: screenWidth * (isSmall ? 1 : value),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isSmall && showZoomIcon)
                _buildZoomIcon(value, context, zoomLevel),
              Expanded(child: child!),
              // Flexible(fit: FlexFit.loose, child: child!),
            ],
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildZoomIcon(
    double value,
    BuildContext context,
    ValueNotifier<double> zoomLevel,
  ) {
    return IconButton(
      tooltip: value > 1.0 ? 'Zoom Out' : 'Zoom In',
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: (value > 1.0 ? kDangerColor : kGrayBlueColor).toAlpha(
          0.4,
        ),
      ),
      icon:
          Icon(
            semanticLabel: 'zoom',
            color: context.surfaceColor,
            value > 1.0 ? Icons.zoom_out_map : Icons.zoom_in_map,
          ).addNeumorphism(
            topShadowColor: kDangerColor,
            offset: const Offset(1, 1),
          ),
      onPressed: () => zoomLevel.value = value > 1.0 ? 0.5 : 1.2,
    );
  }
}

class CustomDraggableBottomSheet extends StatefulWidget {
  final double? initialChildSize, maxChildSize;
  final Widget child;
  final Widget? header;
  final Function()? onPress;
  final EdgeInsets? padding;
  final bool isScrollable;
  final Color? sheetBgColor;
  final bool confirmOnClose; // Confirm on accidental close of bottom sheet

  const CustomDraggableBottomSheet({
    super.key,
    required this.child,
    this.confirmOnClose = true,
    this.onPress,
    this.padding,
    this.isScrollable = true,
    this.initialChildSize,
    this.maxChildSize,
    this.header,
    this.sheetBgColor,
  });

  @override
  State<CustomDraggableBottomSheet> createState() =>
      _CustomDraggableBottomSheetState();
}

class _CustomDraggableBottomSheetState extends State<CustomDraggableBottomSheet> {
  final GlobalKey _contentKey = GlobalKey();
  bool _isClosing = false;
  double? _initialSize;
  double? _lastExtent;

  double get _maxChildSize => widget.maxChildSize ?? 0.8;

  @override
  void initState() {
    super.initState();
    _determineMinHeight();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _determineMinHeight();
  }

  void _determineMinHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _contentKey.currentContext;
      if (context == null) return;

      final box = context.findRenderObject() as RenderBox;
      if (!box.hasSize) return;

      final contentHeight = box.size.height;
      // Calculate the fraction of the screen the content needs
      double relativeSize = contentHeight / context.screenHeight;

      // Add small buffer for padding, but clamp to min/max
      double value = (relativeSize + 0.18).clamp(0.2, _maxChildSize);

      // prevent DraggableScrollableSheet errors: min shouldn't exceed max
      if (value > _maxChildSize) return;

      setState(() => _initialSize = value);

      // Optional: re-run after a short delay if the content might still change
      // This is useful if images or async widgets are loading
      Future.delayed(const Duration(milliseconds: 100), _determineMinHeight);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget buildSheet() {
      final initialCSize = _initialSize ?? widget.initialChildSize ?? 0.33;
      // final maxCSize = widget.maxChildSize ?? 0.8;

      return NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          // final closeThreshold = notification.minExtent + 0.02;
          final current = notification.extent;
          final isShrinking = _lastExtent != null && current < _lastExtent!;
          _lastExtent = current;

          // if (notification.extent <= notification.minExtent + 0.01)
          final isNearMin = current <= notification.minExtent + 0.015;

          if (isShrinking && isNearMin && !_isClosing) {
            _isClosing = true;
            Future.microtask(() async {
              if (context.mounted) {
                await _confirmClose(context);
                await Future.delayed(const Duration(milliseconds: 300));
                _isClosing = false;
              }
            });
            // _confirmClose(context).then((_) => _isClosing = false);
            return true;
          }
          return false;
        },
        child: makeDismissible(
          context,
          child: DraggableScrollableSheet(
            initialChildSize: initialCSize,
            minChildSize: 0.2,
            maxChildSize: _maxChildSize,
            builder: (cxt, controller) => MediaQuery(
              data: MediaQuery.of(context),
              child: widget.isScrollable
                  ? _buildBody(controller, cxt)
                  : widget.child,
            ),
          ),
        ),
      );
    }

    return buildSheet();
  }

  Widget makeDismissible(BuildContext context, {required Widget child}) {
    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onPress ?? () async => await _confirmClose(context),
      child: GestureDetector(onTap: () {}, child: child),
    );

    return widget.confirmOnClose
        ? _handleWillPopScope(context, child: body)
        : body;
  }

  Future<bool> _confirmClose(BuildContext context) async {
    if (!widget.confirmOnClose) return true;

    final shouldPop = await context.confirmAction(
      Text('Are you sure you want to exit?'),
      title: 'Confirm Exit',
    );

    if (shouldPop && context.mounted) {
      Navigator.of(context).pop();
    }

    return shouldPop;
  }

  PopScope<Object> _handleWillPopScope(
    BuildContext context, {
    required Widget child,
  }) {
    return PopScope(
      canPop: false, // disables default back navigation
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _confirmClose(context);
      },
      child: child,
    );
  }

  Container _buildBody(ScrollController controller, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: widget.padding ?? const EdgeInsets.all(16.00),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        // color: const Color.fromRGBO(0, 0, 0, 0.001),
        color: widget.sheetBgColor ?? context.ofTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.00)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove, color: context.surfaceColor),
          if (widget.header != null) ...{
            widget.header!,
            const HorizontalDivider(),
          },
          Flexible(
            key: _contentKey,
            child: SingleChildScrollView(
              controller: controller,
              child: widget.child,
            ),
          ),
          /*Expanded(
            child: SingleChildScrollView(controller: controller, child: child),
          ),*/
        ],
      ),
    );
  }
}
