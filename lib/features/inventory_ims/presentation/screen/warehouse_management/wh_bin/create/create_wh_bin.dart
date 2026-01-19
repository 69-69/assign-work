import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_bin_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/wh_bin_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_bin/widget/wh_bin_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension WHBinExtensions on BuildContext {
  Future<void> openWHBinForm({
    WHBin? serverItem,
    List<String>? existingCodes,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverItem != null
          ? serverItem.description.toTitle
          : 'New Bin/Shelf Storage',
      body: _CreateWHBinForm(
        serverItem: serverItem,
        existingCodes: existingCodes,
      ),
    ),
  );
}

class _CreateWHBinForm extends StatefulWidget {
  final WHBin? serverItem;
  final List<String>? existingCodes;

  const _CreateWHBinForm({this.serverItem, this.existingCodes});

  @override
  State<_CreateWHBinForm> createState() => _CreateWHBinFormState();
}

class _CreateWHBinFormState extends State<_CreateWHBinForm> {
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();

  bool get _isFormValid => _formKey.currentState!.validate();

  // Current employee info
  Employee? get _employee => context.employee;
  String get _employeeName => _employee!.fullName;
  String get _employeeStore => _employee!.storeNumber;

  WHBinBloc get _bloc => context.read<WHBinBloc>();

  WHBin? get _serverItem => widget.serverItem;

  bool get _isServerNull => _serverItem == null;
  List<String>? get _existingCodes => widget.existingCodes;

  // Basic fields
  String _whBinCode = '';
  bool _isSubmitting = false;
  late WHBin _whBinData = widget.serverItem ?? WHBin.empty;

  void _onSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Warehouse
    if (_isFormValid && (_serverItem?.isNotEmpty ?? false)) {
      _updatedWarehouse();
      return;
    }

    // Case 2: Form validation or empty WHBin
    if (!_isFormValid && _whBinData.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Add new WHBIn
    _addNewWarehouse();
  }

  void _addNewWarehouse() {
    final newData = _whBinData.copyWith(
      code: _whBinCode,
      storeNumber: _employeeStore,
      createdBy: _employeeName,
    );

    _bloc.add(AddInventory<WHBin>(data: newData));
  }

  void _updatedWarehouse() {
    final updated = _whBinData.copyWith(updatedBy: _employeeName);

    _bloc.add(UpdateInventory<WHBin>(documentId: _whBinData.id, data: updated));
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _whBinData = WHBin.empty;
      });
      _generateWHBinCode(); // fresh Warehouse Bin code
    }
  }

  void _generateWHBinCode() {
    // Get selected Bin type, else default to 'Zone'
    final prefix = _serverItem?.getType ?? BinType.zone.getName;
    var nextBinCode = prefix.nextBinCode(_existingCodes);
    if (mounted) {
      setState(() => _whBinCode = nextBinCode);
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull ? _resetForm() : Navigator.pop(context),
    );
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, InventoryState<WHBin> state) {
    final note = _isServerNull
        ? 'Warehouse Bin/Shelf Storage created'
        : 'Changes saved';
    switch (state) {
      case InventoryAdded<WHBin>(message: var msg):
      case InventoryUpdated<WHBin>(message: var msg):
        _showAlert(msg ?? note);
      case InventoryError<WHBin>():
        _showAlert('Error saving changes');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _generateWHBinCode();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WHBinBloc, InventoryState<WHBin>>(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: KeyedSubtree(key: _formResetKey, child: _buildBody()),
      ),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        WHBinFormFields.buildBinNumber(context, _whBinCode, _generateWHBinCode),

        FormGroupCard(
          title: '1. Warehouse Bin',
          subTitle:
              '\nOperational details and settings for managing this bin/shelf storage.',
          children: [_buildBinBasic()],
        ),
        FormGroupCard(
          title: '2. Storage Units',
          subTitle:
              '\nConfigure bins or shelves, including capacity and handling rules.',
          children: [_buildStorageCap()],
        ),

        const SizedBox(height: 20),
        context.confirmableActionButton(
          onPressed: _onSubmit,
          isDisabled: _isSubmitting,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Bin')
              : (_isSubmitting ? 'Updating...' : null),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  DynamicTextFields _buildBinBasic() {
    return DynamicTextFields(
      initialData: [{}],
      fullWidthKey: 'description',
      fieldsConfig: WHBinFormFields.whBinFields(),
      onChanged: (List<Map<String, dynamic>> data) {
        final bin = WHBin.fromMap(data.first);

        _whBinData = _whBinData.copyWith(
          description: bin.description,
          isActive: bin.isActive,
          locationId: bin.locationId,
        );
      },
    );
  }

  DynamicTextFields _buildStorageCap() {
    return DynamicTextFields(
      initialData: [{}],
      fieldsConfig: WHBinFormFields.whStorageFields,
      onChanged: (List<Map<String, dynamic>> data) {
        final bin = WHBin.fromMap(data.first);

        _whBinData = _whBinData.copyWith(
          maxItems: bin.maxItems,
          maxWeight: bin.maxWeight,
          minQty: bin.minQty,
          sequence: bin.sequence,
          uomRestriction: bin.uomRestriction,
        );
      },
    );
  }
}
