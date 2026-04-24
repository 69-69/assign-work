import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/extensions/form_validity.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/extensions/wh_location_type.dart';
import 'package:assign_erp/core/util/extensions/wh_zone_type.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/wh_location_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/wh_location_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/warehouse/widget/search_warehouse.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/wh_location/generate_codes/generate_wh_location_codes.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/wh_location/widget/wh_location_form_fields.dart';
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

  bool _isFormValid = false;

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

  void _updateValidity() => _formKey.updateValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

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

    _bloc.add(AddSetup<WHLocation>(data: newData));
  }

  void _updatedLocation(String? codeRanges) {
    _bloc.add(
      UpdateSetup<WHLocation>(
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

  void _handleBlocState(BuildContext cxt, SetupState<WHLocation> state) {
    final note = _isServerNull
        ? 'Warehouse Location Storage created'
        : 'Changes saved';
    switch (state) {
      case SetupAdded<WHLocation>(message: var msg):
      case SetupUpdated<WHLocation>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<WHLocation>(error: var err):
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
    return BlocListener<WHLocationBloc, SetupState<WHLocation>>(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: KeyedSubtree(
          key: _formResetKey,
          child: Column(
            children: [
              _buildBody(),
              const SizedBox(height: 10),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return FormGroupCard(
      showCollapseButton: false,
      title: 'Warehouse Storage Location',
      subTitle:
          '\nDefine physical location hierarchy(sub-areas/levels) used to track where inventory is stored.',
      helperText: '\nZone → Aisle → Rack → Level → Shelf → Bin',
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
        _buildWHFormFields(),
      ],
    );
  }

  DynamicTextFields _buildWHFormFields() {
    return DynamicTextFields(
      initialData: [_serverItem?.toMap() ?? {}],
      fieldsConfig: WhLocationFormFields.whLocFields(
        isZone: _isZoneType,
        isCustom: _isCustomType,
      ),
      onChanged: _handleWHSubLocChanged,
    );
  }

  void _handleWHSubLocChanged(List<Map<String, dynamic>> data) {
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
    _updateValidity();
  }

  Widget _buildButtons() {
    return context.confirmableActionButton(
      onPressed: _onSubmit,
      isDisabled: _isSubmitting || !_isFormValid,
      label: _isServerNull
          ? (_isSubmitting ? 'Creating...' : 'Create Location')
          : (_isSubmitting ? 'Updating...' : null),

      anyButton: context.outlinedButton(
        'Manage Codes',
        onPressed: () async {
          final shouldContinue = await context.confirmAction<bool>(
            const Text(
              'A location must be created before generating sub-location codes. Continue?',
            ),
            title: 'Prerequisite Required',
            onAcceptLabel: 'Continue',
            onRejectLabel: 'Cancel',
          );

          if (shouldContinue != true) return;

          await context.openGenerateWHLocCodesForm(
          serverItem: _serverItem,
          onCreateCodeRanges: (codeRanges) {
            _whLocationData = _whLocationData.copyWith(
              codeRanges: codeRanges.join(','),
            );
            _cacheCodeRanges = codeRanges.join(',');
          },
        );
        },
        style: ElevatedButton.styleFrom(
          elevation: 0.4,
          backgroundColor: kOffWhiteColor,
          padding: const EdgeInsets.all(18),
        ),
      ),
    );
  }
}
