import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:flutter/material.dart';

class CustomRadioModel<T> {
  final T value;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;

  CustomRadioModel({
    required this.value,
    required this.title,
    this.subtitle,
    this.secondary,
  });
}

class CustomRadioList<T> extends StatelessWidget {
  final bool isRow;
  final T? groupValue;
  final Color? tileColor;
  final ValueChanged<T?> onChanged;
  final EdgeInsetsGeometry? padding;
  // List of choices in the radio buttons
  final List<CustomRadioModel<T>> options;
  final WidgetStateProperty<Color?>? fillColor;

  const CustomRadioList({
    super.key,
    this.padding,
    this.tileColor,
    this.fillColor,
    this.isRow = true,
    required this.options,
    required this.onChanged,
    required this.groupValue,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    List<CustomRadioBoxTile<T>> radios = _buildOptions();

    return (isRow && radios.length > 1)
        ? Wrap(spacing: 10, runSpacing: 5, children: _groupIntoRows(radios))
        : Column(children: radios);
  }

  List<CustomRadioBoxTile<T>> _buildOptions() {
    final radios = options.map((option) {
      return CustomRadioBoxTile<T>(
        tileColor: tileColor,
        fillColor: fillColor,
        contentPadding: padding,
        value: option.value,
        title: option.title,
        subtitle: option.subtitle,
        secondary: option.secondary,
        // selected: RadioGroup.maybeOf<T>(context)?.groupValue == option.value,
      );
    }).toList();

    return radios;
  }

  // Group radios into rows if more than one
  List<Widget> _groupIntoRows(List<Widget> fields) {
    final rows = <Widget>[];

    for (var i = 0; i < fields.length; i += 2) {
      final isLast = i == fields.length - 1;
      final children = isLast ? [fields[i]] : [fields[i], fields[i + 1]];

      rows.add(AdaptiveLayout(children: children));
      if (!isLast) {
        rows.add(SizedBox(height: 4));
      }
    }

    return rows;
  }
}

/// A Single Custom Radio button tile.
class CustomRadioBoxTile<T> extends StatelessWidget {
  final T value;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final Color? tileColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? contentPadding;
  final WidgetStateProperty<Color?>? fillColor;

  const CustomRadioBoxTile({
    super.key,
    required this.value,
    required this.title,
    this.subtitle,
    this.secondary,
    this.tileColor,
    this.fillColor,
    this.borderColor,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>.adaptive(
      dense: true,
      tileColor: tileColor,
      fillColor: fillColor,
      contentPadding: contentPadding,
      value: value,
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      selected: RadioGroup.maybeOf<T>(context)?.groupValue == value,
      radioSide: BorderSide(color: borderColor ?? context.onSecondaryContainer),
    );
  }
}
