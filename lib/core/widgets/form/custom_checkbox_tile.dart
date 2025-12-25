import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/* USAGE:
 Set<String> selectedValues = {'apple'};

 CustomCheckboxList<String>(
    values: selectedValues,
  onChanged: (newValues) {
    setState(() => selectedValues = newValues);
  },
  options: const [
    CustomCheckboxModel(
      value: 'apple',
      title: Text('Apple'),
    ),
    CustomCheckboxModel(
      value: 'banana',
      title: Text('Banana'),
    ),
  ],
) */

class CustomCheckboxModel<T> {
  final T value;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;

  CustomCheckboxModel({
    required this.value,
    required this.title,
    this.subtitle,
    this.secondary,
  });
}

/// A List of Checkboxes.
class CustomCheckboxList<T> extends StatelessWidget {
  final bool isRow;
  final Set<T> values;
  final Color? tileColor;
  final EdgeInsetsGeometry? padding;
  final ValueChanged<Set<T>> onChanged;
  // List of choices in the check boxes
  final List<CustomCheckboxModel<T>> options;
  final WidgetStateProperty<Color?>? fillColor;

  const CustomCheckboxList({
    super.key,
    this.padding,
    this.tileColor,
    this.fillColor,
    this.isRow = false,
    required this.options,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final children = _buildList(context);

    return isRow
        ? Wrap(spacing: 10, runSpacing: 5, children: children)
        : Column(children: children);
  }

  List<Widget> _buildList(BuildContext context) {
    return options.map((option) {
      final isChecked = values.contains(option.value);

      return CustomCheckboxTile(
        tileColor: tileColor,
        fillColor: fillColor,
        contentPadding: padding,
        value: isChecked,
        title: option.title,
        subtitle: option.subtitle,
        secondary: option.secondary,
        onChanged: (checked) => _onChanged(checked, option),
      );
    }).toList();
  }

  void _onChanged(bool? checked, CustomCheckboxModel<dynamic> option) {
    final newValues = Set<T>.from(values);

    if (checked == true) {
      newValues.add(option.value);
    } else {
      newValues.remove(option.value);
    }

    onChanged(newValues);
  }
}

/// A Single Custom Checkbox Tile.
class CustomCheckboxTile extends StatelessWidget {
  final bool value;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final ValueChanged<bool?>? onChanged;
  final Color? tileColor;
  final Color? activeColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? contentPadding;
  final WidgetStateProperty<Color?>? fillColor;

  const CustomCheckboxTile({
    super.key,
    required this.value,
    required this.title,
    this.subtitle,
    this.secondary,
    this.onChanged,
    this.tileColor,
    this.contentPadding,
    this.activeColor,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile.adaptive(
      dense: true,
      tileColor: tileColor,
      fillColor: fillColor,
      activeColor: activeColor,
      contentPadding: contentPadding,
      value: value,
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      onChanged: onChanged,
      side: BorderSide(color: borderColor ?? context.onSecondaryContainer),
    );
  }
}
