import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/form/dynamic_radio_list.dart';
import 'package:assign_erp/core/widgets/layout/block_quote.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_taxes.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/taxes/tax_bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaxModeSelectorFactory {
  static Widget create({
    TaxMode? defaultTaxMode,
    List<String>? initialValues,
    required List<String> selectedTaxCodes,
    required Function(TaxMode?) selectedTaxMode,
  }) {
    return TaxModeSelector(
      initialValues: initialValues ?? [],
      defaultTaxMode: defaultTaxMode,
      onTaxModesChanged: (modes) => _onSelectTaxMode(modes, selectedTaxMode),
      onTaxCodesChanged: (codes) => _onTaxCodesChanged(codes, selectedTaxCodes),
    );
  }

  static void _onSelectTaxMode(
    List<RadioGroupConfig> data,
    Function(TaxMode?) selectedTaxMode,
  ) {
    final selected = data.firstWhereOrNull((i) => i.selected == true);
    final selectedKey = selected?.key ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectedTaxMode(TaxModeUtil.fromString(selectedKey));
    });
  }

  static void _onTaxCodesChanged(
    List<CheckboxGroupConfig> data,
    List<String> selectedTaxCodes,
  ) {
    // Extract tax codes from the data
    List<String> selected = data
        .where((e) => e.selected == true)
        .map((m) => Tax.fromMap(m.data).code)
        .toList();

    // Clear previous entries and add new ones to prevent duplication
    selectedTaxCodes
      ..clear()
      ..addAll(selected);
  }
}

/// Tax Modes Radio-Selector [TaxModeSelector]
class TaxModeSelector extends StatefulWidget {
  final TaxMode? defaultTaxMode;
  final List<String>? initialValues;
  final ValueChanged<double>? onValueChanged;
  final Function(List<CheckboxGroupConfig>)? onTaxCodesChanged;
  final Function(List<RadioGroupConfig>)? onTaxModesChanged;

  const TaxModeSelector({
    super.key,
    this.initialValues,
    this.defaultTaxMode,
    this.onValueChanged,
    this.onTaxCodesChanged,
    this.onTaxModesChanged,
  });

  @override
  State<TaxModeSelector> createState() => _TaxModeSelectorState();
}

class _TaxModeSelectorState extends State<TaxModeSelector> {
  /// [_isHeaderTax] Overall tax rate percentage applied to the total amount.
  /// Used only when PerLineTax is `false`.
  bool _isHeaderTax = false;
  double _taxPercent = 0.0;

  TaxMode? get _taxModeToApply => widget.defaultTaxMode;

  void _handleSelectedTaxes(List<CheckboxGroupConfig> data) {
    final selectedTaxes = data
        .where((i) => i.selected == true)
        .map((item) => Tax.fromMap(item.data))
        .toList();

    if (selectedTaxes.isNotEmpty) {
      // Calculate the total tax rate in 'percentage' for the selected taxes
      final totalRate = selectedTaxes.fold<double>(
        0.0,
        (sum, tax) => sum + tax.rate,
      );

      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _taxPercent = totalRate),
      );

      widget.onValueChanged?.call(totalRate);
      widget.onTaxCodesChanged?.call(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 16,
      children: [
        if (widget.onTaxModesChanged != null) ...{_taxToApply()},
        if (_isHeaderTax) ...{
          BlockQuote(
            blockColor: context.errorColor,
            child: Text(
              'If Tax category is not listed, please contact your system admin.',
              textAlign: TextAlign.justify,
            ),
          ),
          _TaxOptionsPanel(
            taxRate: _taxPercent,
            initialValues: widget.initialValues,
            onCheckChanged: _handleSelectedTaxes,
          ),
        },
      ],
    );
  }

  Widget _taxToApply() {
    final perLineTax = TaxMode.perLineTax;
    final headerTax = TaxMode.headerTax;

    return DynamicRadioList(
      title: 'Tax Application Method',
      radiosConfig: [
        RadioGroupConfig(
          key: perLineTax.getName,
          selected: _taxModeToApply == perLineTax,
          label: 'Apply Tax Per Item (Line-Level)',
          tooltip:
              'Use when different items are taxed at different rates (e.g., 5% and 18%).',
          description:
              'Select this option if products or services have different tax rates. You\'ll choose or enter tax for each line item.',
        ),
        RadioGroupConfig(
          key: headerTax.getName,
          selected: _taxModeToApply == headerTax,
          label: 'Apply Single Tax (Document-Level)',
          tooltip:
              'This method applies selected tax rate to the entire document.',
          description:
              'Use this option if all products or services are taxed at the same rate. You\'ll choose an overall tax that applies to the entire document.',
        ),
      ],
      onChanged: (List<RadioGroupConfig> data) {
        RadioGroupConfig? selected = RadioGroupConfig.selected(data);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => _isHeaderTax = selected.key == headerTax.getName);
        });

        widget.onTaxModesChanged!(data);
      },
    );
  }
}

