import 'package:assign_erp/core/widgets/layout/custom_scroll_bar.dart';
import 'package:flutter/material.dart';

extension ColumnRowBuilder on BuildContext {
  /// Column Builder can be used instead of a ListView [columnBuilder]
  columnBuilder({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    MainAxisAlignment? mainAxisAlignment,
    CrossAxisAlignment? crossAxisAlignment,
    VerticalDirection? verticalDirection,
    MainAxisSize? mainAxisSize,
    TextDirection? textDirection,
    ScrollController? controller,
    bool isScrollable = true,
    Axis? scrollDirection,
    Widget? optWidget, // Optional widget to add at the end
  }) {
    var column = Column(
      mainAxisSize: mainAxisSize ?? MainAxisSize.max,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      verticalDirection: verticalDirection ?? VerticalDirection.down,
      textDirection: textDirection,
      children: [
        ...List.generate(itemCount, (index) => itemBuilder(this, index)),
        if (optWidget != null) optWidget,
      ],
    );
    return isScrollable
        ? CustomScrollBar(
            controller: controller ?? ScrollController(),
            scrollDirection: scrollDirection ?? Axis.vertical,
            child: column,
          )
        : column;
  }

  /// rowBuilder Builder can be used instead of a ListView [rowBuilder]
  rowBuilder({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    MainAxisAlignment? mainAxisAlignment,
    CrossAxisAlignment? crossAxisAlignment,
    VerticalDirection? verticalDirection,
    MainAxisSize? mainAxisSize,
    TextDirection? textDirection,
    ScrollController? controller,
    bool isScrollable = true,
    Axis? scrollDirection,
    Widget? optWidget, // Optional widget to add at the end
  }) {
    var row = Row(
      mainAxisSize: mainAxisSize ?? MainAxisSize.max,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      verticalDirection: verticalDirection ?? VerticalDirection.down,
      textDirection: textDirection,
      children: [
        ...List.generate(itemCount, (index) => itemBuilder(this, index)),
        if (optWidget != null) optWidget,
      ],
    );
    return isScrollable
        ? CustomScrollBar(
            controller: controller ?? ScrollController(),
            scrollDirection: scrollDirection ?? Axis.horizontal,
            child: row,
          )
        : row;
  }
}
