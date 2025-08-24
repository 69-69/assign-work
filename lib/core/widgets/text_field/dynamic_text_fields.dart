import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';

class DynamicTextFields extends StatefulWidget {
  final String? title;
  final Color? textColor;
  final bool showButton;
  final List<FieldConfig> fieldsConfig;
  final List<Map<String, String>>? initialData;
  final Function(List<Map<String, String>>) onChanged;

  /// Callback to get the total count of fields-group
  final Function(int total)? onCount;

  const DynamicTextFields({
    super.key,
    this.showButton = false,
    required this.fieldsConfig,
    required this.onChanged,
    this.onCount,
    this.initialData,
    this.textColor,
    this.title,
  });

  @override
  State<DynamicTextFields> createState() => _DynamicTextFieldsState();
}

class _DynamicTextFieldsState extends State<DynamicTextFields> {
  final List<FieldGroup> _fieldGroups = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialData != null && widget.initialData!.isNotEmpty) {
        for (final map in widget.initialData!) {
          _fieldGroups.add(FieldGroup(widget.fieldsConfig, initialValues: map));
        }
      } else {
        _addTextField(); // Default blank field group
      }
      _notifyParent(); // Always notify after init
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 10,
      children: [_buildHeader(context), ..._buildFieldGroups()],
    );
  }

  Iterable<Widget> _buildFieldGroups() {
    return _fieldGroups.asMap().entries.expand((entry) {
      final index = entry.key + 1;
      final group = entry.value;

      // Create list of TextFields for this group
      final fields = widget.fieldsConfig.map((config) {
        return _buildTextField(group, config, index);
      }).toList();

      // Logic to group fields into rows
      if (fields.length <= 1) {
        return fields; // Single field per row
      } else {
        return _groupByTwo(fields);
      }
    });
  }

  CustomTextField _buildTextField(
    FieldGroup group,
    FieldConfig config,
    int index,
  ) {
    final key = config.key;
    final inputType = config.type;
    final helperText = config.helperText;
    final maxLines = config.maxLines ?? 1;
    final labelText = key.separateWord.toTitleCase;

    final inputDecoration =
        config.inputDecoration ??
        InputDecoration(
          helperText: helperText,
          labelText: labelText,
          suffixIcon: _prefixIcon(labelText, index),
          suffixIconConstraints: const BoxConstraints(
            minHeight: 26,
            minWidth: 26,
            maxWidth: 30,
          ),
        );

    return CustomTextField(
      controller: group.controllers[key],
      keyboardType: inputType,
      onChanged: (_) => _notifyParent(),
      maxLines: maxLines,
      helperText: helperText,
      inputDecoration: inputDecoration,
    );
  }

  Card _prefixIcon(String labelText, int index) {
    return Card(
      color: kGrayColor.toAlpha(0.2),
      elevation: 0,
      child: Tooltip(
        message: '$labelText $index',
        child: Text(
          '$index',
          textAlign: TextAlign.center,
          style: TextStyle(color: kTextColor, fontSize: 12),
        ),
      ),
    );
  }

  // Group fields in rows of 2
  List<Widget> _groupByTwo(List<CustomTextField> fields) {
    final rows = <Widget>[];
    final total = fields.length;

    for (var i = 0; i < total; i += 2) {
      final isLast = i == total - 1;
      final isOdd = total % 2 != 0;

      rows.add(
        AdaptiveLayout(
          children: [
            if (isLast && isOdd) ...[
              fields[i], // Make last field full-width
            ] else ...[
              fields[i],
              if (i + 1 < total) fields[i + 1],
            ],
          ],
        ),
      );
    }

    return rows;
  }

  _buildHeader(BuildContext context) {
    var title = widget.title;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (title != null) ...[
          Expanded(
            child: Text(
              title.toTitleCase,
              style: context.textTheme.titleMedium?.copyWith(
                color: widget.textColor ?? kPrimaryColor.toAlpha(0.8),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (!widget.showButton) ...[
          context.iconButton(
            Icons.add,
            isCard: true,
            tooltip: 'Add more fields',
            onPressed: _addTextField,
            iconColor: kPrimaryAccentColor,
            borderColor: kPrimaryAccentColor,
          ),
          if (_fieldGroups.isNotEmpty)
            context.iconButton(
              Icons.remove,
              isCard: true,
              tooltip: 'Remove last field',
              iconColor: kDangerColor,
              bgColor: kLightColor,
              borderColor: kDangerColor,
              onPressed: _removeTextField,
            ),
        ],
      ],
    );
  }

  // Add a new set of fields
  void _addTextField() {
    setState(() => _fieldGroups.add(FieldGroup(widget.fieldsConfig)));
    _notifyParent();
  }

  // Remove the last set of fields
  void _removeTextField() {
    setState(() => _fieldGroups.removeLast());
    _notifyParent();
  }

  // Notify the parent about the data change
  void _notifyParent() {
    // get count of fields
    if (widget.onCount != null) {
      widget.onCount!(_fieldGroups.length);
    }
    widget.onChanged(getAllData());
  }

  // Collect all data in a list of maps (one map per set of fields)
  List<Map<String, String>> getAllData() =>
      _fieldGroups.map((group) => group.getData()).toList();

  @override
  void dispose() {
    for (final group in _fieldGroups) {
      group.dispose();
    }
    super.dispose();
  }
}

class FieldConfig {
  final String key;
  final TextInputType type;
  final int? maxLines;
  final String? helperText;
  final InputDecoration? inputDecoration;

  FieldConfig({
    required this.key,
    required this.type,
    this.maxLines,
    this.helperText,
    this.inputDecoration,
  });
}

class FieldGroup {
  final Map<String, TextEditingController> controllers;

  FieldGroup(
    List<FieldConfig> fieldsConfig, {
    Map<String, String>? initialValues,
  }) : controllers = {
         for (var config in fieldsConfig)
           config.key: TextEditingController(
             text: initialValues?[config.key] ?? '',
           ),
       };

  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Map<String, String> getData() {
    return {
      for (final entry in controllers.entries) entry.key: entry.value.text,
    };
  }
}

/*List<Widget> _groupByTwo2(List<CustomTextField> fields) {
    final rows = <Widget>[];
    for (var i = 0; i < fields.length; i += 2) {
      rows.add(
        AdaptiveLayout(
          children: [
            fields[i],
            if (i + 1 < fields.length) fields[i + 1],
            if (i + 1 >= fields.length) const Spacer(), // Fill gap if odd
          ],
        ),
      );
    }
    return rows;
  }*/
