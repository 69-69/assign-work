import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';

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
          serverCategory: serverCategory,
          onCategoryChange: onCategoryChange,
        ),
      ],
    );
  }
}

/// Guide Type Dropdown [GuideCategoryDropdown]
class GuideCategoryDropdown extends StatelessWidget {
  final void Function(dynamic s) onCategoryChange;
  final String? serverCategory;

  const GuideCategoryDropdown({
    super.key,
    required this.onCategoryChange,
    this.serverCategory,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> categoryList = [
      'Select guide category',
      ...userGuideCategories,
    ];

    return StaticDropdown<String>(
      key: key,
      items: categoryList,
      label: 'Select guide category',
      initialValue: serverCategory,
      getValue: (category) => category,
      getDisplayText: (category) => category,
      onChanged: (String? v) => onCategoryChange(v),
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
