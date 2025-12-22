import 'package:assign_erp/core/constants/tax_context.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/taxes/tax_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_taxes/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateTaxes<T> on BuildContext {
  Future<void> openAddTax({Tax? serverTax}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: '${serverTax != null ? 'Edit' : 'Create'} Tax',
      body: _AddTaxForm(serverTax: serverTax),
    ),
  );
}

class _AddTaxForm extends StatefulWidget {
  final Tax? serverTax;

  const _AddTaxForm({this.serverTax});

  @override
  State<_AddTaxForm> createState() => _AddTaxFormState();
}

class _AddTaxFormState extends State<_AddTaxForm> {
  final List<Tax> _taxList = [];
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => _serverTax.isNotNullNorEmpty;

  Tax? get _serverTax => widget.serverTax;
  bool get _isValid => _formKey.currentState?.validate() ?? false;
  String get _employeeName => context.employee!.fullName;

  void _onSubmit() {
    if (_isValid && _taxList.isNotEmpty) {
      final bloc = context.read<TaxBloc>();

      if (_isEditing) {
        final updatedTax = _prepareUpdatedTax();
        bloc.add(UpdateSetup<Tax>(documentId: updatedTax.id, data: updatedTax));
      } else {
        final newTaxes = _prepareNewTaxes();
        bloc.add(AddSetup<List<Tax>>(data: newTaxes));
      }

      context.showAlertOverlay(
        'Taxes successfully ${_isEditing ? 'updated' : 'created'}',
        popContext: () {
          if (!_isEditing) {
            _formKey.currentState!.reset();
            _taxList.clear();
          }
          Navigator.pop(context);
        },
      );
    }
  }

  // load existing Taxes
  void _loadExistingTaxes() {
    if (_isEditing) {
      _taxList
        ..clear()
        ..add(_serverTax!);
    }
  }

  List<Tax> _prepareNewTaxes() {
    // Append tax-code & createdBy to each tax
    final newDeparts = _taxList
        .map(
          (e) => e.copyWith(
            code: e.name.generateTaxCode(e.rate),
            createdBy: _employeeName,
          ),
        )
        .toList();
    return newDeparts;
  }

  Tax _prepareUpdatedTax() {
    final tax = _taxList.first;
    return _serverTax!.copyWith(
      id: _serverTax!.id,
      name: tax.name,
      rate: tax.rate,
      notes: tax.notes,
      autoApplyOn: tax.autoApplyOn,
      isAutoApply: tax.isAutoApply,
      isWithholding: tax.isWithholding,
      updatedBy: _employeeName,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadExistingTaxes();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(context),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FormGroupCard(
          children: [
            DynamicTextFields(
              title: 'Tax Rates',
              showButton: !_isEditing,
              fieldsConfig: _fieldsConfig,
              initialData: [?_serverTax?.toMap()],
              onChanged: (List<Map<String, dynamic>> data) {
                // if (_isValid) setState(() {});

                _taxList
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map((e) => _toTax(e)));
              },
            ),
          ],
        ),
        context.confirmableActionButton(
          label: _serverTax == null ? 'Create Taxes' : null,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  Tax _toTax(Map<String, dynamic> originalData) {
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

  List<FieldGroupConfig> get _fieldsConfig {
    return [
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
          final initial = _serverTax?.toMap();

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
}
