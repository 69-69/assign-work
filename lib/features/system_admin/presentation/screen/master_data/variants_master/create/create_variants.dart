import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/variant_attr_ext.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/variant_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/attribute_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/widget/attribute_selector.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/widget/variants_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateVariants<T> on BuildContext {
  Future<void> openAddVariant({
    Attribute? serverVariant,
    Map<String, List<Attribute>>? groupedAttrs,
  }) => openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetailMode: true,
      title: serverVariant != null
          ? 'Edit ${serverVariant.type}'
          : 'Create Variant(s)',
      body: _AddAttributeForm(
        serverAttribute: serverVariant,
        groupedAttrs: groupedAttrs,
      ),
    ),
  );
}

class _AddAttributeForm extends StatefulWidget {
  final Attribute? serverAttribute;
  final Map<String, List<Attribute>>? groupedAttrs;

  const _AddAttributeForm({this.serverAttribute, this.groupedAttrs});

  @override
  State<_AddAttributeForm> createState() => _AddAttributeFormState();
}

class _AddAttributeFormState extends State<_AddAttributeForm> {
  bool _isSubmitting = false;
  final List<Attribute> _attributes = [];

  Attribute? get _serverAttribute => widget.serverAttribute;
  List<Map<String, Attribute>> _variants = [];

  bool get _isServerNull => _serverAttribute == null;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  String get _employeeStore => _employee!.storeNumber;

  AttributeBloc get _bloc => context.read<AttributeBloc>();

  void _onSubmit() {
    if (!_isSubmitting) {
      final variantsToSave = Variant.buildVariants(
        itemCode: "TS-001",
        variants: _variants.map((v) => v.toCodeMap()).toList(),
      );
      prettyPrint('variants-To-Save', variantsToSave);

      // _bloc.add(AddSetup<List<Variant>>(data: variantsToSave));
      return;
    }

    setState(() => _isSubmitting = true);

    // Case 3: Create new Attributes
    _newAttributes();
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverAttribute!.history,
    AuditLog(action: action, actionBy: _employeeName),
  ];

  void _newAttributes() {
    final newAttributes = _attributes
        .map(
          (e) => e.copyWith(
            storeNumber: _employeeStore,
            createdBy: _employeeName,
            history: history(),
          ),
        )
        .toList();
    _bloc.add(AddSetup<List<Attribute>>(data: newAttributes));
  }

  // load existing Attributes
  void _loadExistingAttributes() {
    if (_serverAttribute != null) {
      _attributes
        ..clear()
        ..add(_serverAttribute!);
    }
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _attributes.clear();
      });
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull ? _resetForm() : Navigator.pop(context),
    );
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<Attribute> state) {
    final note = _isServerNull ? 'Variants created' : 'Changes saved';
    switch (state) {
      case SetupAdded<Attribute>(message: var msg):
      case SetupUpdated<Attribute>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<Attribute>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingAttributes();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttributeBloc, SetupState<Attribute>>(
      listener: _handleBlocState,
      child: _buildBody(context),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      children: [
        AdaptiveLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VariantsPreview(variants: _variants, itemCode: "TS-001"),
            AttributePanel(
              generatedVariants: (v) {
                setState(() => _variants = v);
              },
            ),
          ],
        ),

        context.confirmableActionButton(
          isDisabled:
              _isSubmitting || _variants.isEmpty || _variants.first.isEmpty,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Variant')
              : (_isSubmitting ? 'Updating...' : null),
          onPressed: _onSubmit,
        ),
      ],
    );
  }

}
