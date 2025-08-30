import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/setup/data/models/tax_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/taxes/tax_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateTaxes<T> on BuildContext {
  Future<void> openAddTax({Tax? serverTax}) => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(
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
  final _formKey = GlobalKey<FormState>();
  final List<Tax> _taxList = [];

  Tax? get _serverTax => widget.serverTax;
  bool get _isValid => _formKey.currentState?.validate() ?? false;
  String get _employeeName => context.employee!.fullName;

  void _onSubmit() {
    if (_isValid && _taxList.isNotEmpty) {
      final bloc = context.read<TaxBloc>();

      if (_serverTax != null) {
        final updated = _taxList.first.copyWith(
          id: _serverTax!.id,
          updatedBy: _employeeName,
        );

        bloc.add(UpdateSetup<Tax>(documentId: updated.id, data: updated));
      } else {
        final newTaxes = _prepareNewTax();
        bloc.add(AddSetup<List<Tax>>(data: newTaxes));
      }

      _formKey.currentState!.reset();

      context.showAlertOverlay('Taxes successfully created');
      Navigator.pop(context);
    }
  }

  List<Tax> _prepareNewTax() {
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

  // load existing Taxes
  void _loadExistingTaxes() {
    if (_serverTax != null) {
      _taxList.clear();
      _taxList.add(_serverTax!);
    }
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
              showButton: _serverTax == null,
              fieldsConfig: _fieldsConfig,
              initialData: [?_serverTax?.toMap()],
              onChanged: (List<Map<String, dynamic>> data) {
                if (_isValid) setState(() {});

                // Create a new line item
                _taxList
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map((e) => Tax.fromMap(e)));
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
        maxLines: 3,
        helperText: 'Optional: Additional notes',
      ),
    ];
  }
}
