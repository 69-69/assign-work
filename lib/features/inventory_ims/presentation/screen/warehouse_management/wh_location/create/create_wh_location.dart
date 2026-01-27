import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/extensions/wh_location_type.dart';
import 'package:assign_erp/core/util/extensions/wh_zone_type.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_location_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/wh_location_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/warehouse/widget/search_warehouse.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/generate_codes/generate_wh_location_codes.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/widget/wh_location_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Cache CodeRanges
String? _cacheCodeRanges;

extension WHLocationExtensions on BuildContext {
  Future<void> openWHLocationForm({WHLocation? serverItem}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverItem?.customType.toTitle ?? 'New Sub Location',
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

  // This allow user to create a custom type of Location
  bool _isCustomType = false;
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

  // Basic fields
  bool _isSubmitting = false;
  late WHLocation _whLocationData;

  void _onSubmit() async {
    if (_isSubmitting) return;
    final isUpdate = _serverItem?.isNotEmpty == true;
    setState(() => _isSubmitting = true);

    // Comma separated full sub-location codeRanges
    final codeRanges = _whLocationData.codeRanges.isEmpty
        ? _cacheCodeRanges
        : _whLocationData.codeRanges;

    // Case 1: Update existing Location
    if (_isFormValid && isUpdate) {
      _updatedLocation(codeRanges);
      return;
    }

    // Case 2: Form validation or empty Location
    if (!_isFormValid || _whLocationData.isEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Add new Location
    _addNewLocation(codeRanges);
  }

  void _addNewLocation(String? codeRanges) {
    final newData = _whLocationData.copyWith(
      storeNumber: _employeeStore,
      codeRanges: codeRanges,
      createdBy: _employeeName,
    );

    _bloc.add(AddInventory<WHLocation>(data: newData));
  }

  void _updatedLocation(String? codeRanges) {
    _bloc.add(
      UpdateInventory<WHLocation>(
        documentId: _whLocationData.id,
        data: _whLocationData.copyWith(
          codeRanges: codeRanges,
          updatedBy: _employeeName,
        ),
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

  /*
  String _whLocationCode = '';
  List<String> get _existingCodes => _serverItem?.getCodeRanges ?? [];
  void _generateWHLocCode([String? prefix]) {
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
  void initState() {
    super.initState();
    _isZoneType = _serverItem?.type.isZoneType ?? false;
    _isCustomType = _serverItem?.type.isDefineNew ?? false;
    _whLocationData = widget.serverItem ?? WHLocation.empty;
  }

  @override
  void didUpdateWidget(covariant _CreateWHLocationForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.serverItem != widget.serverItem) {
      setState(() {
        _whLocationData = widget.serverItem ?? WHLocation.empty;
      });
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
    return FormGroupCard(
      showCollapseButton: false,
      title: 'Warehouse Storage Location',
      subTitle:
          '\nDefine physical location hierarchy(sub-areas/levels) used to track where inventory is stored.'
          '\nZone → Aisle → Rack → Level → Shelf → Bin',
      children: [
        SizedBox(
          width: context.dynamicWidth(0.25),
          child: SearchWarehouses(
            initialValue: _whLocationData.warehouseCode,
            onChanged: (id, code, description) {
              setState(() {
                _whLocationData = _whLocationData.copyWith(warehouseCode: code);
              });
            },
          ),
        ),
        _buildWHSubLocation(),
        _buildButtons(),
        const SizedBox(height: 20),
      ],
    );
  }

  DynamicTextFields _buildWHSubLocation() {
    return DynamicTextFields(
      initialData: [_serverItem?.toMap() ?? {}],
      fieldsConfig: WhLocationFormFields.whLocFields(
        isZone: _isZoneType,
        isCustom: _isCustomType,
      ),
      onChanged: (List<Map<String, dynamic>> data) {
        var map = data.first;
        if (map.isEmpty) return;
        var old = _serverItem;

        var locType = LocationTypeUtil.fromString(map['type'] ?? old?.type);

        _whLocationData = _whLocationData.copyWith(
          type: locType,
          zoneType: ZoneTypeUtil.fromString(map['zoneType'] ?? old?.zoneType),
          uomRestriction: UOMUtil.fromStringList(
            map['uomRestriction'] ?? old?.uomRestriction,
          ),
          description: map['description'] ?? old?.description,
          isActive: map['isActive'] ?? old?.isActive,
          maxQuantity: '${map['maxQuantity'] ?? old?.maxQuantity}'.asDouble,
          maxVolume: '${map['maxVolume'] ?? old?.maxVolume}'.asDouble,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _isZoneType = locType.isZoneType;
            // Check if User chose to create a new/custom subLocation
            _isCustomType = locType.isDefineNew;
          });
        });
      },
    );
  }

  AdaptiveLayout _buildButtons() {
    return AdaptiveLayout(
      children: [
        context.confirmableActionButton(
          onPressed: _onSubmit,
          isDisabled: _isSubmitting,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Location')
              : (_isSubmitting ? 'Updating...' : null),
        ),
        context.outlinedButton(
          'Manage Sub-Location Codes',
          onPressed: () async => await context.openGenerateWHLocCodesForm(
            serverItem: _serverItem,
            onCreateCodeRanges: (codeRanges) {
              _whLocationData = _whLocationData.copyWith(
                codeRanges: codeRanges.join(','),
              );
              _cacheCodeRanges = codeRanges.join(',');
            },
          ),
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(EdgeInsets.all(18)),
          ),
        ),
      ],
    );
  }
}
