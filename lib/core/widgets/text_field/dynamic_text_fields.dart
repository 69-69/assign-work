import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/block_quote.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';

enum FieldWidgetType {
  textField,
  custom, // Custom widget
  titleOnly, // Just a title
}

class DynamicTextFields extends StatefulWidget {
  final String? title;
  final bool isRepeatable; // enable Add/Remove Controls
  final Color? textColor;
  final List<String>? orText;

  /// [fullWidthKey] Use to specify the key for the full width field, else fallback to the last field
  final String? fullWidthKey;
  final int? fieldGroupsLimit;
  final List<FieldGroupConfig> fieldsConfig;
  final List<Map<String, dynamic>>? initialData;
  final Function(List<Map<String, dynamic>>) onChanged;
  final Future<dynamic> Function()? onLimitReached;

  /// Callback to get the total count of fields-group
  final Function(int total)? onCount;

  const DynamicTextFields({
    super.key,
    this.isRepeatable = false,
    this.fieldGroupsLimit,
    required this.fieldsConfig,
    required this.onChanged,
    this.fullWidthKey,
    this.initialData,
    this.onLimitReached,
    this.textColor,
    this.onCount,
    this.title,
    this.orText,
  });

  @override
  State<DynamicTextFields> createState() => _DynamicTextFieldsState();
}

class _DynamicTextFieldsState extends State<DynamicTextFields> {
  final List<FieldGroup> _fieldGroups = [];

  String? get _title => widget.title;

  bool get _isRepeatable => widget.isRepeatable;

  String? get _fullWidthKey => widget.fullWidthKey;

  int? get _groupsLimit => widget.fieldGroupsLimit;

  int get _fieldGroupsLength => _fieldGroups.length;

  List<FieldGroupConfig> get _fieldsConfig => widget.fieldsConfig;

  bool get _showSuffixCount => _isRepeatable && _fieldGroupsLength > 1;

  Future<dynamic> Function()? get _onLimitReached => widget.onLimitReached;

  bool _canAddMoreGroups = true;

  List<String>? get _orTexts => widget.orText;

  @override
  void initState() {
    super.initState();
    _initializeGroups();
  }

  void _initializeGroups() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialData = widget.initialData;

