import 'package:assign_erp/core/widgets/form/category_picker.dart';
import 'package:assign_erp/core/widgets/material_or_service_choice.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/category_model.dart';
import 'package:flutter/material.dart';

class RefMasterFormInputs {
  /// [isNew] represent creating new or updating existing category
  static List<FieldGroupConfig> categoryField(bool isNew) => [
    FieldGroupConfig(
      key: 'type',
      label: 'Type',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return LineTypeDropdown(
          label: 'Type',
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'name',
      label: 'Category name',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,

      customBuilder: ({required initialData, required onChanged}) {
        return CategoryPicker(
          isMultiSelect: isNew,
          allowManualEntry: true,
          label: 'Category name',
          initialValue: !isNew ? initialData : null,
          initialValues: isNew ? List<String>.from(initialData ?? []) : null,
          onChanged: !isNew ? onChanged : null,
          onMultiChanged: isNew ? onChanged : null,
        );
      },
    ),
  ];

  static Iterable<Category> mapCategories(List<Map<String, dynamic>> data) {
    return data.expand((e) {
      final names = List<String>.from(e['name'] ?? []);

      return names.map((n) => Category.fromMap({...e, 'name': n}));
    });
  }
}
