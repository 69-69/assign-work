import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/form/custom_radio_tile.dart';
import 'package:flutter/material.dart';

/// Reusable radio list with dynamic groups [DynamicRadioList]
/// @TODO - This [DynamicRadioList] was upgraded due to Flutter 3.38
class DynamicRadioList extends StatefulWidget {
  final String? title;
  final List<RadioGroupConfig> radiosConfig;
  final List<Map<String, dynamic>>? initialData;
  final Function(List<Map<String, dynamic>>) onChanged;

  const DynamicRadioList({
    super.key,
    required this.radiosConfig,
    required this.onChanged,
    this.initialData,
    this.title,
  });

  @override
  State<DynamicRadioList> createState() => _DynamicRadioListState();
}

class _DynamicRadioListState extends State<DynamicRadioList> {
  String? _selectedKey;

  List<RadioGroupConfig> get _radiosConfig => widget.radiosConfig;

  String? get _title => widget.title;

  @override
  void initState() {
    super.initState();
    _initializeSelectedKey();
  }

  void _initializeSelectedKey() {
    final initialData = widget.initialData;

    if (initialData.isNotNullNorEmpty) {
      final selectedItem = initialData!.firstWhere(
        (map) => map['selected'] == true,
        orElse: () => {},
      );
      _selectedKey = selectedItem['key'] as String?;
    } else {
      _selectedKey = _radiosConfig
          .firstWhere(
            (config) => config.defaultSelected,
            orElse: () => _radiosConfig.first,
          )
          .key;
    }

    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 10,
      children: [
        if (_title != null) ...[
          Text(_title!, style: context.textTheme.titleMedium),
        ],
        _buildCustomRadioList(),
      ],
    );
  }

  Widget _buildCustomRadioList() {
    // Map RadioGroupConfig to CustomRadioModel<String>
    final options = _radiosConfig.map((config) {
      return CustomRadioModel<String>(
        value: config.key,
        title: Row(
          children: [
            Expanded(
              child: Text(
                config.label,
                style: const TextStyle(fontWeight: FontWeight.w400),
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
      );
    }).toList();

    return CustomRadioList<String>(
      groupValue: _selectedKey ?? '',
      onChanged: (value) {
        setState(() {
          _selectedKey = value;
          _notifyParent();
        });
      },
      options: options,
      tileColor: kDangerColor.toAlpha(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  void _notifyParent() {
    final data = _radiosConfig
        .map(
          (config) => {
            'key': config.key,
            'selected': config.key == _selectedKey,
          },
        )
        .toList();
    widget.onChanged(data);
  }

  Future<void> _showInfoDialog(
    BuildContext context,
    String title,
    String desc,
  ) async {
    await context.confirmDone(Text(desc), title: title);
  }
}

class RadioGroupConfig {
  final String key;
  final String label;
  final bool defaultSelected;
  final String? data;
  final String? tooltip;
  final String description;

  RadioGroupConfig({
    required this.key,
    required this.label,
    this.defaultSelected = false,
    this.data,
    this.tooltip,
    required this.description,
  });
}

/*class DynamicRadioList extends StatefulWidget {
  final String? title;
  final List<RadioGroupConfig> radiosConfig;
  final List<Map<String, dynamic>>? initialData;
  final Function(List<Map<String, dynamic>>) onChanged;

  const DynamicRadioList({
    super.key,
    required this.radiosConfig,
    required this.onChanged,
    this.initialData,
    this.title,
  });

  @override
  State<DynamicRadioList> createState() => _DynamicRadioListState();
}

class _DynamicRadioListState extends State<DynamicRadioList> {
  String? _selectedKey; // Holds the currently selected key

  List<RadioGroupConfig> get _radiosConfig => widget.radiosConfig;
  String? get _title => widget.title;

  @override
  void initState() {
    super.initState();
    _initializeSelectedKey();
  }

  void _initializeSelectedKey() {
    final initialData = widget.initialData;

    if (initialData.isNotNullNorEmpty) {
      // Load selection from passed initialData
      final selectedItem = initialData!.firstWhere(
        (map) => map['selected'] == true,
        orElse: () => {},
      );
      _selectedKey = selectedItem['key'] as String?;
    } else {
      // Use the config with defaultSelected = true
      _selectedKey = _radiosConfig
          .firstWhere(
            (config) => config.defaultSelected,
            orElse: () =>
                _radiosConfig.first, // fallback if none marked default
          )
          .key;
    }

    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 10,
      children: [
        if (_title != null) ...[
          Text(_title!, style: context.textTheme.titleMedium),
        ],
        ..._buildGroupedRadios(),
      ],
    );
  }

  List<Widget> _buildGroupedRadios() {
    final radios = _radiosConfig
        .map((config) => _buildRadioTile(config))
        .toList();
    return radios.length <= 1 ? radios : _groupByTwo(radios);
  }

  RadioListTile<String> _buildRadioTile(RadioGroupConfig config) {
    return RadioListTile<String>.adaptive(
      dense: true,
      tileColor: kDangerColor.toAlpha(0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      title: Row(
        children: [
          Expanded(
            child: Text(
              config.label,
              style: const TextStyle(fontWeight: FontWeight.w400),
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
      value: config.key,
      selected: _selectedKey == config.key,
      groupValue: _selectedKey,
      onChanged: (value) {
        setState(() {
          _selectedKey = value;
          _notifyParent();
        });
      },
    );
  }

  void _notifyParent() {
    final data = _radiosConfig
        .map(
          (config) => {
            'key': config.key,
            'selected': config.key == _selectedKey,
          },
        )
        .toList();
    widget.onChanged(data);
  }

  List<Widget> _groupByTwo(List<Widget> fields) {
    final rows = <Widget>[];
    final total = fields.length;

    for (var i = 0; i < total; i += 2) {
      final isLast = i == total - 1;
      final isOdd = total % 2 != 0;

      rows.add(
        AdaptiveLayout(
          children: [
            if (isLast && isOdd)
              fields[i]
            else ...[
              fields[i],
              if (i + 1 < total) fields[i + 1],
            ],
          ],
        ),
      );

      if (i + 1 < total) {
        rows.add(HorizontalDivider(space: 0.1));
      }
    }

    return rows;
  }

  Future<void> _showInfoDialog(
    BuildContext context,
    String title,
    String desc,
  ) async {
    await context.confirmDone(Text(desc), title: title);
  }
}

class RadioGroupConfig {
  final String key;
  final String label;
  final bool defaultSelected;
  final String? data;
  final String? tooltip;
  final String description;

  RadioGroupConfig({
    required this.key,
    required this.label,
    this.defaultSelected = false,
    this.data,
    this.tooltip,
    required this.description,
  });
}*/
