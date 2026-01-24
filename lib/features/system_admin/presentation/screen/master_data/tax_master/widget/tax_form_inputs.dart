import 'package:assign_erp/core/util/extensions/tax_context.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:flutter/material.dart';

class TaxFormInputs {
  static List<FieldGroupConfig> taxRatesFields(
    Map<String, dynamic>? initial,
  ) => [
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
          initialValues: TaxContextUtil.parseList(initialData),
          onMultiChanged: onChanged,
        );
        // final taxContexts = selected.map((e) => e.getValue).toList();
      },
    ),
    FieldGroupConfig(
      key: 'taxOptions',
      label: 'Tax Options',
      isNested: true,
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DynamicCheckboxList(
          title: 'How Tax Is Applied (Optional)',
          showButton: false,
          initialData: CheckboxGroupConfig.mapCheckboxes(initialData),
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
            CheckboxGroupConfig(
              key: 'isShippingTaxed',
              label: 'Apply Tax to Shipping',
              selected: initial?['isShippingTaxed'] ?? false,
              tooltip:
                  'Indicates if this tax should also be applied to shipping charges',
              description:
                  'If enabled, shipping charges will be included in the taxable amount.',
            ),
          ],
          onCheckChanged: (List<CheckboxGroupConfig> selected) {
            final mapList = CheckboxGroupConfig.mapCheckboxes(selected);
            onChanged(mapList);
          },
        );
      },
    ),
  ];

  /// Updates the [list] with objects of type [T] from a list of maps.
  /// Clears the list first to prevent duplication, then adds new objects.
  /// [fromMap] converts each map entry into an object with the index as the ID.
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

    /*  static Tax toTax(Map<String, dynamic> originalData) {
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
    _taxList
        ..clear() // Clear previous entries to prevent duplication
        ..addAll(data.map((e) => TaxFormInputs.toTax(e)));*/
  }
}

/// TaxContexts: Auto Apply Tax On Dropdown [AutoApplyTaxOnDropdown]
class AutoApplyTaxOnDropdown extends StatefulWidget {
  final Function(List<TaxContext>) onMultiChanged;
  final List<TaxContext>? initialValues;

  const AutoApplyTaxOnDropdown({
    super.key,
    required this.onMultiChanged,
    this.initialValues,
  });

  @override
  State<AutoApplyTaxOnDropdown> createState() => _AutoApplyTaxOnDropdownState();
}

class _AutoApplyTaxOnDropdownState extends State<AutoApplyTaxOnDropdown> {
  late List<TaxContext> _taxContexts;

  @override
  void initState() {
    super.initState();
    _taxContexts = widget.initialValues ?? TaxContext.values;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<TaxContext>(
      isMultiSelect: true,
      selectedMultiItems: _taxContexts,
      labelText: 'Auto apply tax on...',
      asyncItems: (String filter, loadProps) async => _loadTaxContexts(filter),
      filterFn: _filterTaxContexts,
      itemAsString: (TaxContext t) => t.getName.separateWord.toTitle,
      onMultiChanged: (List<TaxContext> t) {
        setState(() => _taxContexts = List.from(t));
        widget.onMultiChanged.call(t); // notify parent
      },
      validatorMulti: (t) =>
          t.isNullOrEmpty ? 'Select where to auto-apply tax' : null,
      helperText: 'Enter to search, select to apply',
    );
  }

  // Load auto apply tax on (tax contexts)
  List<TaxContext> _loadTaxContexts(String filter) {
    return TaxContext.values.where((i) => _find(i, filter)).toList();
  }

  bool _filterTaxContexts(TaxContext autoOn, String filter) {
    if (filter.isEmpty) return true; // Show all when nothing typed
    return _find(autoOn, filter);
  }

  bool _find(TaxContext t, String filter) => t.getName.filterAny(filter);
}
