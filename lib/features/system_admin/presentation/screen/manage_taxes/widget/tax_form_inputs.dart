import 'package:assign_erp/core/constants/tax_context.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:flutter/material.dart';

class TaxFormInputs {
  static Tax toTax(Map<String, dynamic> originalData) {
    final data = Map<String, dynamic>.from(originalData);
    final taxOptions = data['taxOptions'] as List?;

    if (taxOptions != null) {
      for (var e in taxOptions) {
        final taxOpt = TaxOption.fromMap(e);
        data[taxOpt.key] = taxOpt.selected;
      }
    }

    data.remove('taxOptions');
    return Tax.fromMap(data);
  }

  static List<FieldGroupConfig> taxRatesFields(Tax? serverTax) => [
    FieldGroupConfig(
      key: 'name',
      label: 'Tax Name',
      type: TextInputType.text,
      helperText: 'Name of the tax, e.g., VAT',
    ),
    FieldGroupConfig(
      key: 'rate',
      label: 'Tax Rate %',
      type: TextInputType.numberWithOptions(decimal: true),
      helperText: 'Tax percentage, e.g., 10 for 10%',
    ),
    FieldGroupConfig(
      key: 'notes',
      label: 'Additional Notes',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      helperText: 'Optional: Additional notes',
    ),
    FieldGroupConfig(
      key: 'autoApplyOn',
      label: 'Auto Apply Tax On',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return AutoApplyTaxOnDropdown(
          initialValues: TaxContextHelper.parseList(initialData),
          onMultiChanged: onChanged,
          // final taxContexts = selected.map((e) => e.getValue).toList();
        );
      },
    ),
    FieldGroupConfig(
      key: 'taxOptions',
      label: 'Tax Options',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final initial = serverTax?.toMap();

        return DynamicCheckboxList(
          title: 'How Tax Is Applied (Optional)',
          showButton: false,
          initialData: initialData,
          checkboxesConfig: [
            CheckboxGroupConfig(
              key: 'isAutoApply',
              label: 'Auto Apply Tax',
              selected: initial?['isAutoApply'] ?? false,
              tooltip:
                  'System should auto-apply this tax to eligible transactions',
              description:
                  'Determines if the system should auto-apply this tax to eligible transactions or services.',
            ),
            CheckboxGroupConfig(
              key: 'isWithholding',
              label: 'Withholding Tax',
              selected: initial?['isWithholding'] ?? false,
              tooltip: 'Indicates if this tax is a withholding tax',
              description:
                  'This tax will be withheld (subtracted) from the total payable.',
            ),
          ],
          onCheckChanged: onChanged,
        );
      },
    ),
  ];
}

/// TaxContexts: Auto Apply Tax On Dropdown [AutoApplyTaxOnDropdown]
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
      selectedMultiItems: initialValues ?? TaxContext.values,
      labelText: 'Auto apply tax on...',
      asyncItems: (String filter, loadProps) async =>
          await _loadTaxContexts(filter),
      filterFn: (cxt, filter) => _filterTaxContexts(filter, cxt),
      itemAsString: (TaxContext taxCxt) => taxCxt.getName.separateWord.toTitle,
      onMultiChanged: (List<TaxContext> taxCts) => onMultiChanged.call(taxCts),
      validatorMulti: (taxCts) =>
          taxCts.isNullOrEmpty ? 'Select where to auto-apply tax' : null,
      helperText: 'Enter to search, select to apply',
    );
  }

  // Load auto apply tax on (tax contexts)
  Future<List<TaxContext>> _loadTaxContexts(String filter) {
    return Future.delayed(Duration.zero, () {
      return TaxContext.values
          .where((i) => i.getName.toLowerAll.contains(filter.toLowerAll))
          .toList();
    });
  }

  // Filter auto apply tax on (tax contexts)
  bool _filterTaxContexts(String filter, TaxContext autoOn) {
    final term = (filter.isEmpty && (initialValues?.isEmpty ?? true))
        ? '' // Use empty string if no filter and initial values are empty
        : filter.isEmpty
        ? (initialValues?.join(' ') ?? '') // Join the list into a single string
        : filter;
    final matches = TaxContextHelper.isAutoAppliedTo(term);
    return matches;
  }
}
