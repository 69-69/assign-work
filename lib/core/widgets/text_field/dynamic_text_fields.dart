import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';

enum FieldWidgetType {
  textField,
  custom, // Custom widget
}

class DynamicTextFields extends StatefulWidget {
  final String? title;

  /// [fullWidthKey] Use to specify the key for the full width field, else fallback to the last field
  final String? fullWidthKey;
  final bool showButton;
  final Color? textColor;
  final List<FieldGroupConfig> fieldsConfig;
  final List<Map<String, dynamic>>? initialData;
  final Function(List<Map<String, dynamic>>) onChanged;

  /// Callback to get the total count of fields-group
  final Function(int total)? onCount;

  const DynamicTextFields({
    super.key,
    this.showButton = false,
    required this.fieldsConfig,
    required this.onChanged,
    this.fullWidthKey,
    this.initialData,
    this.textColor,
    this.onCount,
    this.title,
  });

  @override
  State<DynamicTextFields> createState() => _DynamicTextFieldsState();
}

class _DynamicTextFieldsState extends State<DynamicTextFields> {
  final List<FieldGroup> _fieldGroups = [];
  String? get _fullWidthKey => widget.fullWidthKey;

  String? get _title => widget.title;

  @override
  void initState() {
    super.initState();
    _initializeGroups();
  }

  void _initializeGroups() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialData = widget.initialData;

