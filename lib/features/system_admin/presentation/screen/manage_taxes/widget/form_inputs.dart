import 'package:assign_erp/core/constants/tax_context.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// Auto Apply Tax On Dropdown [AutoApplyTaxOnDropdown]
class AutoApplyTaxOnDropdown extends StatelessWidget {
  final Function(List<TaxContext>) onMultiChanged;
  final List<TaxContext>? initialValues;

  const AutoApplyTaxOnDropdown({
    super.key,
    required this.onMultiChanged,
    this.initialValues,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<TaxContext>(
      isMultiSelect: true,
      selectedMultiItems: initialValues ?? [],
      labelText: 'Auto apply tax on...',
      asyncItems: (String filter, loadProps) async {
        return TaxContext.values
            .where(
              (i) => i.getValue.toLowerCase().contains(filter.toLowerCase()),
            )
            .toList();
      },
      itemAsString: (item) => item.getValue.separateWord.toTitle,
      onMultiChanged: (i) => onMultiChanged.call(i),
      validator: (item) =>
          item == null ? 'Select where to auto-apply tax' : null,
      filterFn: (autoApplyOn, filter) =>
          _filterAutoApplyOn(filter, autoApplyOn),
    );
  }

  bool _filterAutoApplyOn(String filter, TaxContext autoOn) {
    final term = (filter.isEmpty && (initialValues?.isEmpty ?? true))
        ? '' // Use empty string if no filter and initial values are empty
        : filter.isEmpty
        ? (initialValues?.join(' ') ?? '') // Join the list into a single string
        : filter;
    final matches = TaxContextHelper.isAutoAppliedTo(term);
    return matches;
  }
}
