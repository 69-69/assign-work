import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/form/custom_radio_tile.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Reusable radio list with dynamic groups [DynamicRadioList]
/// @TODO - This [DynamicRadioList] was upgraded due to Flutter 3.38
class DynamicRadioList extends StatefulWidget {
  final String? title;
  final List<RadioGroupConfig> radiosConfig;
  final List<Map<String, dynamic>>? initialData;
  final Function(List<RadioGroupConfig>) onChanged;

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
  String? get _title => widget.title;
  List<RadioGroupConfig> get _radiosConfig => widget.radiosConfig;
  List<Map<String, dynamic>>? get _initialData => widget.initialData;

  @override
  void initState() {
    super.initState();
    _initializeSelectedKey();
  }

  void _initializeSelectedKey() {
    if (_initialData.hasValue) {
      final selectedItem = _initialData!.firstWhere(
        (map) => map['selected'] == true,
        orElse: () => {},
      );
      _selectedKey = selectedItem['key'] as String?;
    } else {
      _selectedKey = _radiosConfig
          .firstWhere(
            (config) => config.selected,
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
        _buildCustomRadioList(context),
      ],
    );
  }

  Widget _buildCustomRadioList(BuildContext cxt) {
    // Map RadioGroupConfig to CustomRadioModel<String>
    final options = _radiosConfig.map((config) {
      return CustomRadioModel<String>(
        value: config.key,
        title: Row(
          children: [
            Expanded(
              child: Text(
                config.label,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: cxt.onPrimaryContainer,
                ),
              ),
            ),
            InkWell(
              onTap: () =>
                  _showInfoDialog(cxt, config.label, config.description),
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  void _notifyParent() {
    final data = _radiosConfig
        .map(
          (config) => RadioGroupConfig(
            key: config.key,
            label: config.label,
            data: config.data,
            selected: config.key == _selectedKey,
            tooltip: config.tooltip,
            description: config.description,
          ),
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
  final bool selected;
  final String? data;
  final String? tooltip;
  final String description;

  RadioGroupConfig({
    required this.key,
    required this.label,
    this.selected = false,
    this.data,
    this.tooltip,
    required this.description,
  });

  factory RadioGroupConfig.selected(List<RadioGroupConfig> data) {
    final selected = data.firstWhereOrNull((i) => i.selected == true);
    return selected ?? empty;
  }

  static List<Map<String, dynamic>> mapRadios(List<dynamic>? map) {
    final converted = (map ?? []).map((e) {
      if (e is RadioGroupConfig) {
        return {'key': e.key, 'value': e.selected};
      }
      return e as Map<String, dynamic>;
    }).toList();

    return converted;
  }

  // empty instance
  static RadioGroupConfig get empty =>
      RadioGroupConfig(key: '', label: '', description: '');
}
