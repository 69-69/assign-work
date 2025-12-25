import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:flutter/material.dart';

/// Reusable checkbox list with dynamic groups [DynamicCheckboxList]
class DynamicCheckboxList extends StatefulWidget {
  final String? title;
  final bool showButton;
  final List<Map<String, dynamic>>? initialData;
  final List<CheckboxGroupConfig> checkboxesConfig;
  final Function(List<Map<String, dynamic>>) onCheckChanged;

  const DynamicCheckboxList({
    super.key,
    required this.checkboxesConfig,
    required this.onCheckChanged,
    this.initialData,
    this.title,
    this.showButton = false,
  });

  @override
  State<DynamicCheckboxList> createState() => _DynamicCheckboxListState();
}

class _DynamicCheckboxListState extends State<DynamicCheckboxList> {
  final List<Map<String, bool>> _checkboxGroups = [];

  List<CheckboxGroupConfig> get _configs => widget.checkboxesConfig;

  @override
  void initState() {
    super.initState();
    _initializeGroups();
  }

  void _initializeGroups() {
    if (widget.initialData.isNotNullNorEmpty) {
      for (final groupData in widget.initialData!) {
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
    return Wrap(
      runSpacing: 10,
      children: [_buildHeader(), ..._buildCheckboxGroups()],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.title != null)
          Expanded(
            child: Text(widget.title!, style: context.textTheme.titleMedium),
          ),
        if (widget.showButton) ...[
          context.iconButton(
            Icons.add,
            isCard: true,
            tooltip: 'Add more checkbox group',
            onPressed: _addCheckboxGroup,
            iconColor: kPrimaryAccentColor,
            borderColor: kPrimaryAccentColor,
          ),
          if (_checkboxGroups.isNotEmpty)
            context.iconButton(
              Icons.remove,
              isCard: true,
              tooltip: 'Remove last checkbox group',
              onPressed: _removeCheckboxGroup,
              iconColor: kDangerColor,
              bgColor: kWhiteColor,
              borderColor: kDangerColor,
            ),
        ],
      ],
    );
  }

  List<Widget> _buildCheckboxGroups() {
    return _checkboxGroups.asMap().entries.expand((entry) {
      final group = entry.value;

      final checkboxes = _configs
          .map((config) => _buildCheckbox(group, config))
          .toList();

      return checkboxes.length <= 1 ? checkboxes : _groupIntoRows(checkboxes);
    }).toList();
  }

  CustomCheckboxTile _buildCheckbox(
    Map<String, bool> group,
    CheckboxGroupConfig config,
  ) {
    return CustomCheckboxTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      value: group[config.key] ?? config.selected ?? false,
      title: Row(
        children: [
          Expanded(
            child: Text(
              config.label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
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
      onChanged: (value) {
        setState(() => group[config.key] = value ?? false);
        _notifyParent();
      },
    );
  }

  List<Widget> _groupIntoRows(List<Widget> fields) {
    final rows = <Widget>[];

    for (var i = 0; i < fields.length; i += 2) {
      final isLast = i == fields.length - 1;
      final children = isLast ? [fields[i]] : [fields[i], fields[i + 1]];

      rows.add(AdaptiveLayout(children: children));
      if (!isLast) rows.add(HorizontalDivider(space: 0.1));
    }

    return rows;
  }

  void _addCheckboxGroup() {
    setState(() {
      _checkboxGroups.add({
        for (var config in _configs) config.key: config.selected ?? false,
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
    final List<Map<String, dynamic>> output = [];

    for (var group in _checkboxGroups) {
      for (var config in _configs) {
        output.add({
          'key': config.key,
          'selected': group[config.key] ?? false,
          'data': config.data ?? '',
        });
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
  final String key;
  final String label;
  final T? data;
  final String? tooltip;
  final String description;
  final bool? selected;

  CheckboxGroupConfig({
    required this.key,
    required this.label,
    this.data,
    this.tooltip,
    this.selected,
    required this.description,
  });
}

/*class DynamicCheckboxList extends StatefulWidget {
  final String? title;
  final bool showButton;
  final List<Map<String, dynamic>>? initialData;
  final List<CheckboxGroupConfig> checkboxesConfig;
  final Function(List<Map<String, dynamic>>) onCheckChanged;

  const DynamicCheckboxList({
    super.key,
    required this.checkboxesConfig,
    required this.onCheckChanged,
    this.initialData,
    this.title,
    this.showButton = false,
  });

  @override
  State<DynamicCheckboxList> createState() => _DynamicCheckboxListState();
}

class _DynamicCheckboxListState extends State<DynamicCheckboxList> {
  final List<Set<String>> _checkboxGroups = [];

  List<CheckboxGroupConfig> get _configs => widget.checkboxesConfig;

  @override
  void initState() {
    super.initState();
    _initializeGroups();
  }

  void _initializeGroups() {
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      for (final groupData in widget.initialData!) {
        _checkboxGroups.add({
          for (final config in _configs)
            if (groupData[config.key] == 'true') config.key,
        });
      }
    } else {
      _addCheckboxGroup();
    }
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 10,
      children: [_buildHeader(), ..._buildCheckboxGroups()],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.title != null)
          Expanded(
            child: Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        if (widget.showButton) ...[
          IconButton(
            tooltip: 'Add more checkbox group',
            icon: const Icon(Icons.add),
            onPressed: _addCheckboxGroup,
          ),
          if (_checkboxGroups.isNotEmpty)
            IconButton(
              tooltip: 'Remove last checkbox group',
              icon: const Icon(Icons.remove),
              onPressed: _removeCheckboxGroup,
            ),
        ],
      ],
    );
  }

  List<Widget> _buildCheckboxGroups() {
    return _checkboxGroups.asMap().entries.expand((entry) {
      final index = entry.key;
      final selectedKeys = entry.value;

      final checkboxes = _configs.map((config) {
        return CustomCheckboxList<String>(
          values: selectedKeys,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          onChanged: (values) {
            setState(() => _checkboxGroups[index] = values);
            _notifyParent();
          },
          options: [
            CustomCheckboxModel<String>(
              value: config.key,
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      config.label,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  InkWell(
                    onTap: () => _showInfoDialog(
                      context,
                      config.label,
                      config.description,
                    ),
                    child: Tooltip(
                      message: config.tooltip ?? 'Info',
                      child: const Icon(Icons.info_outline, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList();

      return checkboxes.length <= 1 ? checkboxes : _groupIntoRows(checkboxes);
    }).toList();
  }

  List<Widget> _groupIntoRows(List<Widget> fields) {
    final rows = <Widget>[];

    for (var i = 0; i < fields.length; i += 2) {
      final isLast = i == fields.length - 1;
      final children = isLast ? [fields[i]] : [fields[i], fields[i + 1]];

      rows.add(AdaptiveLayout(children: children));
      if (!isLast) rows.add(HorizontalDivider(space: 0.1));
    }

    return rows;
  }

  void _addCheckboxGroup() {
    setState(() {
      _checkboxGroups.add({
        for (final config in _configs)
          if (config.selected == true) config.key,
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
    final List<Map<String, dynamic>> output = [];

    for (final group in _checkboxGroups) {
      for (final config in _configs) {
        output.add({
          'key': config.key,
          'selected': group.contains(config.key),
          'data': config.data ?? '',
        });
      }
    }

    widget.onCheckChanged(output);
  }

  Future<void> _showInfoDialog(
    BuildContext context,
    String title,
    String description,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}*/