/// Tax Checkboxes-Options Panel [TaxOptionsPanel]
class _TaxOptionsPanel extends StatelessWidget {
  final double taxRate;
  final List<String>? initialValues;
  final Function(List<CheckboxGroupConfig>) onCheckChanged;

  // final Function(List<Map<String, dynamic>>) onCheckChanged;

  const _TaxOptionsPanel({
    required this.onCheckChanged,
    required this.taxRate,
    this.initialValues,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaxBloc, SetupState<Tax>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Tax>() => context.loader,
          SetupsLoaded<Tax>(data: final results) =>
            results.isEmpty
                ? Center(child: Text('No taxes found'))
                : _buildTaxCheckboxes(results),
          SetupError<Tax>(error: final error) => context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildTaxCheckboxes(List<Tax> results) {
    final rateDisplay = taxRate > 0 ? taxRate.toString() : '';

    final configs = results.map((tax) {
      return CheckboxGroupConfig<Map<String, dynamic>>(
        key: tax.code,
        label: '${tax.name.toUpperAll}: ${tax.rate}%',
        description: tax.notes.toSentence,
        selected: initialValues?.contains(tax.code) ?? false,
        data: tax.toMap(),
      );
    }).toList();

    return DynamicCheckboxList(
      title: 'Overall Tax Rate $rateDisplay%',
      showButton: false,
      checkboxesConfig: configs,
      onCheckChanged: onCheckChanged,
    );
  }
}

/// Tax Multi Select Dropdown [TaxMultiSelectDropdown]
class TaxMultiSelectDropdown extends StatefulWidget {
  const TaxMultiSelectDropdown({
    super.key,
    this.label,
    this.initialValues,
    this.onMultiChanged,
  });

  final String? label;
  final List<String>? initialValues;
  final Function(List<Tax>)? onMultiChanged;

  @override
  State<TaxMultiSelectDropdown> createState() => _TaxMultiSelectDropdownState();
}

class _TaxMultiSelectDropdownState extends State<TaxMultiSelectDropdown> {
  List<String>? _initialValues;
  List<Tax>? _taxes;

  get _labelText => widget.label ?? 'Select Tax';

  @override
  void initState() {
    super.initState();
    _initialValues = widget.initialValues; // Load initial values
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTaxes());
  }

  Future<List<Tax>> _loadTaxes({String? filter}) async {
    // Only use filter or initialValues if filter is non-empty
    final filterBy =
        (filter?.isEmpty ?? true) && (_initialValues?.isEmpty ?? true)
        ? '' // Use empty string if both filter and initialValues are empty
        : (filter?.isEmpty ?? true)
        ? (_initialValues?.join(' ') ?? '')
        : filter;

    final taxes = await GetTaxes.getAllTaxes(forceRefresh: true);

    if (filterBy.toString().hasValue && taxes.hasValue) {
      final filteredTaxes = taxes
          .where((t) => t.filterByAny(filterBy!))
          .toList();

      setState(() => _taxes = filteredTaxes);
      return filteredTaxes;
    }
    return taxes;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Tax>(
      isMultiSelect: true,
      selectedMultiItems: _taxes,
      labelText: '$_labelText...',
      helperText:
          'If Tax category is not listed, please contact your system admin.',
      asyncItems: (String filter, loadProps) async =>
          await _loadTaxes(filter: filter),
      filterFn: _filterTax,
      itemAsString: (Tax tax) => tax.itemAsString.toTitle,
      onMultiChanged: (List<Tax> taxes) {
        // Ensure _taxes is updated even if empty
        setState(() => _taxes = List<Tax>.from(taxes));
        widget.onMultiChanged?.call(taxes);
      },
      validatorMulti: (taxes) => taxes.isNullOrEmpty ? _labelText : null,
      onNoDataFound: () {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handleNoDataFound(context),
        );
      },
    );
  }

  bool _filterTax(Tax tax, String filter) {
    final term = (filter.isEmpty && (_initialValues?.isEmpty ?? true))
        ? '' // Use empty string if no filter and initial values are empty
        : filter.isEmpty
        ? (_initialValues?.join(' ') ??
              '') // Join the list into a single string
        : filter;
    return tax.filterByAny(term);
  }

  Future<void> _handleNoDataFound(BuildContext cxt) async {
    await cxt.confirmDone(
      const Text(
        'Enter to search or contact your system administrator to add a new tax rate.',
      ),
      title: 'Tax code not found',
    );
  }
}
