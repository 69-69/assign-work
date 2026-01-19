import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_location_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/wh_location_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/widget/wh_location_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension WHLocationExtensions on BuildContext {
  Future<void> openWHLocationForm({
    WHLocation? serverItem,
    List<String>? existingCodes,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverItem != null
          ? serverItem.description.toTitle
          : 'New Location Storage',
      body: _CreateWHLocationForm(
        serverItem: serverItem,
        existingCodes: existingCodes,
      ),
    ),
  );
}

class _CreateWHLocationForm extends StatefulWidget {
  final WHLocation? serverItem;
  final List<String>? existingCodes;

  const _CreateWHLocationForm({this.serverItem, this.existingCodes});

  @override
  State<_CreateWHLocationForm> createState() => _CreateWHLocationFormState();
}

class _CreateWHLocationFormState extends State<_CreateWHLocationForm> {
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();

  bool get _isFormValid => _formKey.currentState!.validate();

  // Current employee info
  Employee? get _employee => context.employee;
  String get _employeeName => _employee!.fullName;
  String get _employeeStore => _employee!.storeNumber;

  WHLocationBloc get _bloc => context.read<WHLocationBloc>();

  WHLocation? get _serverItem => widget.serverItem;

  bool get _isServerNull => _serverItem == null;
  List<String>? get _existingCodes => widget.existingCodes;

  // Basic fields
  String _whLocationCode = '';
  bool _isSubmitting = false;
  late WHLocation _whLocationData = widget.serverItem ?? WHLocation.empty;

  void _onSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Warehouse
    if (_isFormValid && (_serverItem?.isNotEmpty ?? false)) {
      _updatedWarehouse();
      return;
    }

    // Case 2: Form validation or empty Warehouse
    if (!_isFormValid && _whLocationData.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Add new Warehouse
    _addNewWarehouse();
  }

  void _addNewWarehouse() {
    final newData = _whLocationData.copyWith(
      code: _whLocationCode,
      storeNumber: _employeeStore,
      createdBy: _employeeName,
    );

    _bloc.add(AddInventory<WHLocation>(data: newData));
  }

  void _updatedWarehouse() {
    final updated = _whLocationData.copyWith(updatedBy: _employeeName);

    _bloc.add(
      UpdateInventory<WHLocation>(
        documentId: _whLocationData.id,
        data: updated,
      ),
    );
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _whLocationData = WHLocation.empty;
      });
      _generateWHLocCode(); // fresh Warehouse location code
    }
  }

  void _generateWHLocCode() {
    // Get selected Location type, else default to 'STO'
    final prefix = _serverItem?.getType ?? LocationType.storage.locationCode;
    var nextLocationCode = prefix.nextLocationCode(_existingCodes);
    if (mounted) {
      setState(() => _whLocationCode = nextLocationCode);
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull ? _resetForm() : Navigator.pop(context),
    );
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, InventoryState<WHLocation> state) {
    final note = _isServerNull
        ? 'Warehouse Location Storage created'
        : 'Changes saved';
    switch (state) {
      case InventoryAdded<WHLocation>(message: var msg):
      case InventoryUpdated<WHLocation>(message: var msg):
        _showAlert(msg ?? note);
      case InventoryError<WHLocation>():
        _showAlert('Error saving changes');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _generateWHLocCode();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WHLocationBloc, InventoryState<WHLocation>>(
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
        WhLocationFormFields.buildLocNumber(
          context,
          _whLocationCode,
          _generateWHLocCode,
        ),

        FormGroupCard(
          title: '1. Warehouse Location',
          subTitle:
              '\nOperational details and settings for managing this location storage.',
          children: [_buildWHBasic()],
        ),

        const SizedBox(height: 20),
        context.confirmableActionButton(
          onPressed: _onSubmit,
          isDisabled: _isSubmitting,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Location')
              : (_isSubmitting ? 'Updating...' : null),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  DynamicTextFields _buildWHBasic() {
    return DynamicTextFields(
      initialData: [{}],
      fullWidthKey: 'description',
      fieldsConfig: WhLocationFormFields.whLocFields(),
      onChanged: (List<Map<String, dynamic>> data) {
        final loc = WHLocation.fromMap(data.first);

        _whLocationData = _whLocationData.copyWith(
          type: loc.type,
          description: loc.description,
          isActive: loc.isActive,
          maxItems: loc.maxItems,
          maxWeight: loc.maxWeight,
          warehouseId: loc.warehouseId,
        );
      },
    );
  }
}
