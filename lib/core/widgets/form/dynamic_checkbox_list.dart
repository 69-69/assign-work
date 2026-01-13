import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:flutter/material.dart';

/// Reusable checkbox list with dynamic groups [DynamicCheckboxList]
class DynamicCheckboxList extends StatefulWidget {
  final String? title;
  final bool showButton;
  final List<Map<String, dynamic>>? initialData;
  final List<CheckboxGroupConfig> checkboxesConfig;
  final Function(List<CheckboxGroupConfig>) onCheckChanged;

  const DynamicCheckboxList({
    super.key,
    required this.checkboxesConfig,
    required this.onCheckChanged,
    this.showButton = false,
    this.initialData,
    this.title,
  });

  @override
  State<DynamicCheckboxList> createState() => _DynamicCheckboxListState();
}

class _DynamicCheckboxListState extends State<DynamicCheckboxList> {
  final List<Map<String, bool>> _checkboxGroups = [];

  List<CheckboxGroupConfig> get _configs => widget.checkboxesConfig;

  List<Map<String, dynamic>>? get _initialData => widget.initialData;

  @override
  void initState() {
    super.initState();
    _initializeGroups();
  }

  void _initializeGroups() {
    if (_initialData.hasValue) {
      for (final groupData in _initialData!) {
        _checkboxGroups.add({
          for (final config in _configs)
            config.key: (groupData[config.key] == 'true'),
        });
      }
    } else {
      _addCheckboxGroup();
    }
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    final options = _buildOptionsWithInfo(context);

    return Wrap(
      runSpacing: 10,
      children: [_buildHeader(), ..._buildCheckboxGroups(options)],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.title != null) ...[
          Expanded(
            child: Text(widget.title!, style: context.textTheme.titleMedium),
          ),
        ],
        if (widget.showButton) ...[
          if (_checkboxGroups.length > 1) ...{
            context.iconButton(
              Icons.remove,
              isCard: true,
              tooltip: 'Remove last checkbox group',
              onPressed: _removeCheckboxGroup,
              iconColor: kDangerColor,
              bgColor: kWhiteColor,
              borderColor: kDangerColor,
            ),
          },
          context.iconButton(
            Icons.add,
            isCard: true,
            tooltip: 'Add more checkbox group',
            onPressed: _addCheckboxGroup,
            iconColor: kPrimaryAccentColor,
            borderColor: kPrimaryAccentColor,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildCheckboxGroups(List<CustomCheckboxModel<String>> options) {
    return _checkboxGroups.map((group) {
      final selectedValues = _getSelectedKeys(group);

      return CustomCheckboxList<String>(
        values: selectedValues,
        options: options,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        onChanged: (newValues) {
          setState(() {
            _updateGroupFromSelected(group, newValues);
          });
          _notifyParent();
        },
      );
    }).toList();
  }

  /// Helper to build the options for each checkbox
  List<CustomCheckboxModel<String>> _buildOptionsWithInfo(
    BuildContext context,
  ) {
    return _configs.map((config) {
      return CustomCheckboxModel<String>(
        value: config.key,
        title: Row(
          children: [
            Expanded(
              child: Text(
                config.label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (config.description.isNotEmpty)
              InkWell(
                onTap: () =>
                    _showInfoDialog(context, config.label, config.description),
                child: Tooltip(
                  message: config.tooltip ?? 'Info',
                  child: const Icon(Icons.info_outline, size: 18),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  /// Extract the keys that are selected from a group
  Set<String> _getSelectedKeys(Map<String, bool> group) {
    return group.entries.where((e) => e.value).map((e) => e.key).toSet();
  }

  /// Update a group's values from the selected keys
  void _updateGroupFromSelected(
    Map<String, bool> group,
    Set<String> selectedKeys,
  ) {
    for (final key in group.keys) {
      group[key] = selectedKeys.contains(key);
    }
  }

  void _addCheckboxGroup() {
    setState(() {
      _checkboxGroups.add({
        for (var config in _configs) config.key: config.selected,
      });
    });
    _notifyParent();
  }

  void _removeCheckboxGroup() {
    setState(() {
      if (_checkboxGroups.isNotEmpty) {
        _checkboxGroups.removeLast();
      }
    });
    _notifyParent();
  }

  void _notifyParent() {
    final List<CheckboxGroupConfig> output = [];

    for (var group in _checkboxGroups) {
      for (var config in _configs) {
        final checkboxConfig = CheckboxGroupConfig(
          key: config.key,
          label: config.label,
          data: config.data,
          selected: group[config.key] ?? false,
          tooltip: config.tooltip,
          description: config.description,
        );
        output.add(checkboxConfig);
      }
    }

    widget.onCheckChanged(output);
  }

  Future<void> _showInfoDialog(
    BuildContext context,
    String title,
    String description,
  ) async => await context.confirmDone(Text(description), title: title);
}

class CheckboxGroupConfig<T> {
  final T? data;
  final String key;
  final String label;
  final bool selected;
  final String? tooltip;
  final String description;

  CheckboxGroupConfig({
    this.data,
    this.tooltip,
    required this.key,
    required this.label,
    this.selected = false,
    required this.description,
  });

  factory CheckboxGroupConfig.fromMap(Map<String, dynamic> map) =>
      CheckboxGroupConfig(
        key: map['key'],
        label: map['label'],
        data: map['data'],
        selected: map['selected'],
        tooltip: map['tooltip'],
        description: map['description'],
      );

  Map<String, dynamic> toMap() => {
    'key': key,
    'label': label,
    'data': data,
    'selected': selected,
    'tooltip': tooltip,
    'description': description,
  };

  static List<Map<String, dynamic>> mapCheckboxes(List<dynamic>? map) {
    final converted = (map ?? []).map((e) {
      if (e is CheckboxGroupConfig) {
        return {'key': e.key, 'value': e.selected};
      }
      return e as Map<String, dynamic>;
    }).toList();

    return converted;
  }

  static CheckboxGroupConfig empty = CheckboxGroupConfig(
    key: '',
    label: '',
    description: '',
  );
}
