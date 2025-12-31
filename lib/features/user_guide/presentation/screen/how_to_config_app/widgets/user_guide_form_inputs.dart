import 'package:assign_erp/core/constants/main_modules.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
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
    return MainModulesHelper.toStringList(
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
      label: 'Description...',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
  ];
}

/// Title & Category TextField [TitleCategoryInput]
class TitleCategoryInput extends StatelessWidget {
  const TitleCategoryInput({
    super.key,
    required this.titleController,
    this.onTitleChanged,
    this.serverCategory,
    required this.onCategoryChange,
  });

  final TextEditingController titleController;
  final ValueChanged? onTitleChanged;
  final String? serverCategory;
  final void Function(dynamic s) onCategoryChange;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TitleTextField(controller: titleController, onChanged: onTitleChanged),
        GuideCategoryDropdown(
          initialValue: serverCategory,
          onChanged: onCategoryChange,
        ),
      ],
    );
  }
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

/// [DescTextField]
class DescTextField extends StatelessWidget {
  final TextEditingController? descController;
  final ValueChanged? onDescChanged;

  const DescTextField({super.key, this.descController, this.onDescChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: descController,
      onChanged: onDescChanged,
      label: 'Description...',
      helperText: 'Optional',
      keyboardType: TextInputType.multiline,
      maxLines: 4,
      validator: (s) => null,
    );
  }
}

/// [UrlTextField]
class UrlTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const UrlTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Youtube URL',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.url,
    );
  }
}

/// [TitleTextField]
class TitleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const TitleTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Title',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
    );
  }
}
