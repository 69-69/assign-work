import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/taxes/tax_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_taxes/widget/tax_form_inputs.dart';
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
  bool get _isEditing => _serverTax.hasValue;

  Tax? get _serverTax => widget.serverTax;
  String get _employeeName => context.employee!.fullName;
  bool get _isValid => _formKey.currentState?.validate() ?? false;

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
        onCallback: () {
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
      isShippingTaxed: tax.isShippingTaxed,
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
          title: 'Tax Rates',
          subTitle: '\n Add Tax Rates & Notes',
          children: [
            DynamicTextFields(
              showButton: !_isEditing,
              initialData: [?_serverTax?.toMap()],
              fieldsConfig: TaxFormInputs.taxRatesFields(_serverTax?.toMap()),
              onChanged: (List<Map<String, dynamic>> data) {
                // if (_isValid) setState(() {});

                TaxFormInputs.updateListFromData<Tax>(
                  _taxList,
                  map: data,
                  fromMap: (map, id) => Tax.fromMap(map),
                );
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
}
