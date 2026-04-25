import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/extensions/form_validity.dart';
import 'package:assign_erp/core/util/extensions/item_category.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/block_quote.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_wh_locations.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/wh_bin_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/wh_bin_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/warehouse/widget/search_warehouse.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/wh_bin/generate_bin_code/generate_full_bin_locations.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/wh_bin/widget/wh_bin_form_fields.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/wh_location/widget/search_wh_locations.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// For cache purposes only
String? _cacheFullBinLocations;

extension WHBinExtensions on BuildContext {
  Future<void> openWHBinForm({
    WHBin? serverItem,
    List<String>? existingCodes,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverItem?.description.toTitle ?? 'Bin Location Master',
      subtitle: 'Rack-Aisle-Shelf-Position',
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
  String _warehouseCode = '';
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();

  // final Set<String> _binLocationCode = {};
  final Map<String, String> _binLocationCode = {};
  List<Map<String, dynamic>>? _subLocations = [];

  bool _isFormValid = false;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  String get _employeeStore => _employee!.storeNumber;

  WHBinBloc get _bloc => context.read<WHBinBloc>();

  WHBin? get _serverItem => widget.serverItem;

  bool get _isServerNull => _serverItem == null;

  // Basic fields
  bool _isSubmitting = false;
  late WHBin _whBinData = widget.serverItem ?? WHBin.empty;

  // get _finalBinLocCode => [_warehouseCode, ..._binLocationCode].join('-').toUpperAll;
  get _finalBinLocCode =>
      [_warehouseCode, ..._binLocationCode.values].join('-').toUpperAll;

  void _updateValidity() => _formKey.updateValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _onSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Form validation or empty WHBin
    if (!_isFormValid && _whBinData.isEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Comma separated full bin locations
    final fullBinLocations = _whBinData.fullBinLocations.isEmpty
        ? _cacheFullBinLocations
        : _whBinData.fullBinLocations;

    // Case 2: Update existing Location
    if (_isFormValid && _serverItem != null) {
      _updatedBin(fullBinLocations);
      return;
    }

    // Case 3: Add new WHBIn
    _addNewLocationCodeBin(fullBinLocations);
  }

  void _addNewLocationCodeBin(String? fullBLocations) {
    final newData = _whBinData.copyWith(
      binLocationCode: _finalBinLocCode,
      fullBinLocations: fullBLocations,
      warehouseCode: _warehouseCode,
      storeNumber: _employeeStore,
      createdBy: _employeeName,
    );

    _bloc.add(AddSetup<WHBin>(data: newData));
  }

  void _updatedBin(String? fullBLocations) {
    final updated = _whBinData.copyWith(
      binLocationCode: _finalBinLocCode,
      fullBinLocations: fullBLocations,
      updatedBy: _employeeName,
    );

    _bloc.add(UpdateSetup<WHBin>(documentId: _whBinData.id, data: updated));
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _whBinData = WHBin.empty;
        _warehouseCode = '';
        _subLocations = [];
        _binLocationCode.clear();
      });
    }
  }

  /* List<String>? get _existingCodes => widget.existingCodes;
  void _generateWHBinCode([String? prefix]) {
    // Get selected Bin type, else default to 'Zone'
    final pref = _serverItem?.getType ?? prefix ?? LocationType.zone.getName;
    var nextBinCode = pref.nextBinCode(_existingCodes);
    if (_whBinCode != nextBinCode) {
      setState(() => _whBinCode = nextBinCode);
    }
  }*/

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull ? _resetForm() : Navigator.pop(context),
    );
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<WHBin> state) {
    final note = _isServerNull ? 'Bin Storage created' : 'Changes saved';
    switch (state) {
      case SetupAdded<WHBin>(message: var msg):
      case SetupUpdated<WHBin>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<WHBin>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void dispose() {
    // _bloc.close();
    _subLocations = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WHBinBloc, SetupState<WHBin>>(
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /*if (_isServerNull) ...{
          WHBinFormFields.buildBinNumber(
            context,
            _whBinCode,
            _generateWHBinCode,
          ),
        },
        Warehouse Master
           ↓
        Location Master (Zone / Area / Storage Type)
           ↓
        Bin Master (Aisle + Shelf + Level)*/
        ..._buildLocator(),
        FormGroupCard(
          title: 'Warehouse Bin',
          subTitle:
              '\nOperational details and settings for managing this bin storage.',
          children: [_buildBinFormFields()],
        ),

        const SizedBox(height: 10),
        _buildButtons(),
      ],
    );
  }

  Widget _buildButtons() {
    return context.confirmableActionButton(
      onPressed: _onSubmit,
      isDisabled: _isSubmitting || !_isFormValid,
      label: _isServerNull
          ? (_isSubmitting ? 'Creating...' : 'Create Bin')
          : (_isSubmitting ? 'Updating...' : null),
      anyButton: context.outlinedButton(
        'Manage Bin Locations',
        onPressed: () async {
          final shouldContinue = await context.confirmAction<bool>(
            const Text(
              'Sub-location codes must be created before generating full bin locations (unique addresses). Continue?',
            ),
            title: 'Prerequisite Required',
            onAcceptLabel: 'Continue',
            onRejectLabel: 'Cancel',
          );

          if (!mounted || shouldContinue != true) return;

          await context.openWHBinLocationsForm(
            serverItem: _serverItem,
            onCreateFullBinLocation: (fullCodes) {
              _whBinData = _whBinData.copyWith(
                fullBinLocations: fullCodes.join(','),
              );
              _cacheFullBinLocations = fullCodes.join(',');
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

  List<Widget> _buildLocator() {
    return [
      AdaptiveLayout(
        firstFlex: 2,
        children: [
          SearchWarehouses(
            initialValue: _serverItem?.warehouseCode,
            onChanged: (id, whCode, desc) async {
              final subLevels = await GetWHLocations.subLocations(whCode);
              setState(() {
                _warehouseCode = whCode;
                // reset previous selections
                _binLocationCode.clear();

                // load new structure
                _subLocations = subLevels;
                // _formResetKey = UniqueKey(); // rebuild fields
              });

              _updateValidity();
            },
          ),
          if (_subLocations?.isNotEmpty == true) ...{
            // Sub location/levels codes
            ..._subLocations?.map((e) {
                  final type = e['type'];
                  final codeRanges = e['codeRanges'];

                  return SizedBox(
                    height: 60,
                    child: SearchSubLocationCodes(
                      label: '$type'.toTitle,
                      subLocCodes: codeRanges,
                      // onChanged: (code) => setState(() => _binLocationCode.add(code ?? '')),
                      onChanged: (code) {
                        setState(() => _binLocationCode[type] = code ?? '');
                      },
                    ),
                  );
                }) ??
                [],
          },
        ],
      ),

      const SizedBox(height: 10),
      Text(
        'FULL BIN LOCATION CODE:',
        style: context.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: kDarkSuccessColor,
        ),
      ),
      BlockQuote(
        blockColor: kDarkSuccessColor,
        margin: EdgeInsets.only(top: 5),
        childPadding: EdgeInsets.symmetric(horizontal: 10),
        // child: _binLocationCode.isNotEmpty
        child:
            _binLocationCode.isNotEmpty &&
                _binLocationCode.values.every((e) => e.isNotEmpty)
            ? Text(_finalBinLocCode)
            : Text(_whBinData.binLocationCode),
      ),
      HorizontalDivider(),
    ];
  }

  DynamicTextFields _buildBinFormFields() {
    return DynamicTextFields(
      initialData: [_serverItem?.toMap() ?? {}],
      fieldsConfig: WHBinFormFields.whBinFields(),
      onChanged: (List<Map<String, dynamic>> data) {
        var map = data.first;
        if (map.isEmpty) return;
        var old = _serverItem;

        _whBinData = _whBinData.copyWith(
          isActive: map['isActive'] ?? old?.isActive,
          description: map['description'] ?? old?.description,
          maxQuantity: '${map['maxQuantity'] ?? old?.maxQuantity}'.asDouble,
          maxVolume: '${map['maxVolume'] ?? old?.maxVolume}'.asDouble,
          minQuantity: '${map['minQuantity'] ?? old?.minQuantity}'.asDouble,
          sequence: '${map['sequence'] ?? old?.sequence}'.asInt,
          uomRestriction: UOMUtil.fromStringList(
            map['uomRestriction'] ?? old?.uomRestriction,
          ),
          itemRestriction: ItemCategoryUtil.fromStringList(
            map['itemRestriction'] ?? old?.itemRestriction,
          ),
        );

        _updateValidity();
        /*if (_whBinData.isNotEmpty || _whBinData.type.isNullOrEmpty) {
          _generateWHBinCode(_whBinData.getType);
        }*/
      },
    );
  }
}

/*Below is a **clean, practical Flutter (Dart) data model** for a **Bin**, aligned with the WMS structure you’ve been discussing (Warehouse → Location → Bin with Aisle/Shelf/Level).

This is **system-agnostic**, but enterprise-ready.

---

## Bin model (Dart)

```dart
class Bin {
  final String warehouseCode;   // e.g. "05"
  final String locationCode;    // e.g. "A" (Zone / Area)
  final String aisle;           // e.g. "A1"
  final String shelf;           // e.g. "S1" (Rack / Bay)
  final String level;           // e.g. "L1"

  const Bin({
    required this.warehouseCode,
    required this.locationCode,
    required this.aisle,
    required this.shelf,
    required this.level,
  });

  /// System bin code (no separators)
  String get binCode => '$aisle$shelf$level';

  /// Human-readable bin location
  String get binLocationCode => '$aisle-$shelf-$level';

  /// Fully qualified bin location
  String get fullBinLocation =>
      '$warehouseCode-$locationCode-$binLocationCode';

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'warehouseCode': warehouseCode,
        'locationCode': locationCode,
        'aisle': aisle,
        'shelf': shelf,
        'level': level,
      };

  /// JSON deserialization
  factory Bin.fromJson(Map<String, dynamic> json) {
    return Bin(
      warehouseCode: json['warehouseCode'],
      locationCode: json['locationCode'],
      aisle: json['aisle'],
      shelf: json['shelf'],
      level: json['level'],
    );
  }
}
```

---

## Example usage

```dart
final bin = Bin(
  warehouseCode: '05',
  locationCode: 'A',
  aisle: 'A1',
  shelf: 'S1',
  level: 'L1',
);

print(bin.binCode);          // A1S1L1
print(bin.binLocationCode);  // A1-S1-L1
print(bin.fullBinLocation);  // 05-A-A1-S1-L1
```

---

## Why this model works well for WMS

* ✅ Matches **Warehouse / Location / Bin master separation**
* ✅ Supports **system bin code** and **human-readable location**
* ✅ Easy to serialize for **API / backend**
* ✅ Clean getters avoid data duplication
* ✅ Flexible for SAP / Oracle / custom WMS mappings

---

## Optional enhancements (if you want to go further)

Tell me if you want:

* **BinType** (PICK, BULK, PALLET)
* **Capacity / dimensions**
* **Status** (ACTIVE, BLOCKED)
* **Barcode / QR support**
* **Validation rules** (aisle format, level limits)

I can extend this into a **full WMS domain model** or adapt it exactly to your backend API.
*/

/*Below is a **clean, production-ready Flutter UI form** for creating/editing a **Bin**, aligned with your WMS model (**Warehouse → Location → Bin**).

This is a **Material-based form**, simple to integrate into your app.

---

## Bin Form UI (Flutter)

### Key features

* Dropdowns for **Warehouse** and **Location**
* Text fields for **Aisle / Shelf / Level**
* Live preview of **Bin Code** and **Full Bin Location**
* Validation-ready structure

---

## BinForm widget

```dart
import 'package:flutter/material.dart';

class BinForm extends StatefulWidget {
  const BinForm({super.key});

  @override
  State<BinForm> createState() => _BinFormState();
}

class _BinFormState extends State<BinForm> {
  final _formKey = GlobalKey<FormState>();

  String? warehouseCode;
  String? locationCode;
  final aisleController = TextEditingController();
  final shelfController = TextEditingController();
  final levelController = TextEditingController();

  @override
  void dispose() {
    aisleController.dispose();
    shelfController.dispose();
    levelController.dispose();
    super.dispose();
  }

  String get binCode =>
      '${aisleController.text}${shelfController.text}${levelController.text}';

  String get binLocationCode =>
      '${aisleController.text}-${shelfController.text}-${levelController.text}';

  String get fullBinLocation =>
      '${warehouseCode ?? ''}-${locationCode ?? ''}-$binLocationCode';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bin Master')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// Warehouse
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Warehouse',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '05', child: Text('05')),
                  DropdownMenuItem(value: '06', child: Text('06')),
                ],
                onChanged: (value) {
                  setState(() => warehouseCode = value);
                },
                validator: (value) =>
                    value == null ? 'Select warehouse' : null,
              ),
              const SizedBox(height: 16),

              /// Location / Zone
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Location / Zone',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('A')),
                  DropdownMenuItem(value: 'B', child: Text('B')),
                ],
                onChanged: (value) {
                  setState(() => locationCode = value);
                },
                validator: (value) =>
                    value == null ? 'Select location' : null,
              ),
              const SizedBox(height: 16),

              /// Aisle
              TextFormField(
                controller: aisleController,
                decoration: const InputDecoration(
                  labelText: 'Aisle',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter aisle' : null,
              ),
              const SizedBox(height: 16),

              /// Shelf / Rack
              TextFormField(
                controller: shelfController,
                decoration: const InputDecoration(
                  labelText: 'Shelf / Rack',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter shelf' : null,
              ),
              const SizedBox(height: 16),

              /// Level
              TextFormField(
                controller: levelController,
                decoration: const InputDecoration(
                  labelText: 'Level',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter level' : null,
              ),
              const SizedBox(height: 24),

              /// Live Preview
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bin Code: $binCode'),
                      Text('Bin Location: $binLocationCode'),
                      Text('Full Location: $fullBinLocation'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// Save button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: Save Bin
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bin saved')),
                    );
                  }
                },
                child: const Text('Save Bin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## UX aligned with warehouse operations

* **Dropdowns** prevent invalid warehouse/location selection
* **Free-text fields** allow flexible aisle/shelf/level formats
* **Live bin preview** mirrors real WMS screens
* Clean enough for **handheld / tablet usage**

---

## Next improvements (optional)

If you want, I can:

* Auto-generate aisle/shelf/level from rules
* Add **barcode scan input**
* Connect to **REST API**
* Add **edit vs create mode**
* Support **SAP-style storage types**

Just tell me the direction you want to take this.
*/