      if (initialData.isNotNullNorEmpty) {
        for (final map in initialData!) {
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
      final fields = widget.fieldsConfig
          .map(
            (config) => config.hideField
                ? const SizedBox.shrink()
                : _buildFieldWidget(group, config, index),
          )
          .toList();

      // Return a single field if there's only one, otherwise group fields into pairs
      return fields.length <= 1 ? fields : _groupByTwo(fields);
    });
  }

  Widget _buildFieldWidget(
    FieldGroup group,
    FieldGroupConfig config,
    int index,
  ) {
    final type = switch (config.widgetType) {
      FieldWidgetType.textField => _buildTextField(group, config, index),
      FieldWidgetType.custom => _buildCustomWidget(config, group),
    };
    return type;
  }

  Widget _buildCustomWidget(FieldGroupConfig config, FieldGroup group) {
    if (config.customBuilder != null) {
      return config.customBuilder!(
        initialData: group.otherValues[config.key],
        onChanged: (value) {
          group.otherValues[config.key] = value;
          _notifyParent();
        },
      );
    }
    return const SizedBox.shrink();
  }

  CustomTextField _buildTextField(
    FieldGroup group,
    FieldGroupConfig config,
    int index,
  ) {
    final key = config.key;
    final inputType = config.type;
    final validator = config.validator;
    final helperText = config.helperText;
    final maxLines = config.isTextArea ? null : 1;
    final labelText = config.label.toTitle;

    final inputDecoration =
        config.inputDecoration ??
        InputDecoration(
          helperText: helperText,
          labelText: labelText,
          suffixIcon: widget.showButton ? _prefixIcon(labelText, index) : null,
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
      minLines: config.minLines ?? 1,
      helperText: helperText,
      inputDecoration: inputDecoration,
      validator: validator,
    );
  }

  Card _prefixIcon(String labelText, int index) {
    return Card(
      color: kGrayColor.toAlpha(0.2),
      elevation: 0,
      child: Tooltip(
        message: '$index: $labelText',
        child: Text(
          '$index',
          textAlign: TextAlign.center,
          style: TextStyle(color: kTextColor, fontSize: 12),
        ),
      ),
    );
  }

  // Group fields in rows of 2
  List<Widget> _groupByTwo(List<Widget> fields) {
    final rows = <Widget>[];
    final total = fields.length;
    int i = 0;

    while (i < total) {
      final bool isFirst = i == 0;
      final bool isLast = i == total - 1;

      final bool isFullWidth =
          (isFirst && widget.fieldsConfig[i].key == _fullWidthKey) ||
          (_fullWidthKey == null && isLast && total.isOdd);

      // Case 1: Full-width field (either first or fallback last)
      if (isFullWidth) {
        rows.add(AdaptiveLayout(children: [fields[i]]));
        i += 1;
      }
      // Case 2: Last field remaining, render it alone
      else if (isLast) {
        rows.add(AdaptiveLayout(children: [fields[i]]));
        i += 1;
      }
      // Case 3: Normal pair
      else {
        rows.add(AdaptiveLayout(children: [fields[i], fields[i + 1]]));
        i += 2;
      }
    }

    // Add divider if multiple field groups
    if (_fieldGroups.length > 1) {
      rows.add(const HorizontalDivider());
    }

    return rows;
  }

  _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_title != null) ...[
          Expanded(
            child: Text(
              _title.toTitle,
              style: context.textTheme.titleMedium?.copyWith(
                color:
                    widget.textColor ?? context.onPrimaryContainer.toAlpha(0.8),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (widget.showButton) ...[
          context.iconButton(
            Icons.add,
            isCard: true,
            tooltip: 'Add more ${_title ?? 'field'} group'.toSentence,
            onPressed: _addTextField,
            iconColor: kPrimaryAccentColor,
            borderColor: kPrimaryAccentColor,
          ),
          if (_fieldGroups.isNotEmpty)
            context.iconButton(
              Icons.remove,
              isCard: true,
              tooltip: 'Remove last ${_title ?? 'field'} group'.toSentence,
              iconColor: kDangerColor,
              bgColor: kWhiteColor,
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
  List<Map<String, dynamic>> getAllData() =>
      _fieldGroups.map((group) => group.getData()).toList();

  @override
  void dispose() {
    for (final group in _fieldGroups) {
      group.dispose();
    }
    super.dispose();
  }
}

class FieldGroupConfig {
  final String key;
  final String label;
  final bool isTextArea;
  final int? minLines;
  final bool hideField;
  final String? helperText;
  final TextInputType type;
  final String? Function(String?)? validator;
  final InputDecoration? inputDecoration;
  final FieldWidgetType widgetType;

  /// Optional custom widget builder
  final Widget Function({
    required dynamic initialData,
    required void Function(dynamic value) onChanged,
  })?
  customBuilder;

  FieldGroupConfig({
    required this.key,
    required this.type,
    required this.label,
    this.isTextArea = false,
    this.minLines,
    this.validator,
    this.helperText,
    this.inputDecoration,
    this.hideField = false,
    this.customBuilder,
    this.widgetType = FieldWidgetType.textField,
  });
}

class FieldGroup {
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> otherValues = {};

  FieldGroup(
    List<FieldGroupConfig> fieldsConfig, {
    Map<String, dynamic>? initialValues,
  }) : controllers = {
         for (var config in fieldsConfig)
           if (config.widgetType == FieldWidgetType.textField)
             config.key: TextEditingController(
               text: initialValues?[config.key]?.toString() ?? '',
             ),
       } {
    for (var config in fieldsConfig) {
      if (config.widgetType != FieldWidgetType.textField) {
        otherValues[config.key] = initialValues?[config.key];
      }
    }
  }

  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Map<String, dynamic> getData() {
    final data = <String, dynamic>{};
    data.addAll({
      for (final entry in controllers.entries) entry.key: entry.value.text,
    });
    data.addAll(otherValues);
    return data;
  }
}

/*
  List<Widget> _groupByTwo2(List<Widget> fields) {
    final rows = <Widget>[];
    final total = fields.length;

    for (var i = 0; i < total; i += 2) {
      final isLast = i == total - 2;
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

      // Only add horizontal divider to the last, If new group is added
      if (i == total - 2 && _fieldGroups.length > 1) {
        rows.add(const HorizontalDivider());
      }
    }

    return rows;
  }


List<Widget> _groupByTwo2(List<CustomTextField> fields) {
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
