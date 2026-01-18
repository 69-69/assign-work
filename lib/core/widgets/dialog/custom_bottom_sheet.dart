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
              if (!isSmall && showZoomIcon) ...{
                _buildZoomIcon(value, context, zoomLevel),
                const SizedBox(height: 10),
              },
              // Flexible(fit: FlexFit.loose, child: child!),
              Expanded(child: child!),
            ],
          ),
        );
      },
      child: child,
    );
  }

  Align _buildZoomIcon(
    double value,
    BuildContext context,
    ValueNotifier<double> zoomLevel,
  ) {
    return Align(
      alignment: Alignment.topCenter,
      child: IconButton(
        tooltip: value > 1.0 ? 'Zoom Out' : 'Zoom In',
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: LinearBorder.none,
          backgroundColor: (value > 1.0 ? kDangerColor : kGrayBlueColor)
              .toAlpha(0.4),
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
      ),
    );
  }
}

class CustomDraggableBottomSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Widget buildSheet() {
      final initialCSize = initialChildSize ?? 0.33;
      final maxCSize = maxChildSize ?? 0.8;

      return makeDismissible(
        context,
        child: DraggableScrollableSheet(
          initialChildSize: initialCSize,
          minChildSize: 0.2,
          maxChildSize: maxCSize,
          builder: (cxt, controller) => MediaQuery(
            data: MediaQuery.of(context),
            child: isScrollable ? _buildBody(controller, cxt) : child,
          ),
        ),
      );
    }

    return buildSheet();
  }

  Widget makeDismissible(BuildContext context, {required Widget child}) {
    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPress ?? () => Navigator.of(context).pop(),
      child: GestureDetector(onTap: () {}, child: child),
    );

    return confirmOnClose ? _buildWillPopScope(context, child: body) : body;
  }

  PopScope<Object> _buildWillPopScope(
    BuildContext context, {
    required Widget child,
  }) {
    return PopScope(
      canPop: false, // disables default back navigation
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          bool shouldPop = await context.confirmAction(
            Text('Are you sure you want to exit?'),
            title: 'Confirm Exit',
          );
          if (context.mounted && shouldPop) {
            // or pass result: Navigator.of(context).pop(myResult);
            Navigator.of(context).pop();
          }
        }
      },
      child: child,
    );
  }

  Container _buildBody(ScrollController controller, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16.00),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        // color: const Color.fromRGBO(0, 0, 0, 0.001),
        color: sheetBgColor ?? context.ofTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.00)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove, color: context.surfaceColor),
          if (header != null) ...{header!, const HorizontalDivider()},
          Flexible(
            child: SingleChildScrollView(controller: controller, child: child),
          ),
          /*Expanded(
            child: SingleChildScrollView(controller: controller, child: child),
          ),*/
        ],
      ),
    );
  }
}