      if (initialData.hasValue) {
        for (final map in initialData!) {
          _fieldGroups.add(FieldGroup(_fieldsConfig, initialValues: map));
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

  /// Builds all field groups and orchestrates layout & decoration
  Iterable<Widget> _buildFieldGroups() {
    return _fieldGroups.asMap().entries.expand((entry) {
      final groupIndex = entry.key;
      final index = groupIndex + 1;

      final widgets = _buildSingleGroup(entry.value, index);

      return _withGroupSeparator(widgets, groupIndex, index);
    });
  }

  /// Adds a visual separator between repeated field groups
  Iterable<Widget> _withGroupSeparator(
    List<Widget> widgets,
    int groupIndex,
    int index,
  ) {
    if (groupIndex < _fieldGroups.length - 1) {
      final i = index + 1;
      final ranColor = randomBgColors[index];
      final orText = _orTexts?[index] ?? 'Form Group $i';

      return [
        ...widgets,
        BlockQuote(
          margin: EdgeInsets.zero,
          blockColor: ranColor,
          child: Tooltip(
            message: orText.toSentence,
            child: HorizontalDivider(
              thickness: 2,
              isORSeparator: true,
              txtColor: ranColor,
              orText: orText,
            ),
          ),
        ),
      ];
    }
    return widgets;
  }

  /// Builds widgets for a single repeated fieldsConfig group
  List<Widget> _buildSingleGroup(FieldGroup group, int index) {
    final result = <Widget>[];
    final buffer = <Widget>[];

    for (final config in _fieldsConfig) {
      /// Skip fields that are permanently hidden.
      if (config.isHidden) continue;

      /// current row data
      final currentData = group.getData(_fieldsConfig);
      /*final currentData = {
        ...group.getData(_fieldsConfig),
        ...group.otherValues,
      };*/
      /// Whether the field should be rendered in the UI
      /// based on the current form/group data.
      final shouldRender = config.visibleWhen?.call(currentData) ?? true;

      if (!shouldRender) continue;

      final widget = _buildFieldWidget(group, config, index);

      if (config.widgetType == FieldWidgetType.titleOnly) {
        _flushBuffer(buffer, result);
        result.add(AdaptiveLayout(children: [widget]));
      } else {
        buffer.add(widget);
      }
    }

    _flushBuffer(buffer, result);
    return result;
  }

  /// Flushes buffered pairable fields into the result list
  void _flushBuffer(List<Widget> buffer, List<Widget> target) {
    if (buffer.isEmpty) return;
    target.addAll(buffer.length <= 1 ? buffer : _groupByTwo(buffer));
    buffer.clear();
  }

  Widget _buildFieldWidget(
    FieldGroup group,
    FieldGroupConfig config,
    int index,
  ) {
    final type = switch (config.widgetType) {
      FieldWidgetType.textField => _buildTextField(group, config, index),
      FieldWidgetType.custom => _buildCustomWidget(config, group, index),
      FieldWidgetType.titleOnly => _buildTitleOnly(config),
    };
    return type;
  }

  Widget _buildTitleOnly(FieldGroupConfig config) {
    return BlockQuote(
      isColored: false,
      margin: EdgeInsets.only(top: 5.0),
      child: RichText(
        text: TextSpan(
          style: context.textTheme.titleMedium?.copyWith(
            color: widget.textColor ?? context.onPrimaryContainer.toAlpha(0.8),
          ),
          children: [
            TextSpan(text: config.label.toTitle),
            if (config.helperText != null) ...{
              TextSpan(
                text: '\n${config.helperText.toSentence}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: widget.textColor ?? context.onSecondaryContainer,
                ),
              ),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildCustomWidget(
    FieldGroupConfig config,
    FieldGroup group,
    int index,
  ) {
    if (config.customBuilder != null) {
      return Row(
        children: [
          Expanded(
            child: config.customBuilder!(
              initialData: group.otherValues[config.key],
              onChanged: (v) {
                if(mounted){
                  setState(() => group.otherValues[config.key] = v);
                }
                _notifyParent();
              },
            ),
          ),
          ?_showSuffixCount
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: _suffixCount(config.label.toTitle, index),
                )
              : null,
        ],
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
          suffixIcon: _showSuffixCount ? _suffixCount(labelText, index) : null,
          suffixIconConstraints: const BoxConstraints(
            minHeight: 26,
            minWidth: 26,
            maxWidth: 30,
          ),
        );

    return CustomTextField(
      isAutoGrow: config.isAutoGrow,
      maxHeight: config.maxHeight,
      enable: !config.isDisabled,
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

  /// [_suffixCount] Add field count suffix to the end of the label
  Card _suffixCount(String labelText, int index, {double alpha = 0.2}) {
    return Card(
      color: kGrayColor.toAlpha(alpha),
      elevation: 0,
      child: Tooltip(
        message: '$index: $labelText',
        child: Text(
          '$index',
          textAlign: TextAlign.center,
          style: TextStyle(color: kTextColor, fontSize: 11),
        ),
      ),
    );
  }

  // Group fields in rows of 2.
  // Also expand the last field if odd,
  // and expand first if fullWidthKey is provided.
  List<Widget> _groupByTwo(List<Widget> fields) {
    final rows = <Widget>[];
    final total = fields.length;
    int i = 0;

    while (i < total) {
      /*final bool isFirst = i == 0;
      final bool isLast = i == total - 1;

      final bool isFullWidth = (isFirst && _fieldsConfig[i].key == _fullWidthKey); // last field expands if odd

      // Case 1: Full-width field (either first or fallback last)
      if (isFullWidth || (isLast && total.isOdd && _fullWidthKey == null)) {
        rows.add(AdaptiveLayout(children: [fields[i]]));
        i += 1;
      }*/
      final bool isLast = i == total - 1;

      // Should this field be full width based on provided fullWidthKey
      final bool isFullWidth = _fieldsConfig[i].key == _fullWidthKey;

      // Case 1: Full-width field (based on key or fallback to LAST-FIELD if its odd)
      if (isFullWidth || (isLast && total.isOdd && _fullWidthKey == null)) {
        rows.add(AdaptiveLayout(children: [fields[i]]));
        i += 1;
      }
      // Case 2: LAST-FIELD remaining, render it alone (if its only a SINGLE-FIELD)
      else if (isLast) {
        rows.add(AdaptiveLayout(children: [fields[i]]));
        i += 1;
      }
      // Case 3: Normal pair of fields
      else {
        rows.add(AdaptiveLayout(children: [fields[i], fields[i + 1]]));
        i += 2;
      }
    }

    // Add divider if multiple field groups
    if (_fieldGroupsLength > 1) {
      rows.add(const HorizontalDivider());
    }

    return rows;
  }

  Widget _buildHeader(BuildContext context) {
    final addColor = _canAddMoreGroups ? kPrimaryAccentColor : kGrayColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_title != null) ...[
          Expanded(
            child: Text(
              "${_title.toTitle} ${_isRepeatable ? '[$_fieldGroupsLength]' : ''}",
              style: context.textTheme.titleMedium?.copyWith(
                color:
                    widget.textColor ?? context.onPrimaryContainer.toAlpha(0.8),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_isRepeatable) ...[
          if (_fieldGroupsLength > 1) ...{
            context.iconButton(
              Icons.remove,
              isCard: true,
              iconColor: kDangerColor,
              bgColor: kWhiteColor,
              borderColor: kDangerColor,
              tooltip: 'Remove last ${_title ?? 'field'} group'.toSentence,
              onPressed: _removeTextField,
            ),
          },
          context.iconButton(
            Icons.add,
            isCard: true,
            iconColor: addColor,
            borderColor: addColor,
            tooltip: _canAddMoreGroups
                ? 'Add more ${_title ?? 'field'} group'.toSentence
                : 'Can\'t add',
            onPressed: _canAddMoreGroups ? _addTextField : _onLimitReached,
          ),
        ],
      ],
    );
  }

  // Add a new set of fields
  void _addTextField() {
    // Enforce limit strictly
    if (!_canAddMoreGroups) return;

    setState(() {
      _fieldGroups.add(FieldGroup(_fieldsConfig));
      // Check if we can add more groups: either by limit or by length
      _canAddMoreGroups =
          _groupsLimit == null || _fieldGroupsLength < _groupsLimit!;
    });
    _notifyParent();
  }

  // Remove the last set of fields
  void _removeTextField() {
    setState(() {
      _fieldGroups.removeLast();
      _canAddMoreGroups = true;
    });
    _notifyParent();
  }

  // Notify the parent about the data change
  void _notifyParent() {
    // get count of fields
    if (widget.onCount != null) {
      widget.onCount!(_fieldGroupsLength);
    }
    widget.onChanged(getAllData());
  }

  // Collect all data in a list of maps (one map per set of fields)
  List<Map<String, dynamic>> getAllData() =>
      _fieldGroups.map((group) => group.getData(_fieldsConfig)).toList();

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
  final String? helperText;
  final TextInputType type;
  final String? Function(String?)? validator;
  final InputDecoration? inputDecoration;
  final FieldWidgetType widgetType;
  /// [isHidden] Whether the field is permanently hidden from the UI.
  final bool isHidden;
  /// Determines whether the field should be rendered
  /// based on the current form/group data.
  /// [visibleWhen]
  /// Return `true` to show the field, or `false` to hide it.
  final bool Function(Map<String, dynamic> data)? visibleWhen;

  /// Indicates that this field contains a nested list of key-value pairs
  /// (e.g., `[{ "key": "isAutoApply", "value": true }]`) in `otherValues`.
  /// When `true`, `getData()` will flatten these into top-level keys.
  final bool isNested;

  /// [initialValue] Initial value of the text field
  final String? initialValue;

  /// [isDisabled] Enable/Disable text field
  final bool isDisabled;

  /// [isAutoGrow] Auto-Wrap + Grow text field
  final bool isAutoGrow;

  /// [maxHeight] Max height of the Auto-Grow text field
  final double maxHeight;

  /// Optional custom widget builder for non text-fields
  /// e.g., CustomButton or CustomDropdown
  final Widget Function({
    required dynamic initialData,
    required void Function(dynamic) onChanged,
  })?
  customBuilder;

  FieldGroupConfig({
    required this.key,
    this.type = TextInputType.none,
    required this.label,
    this.isTextArea = false,
    this.minLines,
    this.validator,
    this.helperText,
    this.initialValue,
    this.inputDecoration,
    this.isHidden = false,
    this.isNested = false,
    this.isDisabled = false,
    this.isAutoGrow = false,
    this.maxHeight = 100,
    this.customBuilder,
    this.widgetType = FieldWidgetType.textField,
    this.visibleWhen,
  });
}

class FieldGroup {
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> otherValues = {};

  FieldGroup(
    List<FieldGroupConfig> fieldsConfig, {
    Map<String, dynamic>? initialValues,
  }) : controllers = {
         for (var cf in fieldsConfig)
           if (cf.widgetType == FieldWidgetType.textField)
             cf.key: TextEditingController(
               text:
                   cf.initialValue ?? initialValues?[cf.key]?.toString() ?? '',
             ),
       } {
    for (var cf in fieldsConfig) {
      if (cf.widgetType != FieldWidgetType.textField) {
        otherValues[cf.key] = initialValues?[cf.key];
      }
    }
  }

  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Map<String, dynamic> getData(List<FieldGroupConfig> fieldsConfig) {
    final data = <String, dynamic>{};

    // Text fields
    data.addAll({for (final e in controllers.entries) e.key: e.value.text});

    for (final cf in fieldsConfig) {
      if (cf.widgetType != FieldWidgetType.textField) {
        final val = otherValues[cf.key];
        if (val == null) continue;

        cf.isNested && val is List
            ? _flattenNest(data, val)
            : data[cf.key] = val;
      }
    }

    return data;
  }

  /// Flatten a nested list of key-value maps into the parent map.
  /// Example: [{"name": "GST", "taxOptions":[{"key":"isAutoApply","value":true}]}]
  /// becomes: [{"name": "GST", "isAutoApply":true}]
  void _flattenNest(Map<String, dynamic> target, List values) {
    for (final m in values.whereType<Map>()) {
      final k = m['key'];
      if (k != null) {
        target[k] = m['value'];
      }
    }
  }
}

