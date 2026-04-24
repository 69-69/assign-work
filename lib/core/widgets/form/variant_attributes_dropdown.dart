import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/ref_master_cache.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/ref_master_model.dart';
import 'package:flutter/material.dart';

/// Variant Attributes [VariantAttributesDropdown]
class VariantAttributesDropdown extends StatelessWidget {
  final String? label;
  final bool isService;
  final bool isDisabled;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const VariantAttributesDropdown({
    super.key,
    required this.onChanged,
    this.isDisabled = false,
    this.isService = false,
    this.initialValue,
    this.label,
  });

  RefMaster? get _cache => RefMasterCache().getById(attributeMasterCacheId);

  get _excludedAttributes => (_cache?.references ?? const <String>[]);

  @override
  Widget build(BuildContext context) {
    final strList = variantAttributes;
    // If label is provided, replace it with the first in the list
    if (label != null) strList[0] = label!;

    return IgnorePointer(
      ignoring: isDisabled,
      child: StaticDropdown<String>(
        key: key,
        label: strList.first,
        initialValue: initialValue,
        items: strList.where((u) => !_excludedAttributes.contains(u)).toList(),
        getDisplayText: (category) => category.toTitle,
        onChanged: onChanged,
      ),
    );
  }
}
