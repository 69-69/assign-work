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
  final T groupValue;
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
    this.isRow = false,
    required this.options,
    required this.onChanged,
    required this.groupValue,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: isRow
          ? Wrap(spacing: 10, runSpacing: 5, children: _buildList(context))
          : Column(children: _buildList(context)),
    );
  }

  List<CustomRadioBoxTile<dynamic>> _buildList(BuildContext context) {
    return options.map((option) {
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
  }
}

/// A Single Custom Radio button tile.
class CustomRadioBoxTile<T> extends StatelessWidget {
  final T value;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final Color? tileColor;
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
    );
  }
}
