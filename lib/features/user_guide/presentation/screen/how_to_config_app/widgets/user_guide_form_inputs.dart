import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/extensions/main_modules.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:flutter/material.dart';

class UserGuideConfig {
  static updateListFromData<T>(
    List<T> list, {
    required List<Map<String, dynamic>> map,
    required T Function(Map<String, dynamic>, String) fromMap,
  }) {
    return list
      ..clear() // Clear previous entries to prevent duplication
      ..addAll(
        map
            .asMap()
            .entries
            .map((e) => fromMap(e.value, '${e.key + 1}'))
            .toList(),
      );
  }

  static List<String> tabContents(bool canAccessAgent) =>
      _list(canAccessAgent).map((entry) => entry.first.label).toList();

  static List<CustomTabModel> sideTabs(bool canAccessAgent) =>
      _list(canAccessAgent)
          .map((e) => CustomTabModel(label: e.first.label, icon: e.first.icon))
          .toList();

  static List<Set<({IconData icon, String label})>> _list(bool canAccessAgent) {
    return MainModulesUtil.toStringList(
      keysToExclude: [
        if (!canAccessAgent) MainModuleId.agent,
        MainModuleId.trouble,
        MainModuleId.guide,
      ],
    );
  }

  static List<FieldGroupConfig> get formFields => [
    FieldGroupConfig(key: 'title', label: 'Title', type: TextInputType.text),
    FieldGroupConfig(key: 'url', label: 'Youtube URL', type: TextInputType.url),
    FieldGroupConfig(
      key: 'category',
      label: 'Guide Category',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return GuideCategoryDropdown(
          initialValue: initialData,
          onChanged: onChanged,
        );
      },
    ),
    FieldGroupConfig(
      key: 'description',
      label: 'Short description of the guide (user manual)',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
  ];
}

/// Guide Type Dropdown [GuideCategoryDropdown]
class GuideCategoryDropdown extends StatelessWidget {
  final void Function(dynamic s) onChanged;
  final String? initialValue;

  const GuideCategoryDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> categoryList = [
      'Select guide category',
      ...UserGuideConfig.tabContents(false),
    ];

    return StaticDropdown<String>(
      key: key,
      items: categoryList,
      label: 'Guide category',
      initialValue: initialValue,
      getDisplayText: (category) => category,
      onChanged: onChanged,
    );
  }
}
