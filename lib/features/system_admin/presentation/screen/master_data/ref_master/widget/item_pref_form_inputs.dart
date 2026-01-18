import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:flutter/material.dart';

class ItemPref {
  static List<FieldGroupConfig> get categoryField => [
    FieldGroupConfig(key: 'name', label: 'Name', type: TextInputType.text),
  ];
}
