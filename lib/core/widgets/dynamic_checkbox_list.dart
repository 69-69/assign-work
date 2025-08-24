import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:flutter/material.dart';

/// Reusable checkbox list with dynamic groups [DynamicCheckboxList]
class DynamicCheckboxList extends StatefulWidget {
  final String? title;
  final bool showButton;
  final List<CheckboxGroupConfig> fieldsConfig;
  final List<Map<String, String>>? initialData;
  final Function(List<Map<String, String>>) onChanged;

  const DynamicCheckboxList({
    super.key,
    required this.fieldsConfig,
    required this.onChanged,
    this.initialData,
    this.title,
    this.showButton = false,
  });

  @override
  State<DynamicCheckboxList> createState() => _DynamicCheckboxListState();
}

class _DynamicCheckboxListState extends State<DynamicCheckboxList> {
  final List<Map<String, bool>> _checkboxGroups = [];

  @override
  void initState() {
    super.initState();
    _initializeGroups();
  }

  void _initializeGroups() {
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      for (final map in widget.initialData!) {
        _checkboxGroups.add({
          for (var config in widget.fieldsConfig)
            config.key: (map[config.key] == 'true'),
        });
      }
    } else {
      _addCheckboxGroup(); // Add at least one group
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
    final title = widget.title;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (title != null) ...[
          Expanded(child: Text(title, style: context.textTheme.titleMedium)),
        ],
        if (!widget.showButton) ...[
          context.iconButton(
            Icons.add,
            isCard: true,
            tooltip: 'Add group',
            onPressed: _addCheckboxGroup,
            iconColor: kPrimaryAccentColor,
            borderColor: kPrimaryAccentColor,
          ),
          if (_checkboxGroups.isNotEmpty)
            context.iconButton(
              Icons.remove,
              isCard: true,
              tooltip: 'Remove group',
              iconColor: kDangerColor,
              bgColor: kLightColor,
              borderColor: kDangerColor,
              onPressed: _removeCheckboxGroup,
            ),
        ],
      ],
    );
  }

  Iterable<Widget> _buildCheckboxGroups() {
    return _checkboxGroups.asMap().entries.expand((entry) {
      // final index = entry.key;
      final group = entry.value;

      // Create list of Checkbox for this group
      final fields = widget.fieldsConfig.map((config) {
        return _buildCheckboxList(group, config);
      }).toList();

      // Logic to group fields into rows
      if (fields.length <= 1) {
        return fields; // Single field per row
      } else {
        return _groupByTwo(fields);
      }
    }).toList();
  }

  CheckboxListTile _buildCheckboxList(
    Map<String, bool> group,
    CheckboxGroupConfig config,
  ) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      value: group[config.key] ?? false,
      title: Row(
        children: [
          Expanded(child: Text(config.label)),
          InkWell(
            onTap: () =>
                _showInfoDialog(context, config.modalTitle, config.description),
            child: const Icon(Icons.info_outline, size: 18),
          ),
        ],
      ),
      onChanged: (value) {
        setState(() => group[config.key] = value ?? false);
        _notifyParent();
      },
    );
  }

  // Group CheckBoxes in rows of 2
  List<Widget> _groupByTwo(List<CheckboxListTile> fields) {
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

  void _addCheckboxGroup() {
    setState(() {
      _checkboxGroups.add({
        for (var config in widget.fieldsConfig) config.key: false,
      });
    });
    _notifyParent();
  }

  void _removeCheckboxGroup() {
    setState(() => _checkboxGroups.removeLast());
    _notifyParent();
  }

  void _notifyParent() {
    final data = _checkboxGroups.map((group) {
      return {
        for (var entry in group.entries) entry.key: entry.value.toString(),
      };
    }).toList();

    widget.onChanged(data);
  }

  Future<void> _showInfoDialog(
    BuildContext cxt,
    String title,
    String desc,
  ) async {
    await cxt.confirmDone(Text(desc), title: title);
  }
}

class CheckboxGroupConfig {
  final String key;
  final String label;
  final String modalTitle;
  final String description;

  CheckboxGroupConfig({
    required this.key,
    required this.label,
    required this.modalTitle,
    required this.description,
  });
}

class CheckboxGroup {
  final Map<String, TextEditingController> controllers;

  CheckboxGroup(
    List<CheckboxGroupConfig> fieldsConfig, {
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
