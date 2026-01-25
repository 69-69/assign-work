import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/wh_location_type.dart';
import 'package:assign_erp/core/util/size_config.dart';
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
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/warehouse/widget/search_warehouse.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/widget/wh_location_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension WHLocationExtensions on BuildContext {
  Future<void> openWHLocationForm({WHLocation? serverItem}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverItem != null
          ? '${serverItem.getLocType.toTitle} - ${serverItem.isActive ? 'Active' : 'Inactive'}'
          : 'New Sub Location',
      body: _CreateWHLocationForm(serverItem: serverItem),
    ),
  );
}

class _CreateWHLocationForm extends StatefulWidget {
  final WHLocation? serverItem;

  const _CreateWHLocationForm({this.serverItem});

  @override
  State<_CreateWHLocationForm> createState() => _CreateWHLocationFormState();
}

class _CreateWHLocationFormState extends State<_CreateWHLocationForm> {
  bool _isZoneType = false;
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
  List<String> get _existingCodes => _serverItem?.getCodeRanges ?? [];

  // Basic fields
  String _whLocationCode = '';
  bool _isSubmitting = false;
  late WHLocation _whLocationData = widget.serverItem ?? WHLocation.empty;

  void _onSubmit() async {
    if (_isSubmitting) return;
    final isUpdate = _serverItem?.isNotEmpty == true;
    final isValid = _isFormValid;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Location
    if (isValid && isUpdate) {
      _updatedLocation();
      return;
    }

    // Case 2: Form validation or empty Location
    if (!isValid && _whLocationData.isNullOrEmpty) {
      prettyPrint('_whLocationData', _whLocationData.toMap());
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Add new Location
    _addNewLocation();
  }

  void _addNewLocation() {
    final newData = _whLocationData.copyWith(
      storeNumber: _employeeStore,
      createdBy: _employeeName,
    );

    _bloc.add(AddInventory<WHLocation>(data: newData));
  }

  void _updatedLocation() {
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
    }
  }

  /*void _generateWHLocCode([String? prefix]) {
    // Get selected Location type
    final pref = _serverItem?.getLocType ?? prefix;

    var nextLocationCode = pref?.nextLocationCode(_existingCodes) ?? '';
    if (_whLocationCode != nextLocationCode) {
      setState(() => _whLocationCode = nextLocationCode);
    }
  }*/

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
      case InventoryError<WHLocation>(error: var err):
        _showAlert('Error saving changes $err');
      case _: // no action
    }
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

  Widget _buildBody() {
    return FormGroupTabView(
      contents: formGroupCards,
      footers: [
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

  List<Map<String, dynamic>> get formGroupCards => [
    {
      'title': 'Warehouse Storage Location',
      'subTitle':
          '\nDefine physical location hierarchy(sub-areas/levels) used to track where inventory is stored.'
          '\nZone → Aisle → Rack → Level → Shelf → Bin',
      'children': [
        SizedBox(
          width: context.dynamicWidth(0.25),
          child: SearchWarehouses(
            initialValue: _whLocationData.warehouseCode,
            onChanged: (id, code, description) {
              _whLocationData = _whLocationData.copyWith(warehouseCode: code);
            },
          ),
        ),
        _buildWHSubLocation(),
      ],
    },
  ];

  DynamicTextFields _buildWHSubLocation() {
    prettyPrint('_whLocationCode', _whLocationCode);
    return DynamicTextFields(
      showButton: true,
      // key: ValueKey(_whLocationData.type),
      initialData: [
        _serverItem?.toMap() ?? {},
      ].map((e) => Map<String, dynamic>.from(e)).toList(),
      fieldsConfig: WhLocationFormFields.whLocFields(
        _serverItem?.toMap(),
        _isZoneType,
      ),
      onChanged: (List<Map<String, dynamic>> data) {
        var map = data.first;
        _whLocationData = WHLocation.fromMap(map);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _isZoneType = map['type'] == LocationType.zone.getName;
          });
        });
      },
    );
  }
}
