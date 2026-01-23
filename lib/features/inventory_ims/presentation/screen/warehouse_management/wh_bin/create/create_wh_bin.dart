import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/block_quote.dart';
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
          ? '${serverItem.code.toUpperAll} - ${serverItem.description.toTitle}'
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
    final isUpdate = _serverItem?.isNotEmpty == true;
    final isValid = _isFormValid;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Location
    if (isValid && isUpdate) {
      _updatedBin();
      return;
    }

    // Case 2: Form validation or empty WHBin
    if (!isValid && _whBinData.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Add new WHBIn
    _addNewBin();
  }

  void _addNewBin() {
    final newData = _whBinData.copyWith(
      code: _whBinCode,
      storeNumber: _employeeStore,
      createdBy: _employeeName,
    );

    _bloc.add(AddInventory<WHBin>(data: newData));
  }

  void _updatedBin() {
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

  void _generateWHBinCode([String? prefix]) {
    // Get selected Bin type, else default to 'Zone'
    final pref =
        _serverItem?.getType ?? prefix ?? LocationHierarchy.zone.getName;
    var nextBinCode = pref.nextBinCode(_existingCodes);
    if (_whBinCode != nextBinCode) {
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_isServerNull) ...{
          WHBinFormFields.buildBinNumber(
            context,
            _whBinCode,
            _generateWHBinCode,
          ),
        },
        const SizedBox(height: 20),
        /*Warehouse Master
           ↓
        Location Master (Zone / Area / Storage Type)
           ↓
        Bin Master (Aisle + Shelf + Level)
        */
        FittedBox(
          alignment: Alignment.topLeft,
          child: BlockQuote(
            blockColor: kBgLightColor,
            blockWidth: 20,
            child: Tooltip(
              message: 'Storage Bin Location Address',
              child: Wrap(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BIN LOCATION CODE:',
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  BlockQuote(
                    blockColor: kPrimaryAccentColor,
                    margin: EdgeInsets.only(left: 10),
                    child: Text('Warehouse: $_whBinCode -'),
                  ),
                  BlockQuote(
                    blockColor: kWarningColor,
                    margin: EdgeInsets.only(left: 10),
                    child: Text('Aisle: ${_whBinData.locationId} -'),
                  ),
                  BlockQuote(
                    blockColor: kSuccessColor,
                    margin: EdgeInsets.only(left: 10),
                    child: Text('Shelf: $_whBinCode -'),
                  ),
                  BlockQuote(
                    blockColor: kDangerColor,
                    margin: EdgeInsets.only(left: 10),
                    child: Text('Level: L1'),
                  ),
                ],
              ),
            ),
          ),
        ),

        FormGroupCard(
          title: 'Warehouse Bin',
          subTitle:
              '\nOperational details and settings for managing this bin/shelf storage.',
          children: [_buildBinBasic()],
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
      showButton: true,
      initialData: [_serverItem?.toMap() ?? {}],
      fieldsConfig: WHBinFormFields.whBinFields(_serverItem?.toMap()),
      onChanged: (List<Map<String, dynamic>> data) {
        _whBinData = WHBin.fromMap(data.first);
        /*_whBinData = _whBinData.copyWith(
          uomRestriction: [_whBinData.uomRestriction?.first ?? ''],
        );*/
        if (_whBinData.isNotEmpty || _whBinData.type.isNullOrEmpty) {
          _generateWHBinCode(_whBinData.getType);
        }

        /*_whBinData = _whBinData.copyWith(
          description: bin.description,
          isActive: bin.isActive,
          locationId: bin.locationId,
          maxItems: bin.maxItems,
          maxWeight: bin.maxWeight,
          minQty: bin.minQty,
          sequence: bin.sequence,
          uomRestriction: bin.uomRestriction,
        );*/
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
