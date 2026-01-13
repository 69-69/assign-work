import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
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
    this.isRow = true,
    required this.options,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    List<CustomCheckboxTile> radios = _buildOptions();

    return (isRow && radios.length > 1)
        ? Wrap(spacing: 10, runSpacing: 5, children: _groupIntoRows(radios))
        : Column(children: radios);
  }

  List<CustomCheckboxTile> _buildOptions() {
    final radios = options.map((option) {
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
        // selected: RadioGroup.maybeOf<T>(context)?.groupValue == option.value,
      );
    }).toList();

    return radios;
  }

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
