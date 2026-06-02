import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/form_validity.dart';
import 'package:assign_erp/core/util/extensions/item_category.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/warehouse_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/warehouse_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/warehouse/widget/warehouse_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension WHExtensions on BuildContext {
  Future<void> openWarehouseForm({
    Warehouse? serverItem,
    List<String>? existingCodes,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverItem != null
          ? '${serverItem.code.toUpperAll} - ${serverItem.description.toTitle}'
          : 'New Warehouse',
      body: _CreateWarehouseForm(
        serverItem: serverItem,
        existingCodes: existingCodes,
      ),
    ),
  );
}

class _CreateWarehouseForm extends StatefulWidget {
  final Warehouse? serverItem;
  final List<String>? existingCodes;

  const _CreateWarehouseForm({this.serverItem, this.existingCodes});

  @override
  State<_CreateWarehouseForm> createState() => _CreateWarehouseFormState();
}

class _CreateWarehouseFormState extends State<_CreateWarehouseForm> {
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();

  bool _isFormValid = false;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;
  String get _employeeStore => _employee!.storeNumber;

  WarehouseBloc get _bloc => context.read<WarehouseBloc>();

  Warehouse? get _serverItem => widget.serverItem;

  bool get _isServerNull => _serverItem == null;
  List<String>? get _existingCodes => widget.existingCodes;

  // Basic fields
  String _warehouseCode = '';
  bool _isSubmitting = false;
  late Warehouse _warehouseData = widget.serverItem ?? Warehouse.empty;

  void _syncValidity() => _formKey.syncValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _onSubmit() async {
    if (_isSubmitting) return;
    final isUpdate = _serverItem?.isNotEmpty == true;
    final isValid = _isFormValid;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Warehouse
    if (isValid && isUpdate) {
      _updatedWarehouse();
      prettyPrint('updated', isUpdate);
      return;
    }

    // Case 2: Invalid form
    if (!isValid && _warehouseData.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Add new Warehouse
    _addNewWarehouse();
  }

  void _addNewWarehouse() {
    final newData = _warehouseData.copyWith(
      code: _warehouseCode,
      storeNumber: _employeeStore,
      createdBy: _employeeName,
    );

    prettyPrint('adding-01', _warehouseCode);
    _bloc.add(AddSetup<Warehouse>(data: newData));
  }

  void _updatedWarehouse() {
    final updated = _warehouseData.copyWith(updatedBy: _employeeName);

    _bloc.add(
      UpdateSetup<Warehouse>(documentId: _warehouseData.id, data: updated),
    );
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _warehouseData = Warehouse.empty;
      });
      _generateWHCode(); // fresh Warehouse number
    }
  }

  void _generateWHCode() {
    // NOTE: With warehouse, type is not used to generate code
    var nextWarehouseCode = 'WH'.nextWarehouseCode(_existingCodes);
    if (mounted) {
      setState(() => _warehouseCode = nextWarehouseCode);
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull ? _resetForm() : Navigator.pop(context),
    );
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<Warehouse> state) {
    final note = _isServerNull ? 'Warehouse created' : 'Changes saved';
    switch (state) {
      case SetupAdded<Warehouse>(message: var msg):
      case SetupUpdated<Warehouse>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<Warehouse>(error: var err):
        _showAlert('Something went wrong. Kindly try again $err');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _generateWHCode();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WarehouseBloc, SetupState<Warehouse>>(
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
        if (_isServerNull) ...{
          WarehouseFormFields.buildWHNumber(
            context,
            _warehouseCode,
            _generateWHCode,
          ),
        },
        FormGroupCard(
          title: 'Warehouse Information',
          subTitle:
              '\nName, type, operational status, and default settings for this warehouse.',
          children: [_buildWHBasic()],
        ),
        const SizedBox(height: 10),
        context.confirmableActionButton(
          onSubmit: _onSubmit,
          isDisabled: _isSubmitting || !_isFormValid,
          submitLabel: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Warehouse')
              : (_isSubmitting ? 'Updating...' : null),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  DynamicTextFields _buildWHBasic() {
    var item = _serverItem?.toMap();
    return DynamicTextFields(
      isRepeatable: _isServerNull,
      initialData: [
        {...?item, ...?_serverItem?.address.toMap()},
      ],
      fieldsConfig: WarehouseFormFields.wmsFields({
        "isActive": item?["isActive"] ?? true,
        "isDefault": item?["isDefault"] ?? false,
        "isBinManaged": item?["isBinManaged"] ?? false,
      }),
      onChanged: (List<Map<String, dynamic>> data) {
        var map = Map<String, dynamic>.from(data.first);
        if (map.isNullOrEmpty) return;
        var old = _serverItem;

        final address = {
          'type': AddressType.warehouse.getName,
          'city': map['city'],
          'state': map['state'],
          'street': map['street'],
          'postalCode': map['postalCode'],
        };

        _warehouseData = _warehouseData.copyWith(
          description: map['description'] ?? old?.description,
          wareType: WarehouseTypeUtil.fromString(
            map['wareType'] ?? old?.wareType,
          ),
          isActive: map['isActive'] ?? old?.isActive,
          isDefault: map['isDefault'] ?? old?.isDefault,
          isBinManaged: map['isBinManaged'] ?? old?.isBinManaged,
          maxItems: '${map['maxItems'] ?? old?.maxItems}'.asDouble,
          maxVolume: '${map['maxVolume'] ?? old?.maxVolume}'.asDouble,
          address: AddressInfo.fromMap(address),
          uomRestriction: UOMUtil.fromStringList(
            map['uomRestriction'] ?? old?.uomRestriction,
          ),
          itemRestriction: ItemCategoryUtil.fromStringList(
            map['itemRestriction'] ?? old?.itemRestriction,
          ),
        );

        _syncValidity();
      },
    );
  }
}
