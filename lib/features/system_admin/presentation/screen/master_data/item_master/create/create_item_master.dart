import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/extensions/form_validity.dart';
import 'package:assign_erp/core/util/extensions/line_item_type.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
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
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/item_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/item_master_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/item_master/widget/item_master_form_fields.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/widget/attribute_selector.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/widget/variants_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension IMFormExtensions on BuildContext {
  Future<void> openItemMasterForm({
    ItemMaster? serverItem,
    String? itemType,
    void Function()? onBackPress,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      onBackPress: onBackPress,
      title: serverItem != null
          ? serverItem.name.toTitle
          : 'New Item Master',
      body: _CreateItemMasterForm(itemType: itemType, serverItem: serverItem),
    ),
  );
}

class _CreateItemMasterForm extends StatefulWidget {
  final ItemMaster? serverItem;
  final String? itemType;

  const _CreateItemMasterForm({this.serverItem, this.itemType});

  @override
  State<_CreateItemMasterForm> createState() => _CreateItemMasterFormState();
}

class _CreateItemMasterFormState extends State<_CreateItemMasterForm> {
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();

  bool _isFormValid = false;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  String get _employeeId => _employee!.employeeId;

  String get _employeeStore => _employee!.storeNumber;

  ItemMasterBloc get _bloc => context.read<ItemMasterBloc>();

  ItemMaster? get _serverItem => widget.serverItem;

  bool get _isServerNull => _serverItem == null;

  String get _itemType =>
      widget.itemType ?? _serverItem?.itemType.getLabel ?? '';

  // Basic fields
  String _imNumber = '';
  bool _isSubmitting = false;
  final List<String> _taxCodes = [];
  List<Map<String, Attribute>> _variants = [];
  late ItemMaster _itemMaster = widget.serverItem ?? ItemMaster.empty;

  void _updateValidity() => _formKey.updateValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _onSubmit() async {
    if (_isSubmitting) return;
    final isUpdate = _serverItem?.isNotEmpty == true;
    final isValid = _isFormValid;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing ItemMaster
    if (isValid && isUpdate) {
      _updatedItemMaster();
      return;
    }

    // Case 2: Form validation or empty ItemMaster
    if (!isValid && _itemMaster.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Add new ItemMaster
    _createNewItemMaster();
  }

  void _createNewItemMaster() {
    final newData = _itemMaster.copyWith(
      sku: _imNumber,
      storeNumber: _employeeStore,
      createdBy: _employeeName,
      history: history(),
    );

    _bloc.add(AddSetup<ItemMaster>(data: newData));
  }

  void _updatedItemMaster() {
    final updated = _itemMaster.copyWith(
      updatedBy: _employeeName,
      history: history(AuditAction.updated),
    );

    _bloc.add(
      UpdateSetup<ItemMaster>(documentId: _itemMaster.id, data: updated),
    );
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _itemMaster = ItemMaster.empty;
      });
      _generateIMNumber(); // fresh IM number
    }
  }

  void _generateIMNumber() async {
    await DocType.itemMaster.getShortUID(
      onChanged: (s) {
        if (mounted) setState(() => _imNumber = s);
      },
    );
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverItem!.history,
    AuditLog(action: action, actionBy: _employeeId),
  ];

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull ? _resetForm() : Navigator.pop(context),
    );
  }

  void _handleBlocState(BuildContext cxt, SetupState<ItemMaster> state) {
    final note = _isServerNull ? 'Item master created' : 'Changes saved';
    switch (state) {
      case SetupAdded<ItemMaster>(message: var msg):
      case SetupUpdated<ItemMaster>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<ItemMaster>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _generateIMNumber();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ItemMasterBloc, SetupState<ItemMaster>>(
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
        ItemMasterFormFields.buildIMNumber(
          context,
          _imNumber,
          _generateIMNumber,
        ),

        /// 1️⃣ Basic Item Information + 2️⃣ Classification & Type
        FormGroupCard(
          title: '1. Basic Item Information',
          subTitle:
              '\nKey identification details and description of the $_itemType.',
          children: [_buildNameAndDesc()],
        ),

        /// 3️⃣ Units & Stock Rules
        FormGroupCard(
          isExpanded: false,
          title: '3. Units & Stock Rules',
          subTitle: '\nBase unit of measure and Setup control rules.',
          children: [_baseUOM(), _buildUsageAndAvailability()],
        ),

        /// 4️⃣ Planning & Procurement
        FormGroupCard(
          isExpanded: false,
          title: '4. Planning & Procurement',
          subTitle:
              '\nDefault reorder settings, lead times, and procurement rules.',
          children: [_buildPlanningAndProcurement()],
        ),

        /// 5️⃣ Costing
        FormGroupCard(
          isExpanded: false,
          title: '5. Costing',
          subTitle: '\nStandard costing and valuation method.',
          children: [_buildCosting()],
        ),

        /// Taxes
        FormGroupCard(
          isExpanded: false,
          title: '6.Taxes & Pricing',
          subTitle: '\nSelect applicable taxes',
          children: [_buildTaxModeSelector()],
        ),

        /// Warehouse + Sub-location + Bin address
        FormGroupCard(
          isExpanded: false,
          title: '7.Warehouse + Bins & Stock',
          subTitle:
              '\nSet the default warehouse, sub-location, and bin for this $_itemType.',
          children: [/*Widget here*/],
        ),

        /// Attributes & Variants
        AttributePanel(
          isExpanded: false,
          title: '8. Attributes & Variants',
          subTitle:
          '\nCreate multiple versions of this $_itemType using attributes like size or color.',
          generatedVariants: (v) {
            setState(() => _variants = v);
          },
          actionBuilder: Align(
            alignment: Alignment.topRight,
            child: context.elevatedButton(
              'Preview Variants (${_variants.length})',
              onPressed: () => context.showVariantPreview(
                itemCode: _imNumber,
                variants: _variants,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Text(
          'Needed & Optional Fields'
          'Optional / default warehouse fields (for ease of transactions):\n'
          'Default Warehouse\n'
          'Default Storage Location (shelf, aisle, BIN)\n'
        ),

        context.confirmableActionButton(
          onPressed: _onSubmit,
          isDisabled: _isSubmitting || !_isFormValid,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Item')
              : (_isSubmitting ? 'Updating...' : null),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNameAndDesc() {
    final itemType = LineItemTypeUtil.fromString(_itemType);

    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.nameAndDescFields(itemType: itemType),
      initialData: [_serverItem?.toMap() ?? {}],
      onChanged: (List<Map<String, dynamic>> data) {
        // if (_isFormValid) setState(() {});
        final i = ItemMaster.fromMap(data.first);

        _itemMaster = _itemMaster.copyWith(
          name: i.name,
          itemType: i.itemType,
          category: i.category,
          description: i.description,
        );

        _updateValidity();
      },
    );
  }

  Widget _baseUOM() {
    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.baseUomFields,
      initialData: [
        {'baseUom': _serverItem?.baseUom.getName},
      ],
      onChanged: (List<Map<String, dynamic>> data) async {
        final i = ItemMaster.fromMap(data.first);

        _itemMaster = _itemMaster.copyWith(baseUom: i.baseUom);
      },
    );
  }

  Widget _buildUsageAndAvailability() {
    final itemType = LineItemTypeUtil.fromString(_itemType);

    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.unitRuleFields(
        initial: _serverItem?.toMap() ?? {},
        isService: itemType.isService,
      ),
      onChanged: (List<Map<String, dynamic>> data) async {
        final i = ItemMaster.fromMap(data.first);

        _itemMaster = _itemMaster.copyWith(
          isActive: i.isActive,
          isSellable: i.isSellable,
          isStockItem: i.isStockItem,
          isPurchasable: i.isPurchasable,
        );
      },
    );
  }

  Widget _buildPlanningAndProcurement() {
    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.planningFields,
      initialData: [_serverItem?.toMap() ?? {}],
      onChanged: (List<Map<String, dynamic>> data) {
        // if (_isFormValid) setState(() {});
        final i = ItemMaster.fromMap(data.first);

        // Add new item master
        _itemMaster = _itemMaster.copyWith(
          reorderPoint: i.reorderPoint,
          reorderQty: i.reorderQty,
          leadTimeDays: i.leadTimeDays,
        );
      },
    );
  }

  Widget _buildCosting() {
    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.costingFields,
      initialData: [
        _serverItem?.pickKeys({'standardCost', 'costingMethod'}) ?? {},
      ],
      onChanged: (List<Map<String, dynamic>> data) {
        // if (_isFormValid) setState(() {});
        final i = ItemMaster.fromMap(data.first);

        // Add new item master
        _itemMaster = _itemMaster.copyWith(
          standardCost: i.standardCost,
          costingMethod: i.costingMethod,
        );
      },
    );
  }

  Widget _buildTaxModeSelector() {
    return ItemMasterFormFields.buildTaxModeSelector(
      isEnabled: false,
      selectedTaxCodes: _taxCodes,
      defaultTaxMode: TaxMode.headerTax,
      selectedTaxMode: (TaxMode? mode) {
        prettyPrint('Selected-tax-mode', mode);
      },
    );
  }
}

/*Here’s a clean **ERP-style grouping using your `FormGroupCard` pattern**, structured so it scales well and stays readable in Flutter.

I’ll group them exactly like an enterprise Item Master would.

---

# 🧩 1. Basic Information

```dart id="g1"
FormGroupCard(
  title: '1. Basic Information',
  subTitle: 'Core identity of the item.',
  children: [
    _itemName(),
    _itemCode(),
    _description(),
    _shortDescription(),
  ],
)
```

---

# 🧩 2. Classification & Identification

```dart id="g2"
FormGroupCard(
  title: '2. Classification & Identification',
  subTitle: 'Defines item category, type, and identity rules.',
  children: [
    _itemType(),
    _itemGroup(),
    _brand(),
    _model(),
    _barcode(),
    _tags(),
  ],
)
```

---

# 🧩 3. Units & Inventory Rules

```dart id="g3"
FormGroupCard(
  title: '3. Units & Inventory Rules',
  subTitle: 'Measurement units and stock behavior rules.',
  children: [
    _baseUOM(),
    _purchaseUOM(),
    _salesUOM(),
    _uomConversion(),
    _trackInventory(),
    _allowNegativeStock(),
    _batchTracking(),
    _serialTracking(),
  ],
)
```

---

# 🧩 4. Inventory Planning

```dart id="g4"
FormGroupCard(
  title: '4. Inventory Planning',
  subTitle: 'Controls stock availability and replenishment strategy.',
  children: [
    _safetyStock(),
    _reorderPoint(),
    _reorderQty(),
    _minStock(),
    _maxStock(),
    _leadTime(),
  ],
)
```

---

# 🧩 5. Procurement

```dart id="g5"
FormGroupCard(
  title: '5. Procurement',
  subTitle: 'Supplier and purchasing configuration.',
  children: [
    _preferredVendor(),
    _vendorItemCode(),
    _moq(),
    _purchaseLeadTime(),
    _purchaseTaxGroup(),
  ],
)
```

---

# 🧩 6. Sales

```dart id="g6"
FormGroupCard(
  title: '6. Sales',
  subTitle: 'Selling rules and pricing configuration.',
  children: [
    _sellingPrice(),
    _priceList(),
    _discountGroup(),
    _commissionGroup(),
    _isSellable(),
    _ecommerceEnabled(),
  ],
)
```

---

# 🧩 7. Costing & Accounting

```dart id="g7"
FormGroupCard(
  title: '7. Costing & Accounting',
  subTitle: 'Financial valuation and accounting mapping.',
  children: [
    _costMethod(),
    _standardCost(),
    _inventoryAccount(),
    _cogsAccount(),
    _revenueAccount(),
  ],
)
```

---

# 🧩 8. Taxes & Compliance

```dart id="g8"
FormGroupCard(
  title: '8. Taxes & Compliance',
  subTitle: 'Tax rules and regulatory codes.',
  children: [
    _taxGroup(),
    _vat(),
    _hsnSac(),
    _customsCode(),
  ],
)
```

---

# 🧩 9. Warehousing & Logistics

```dart id="g9"
FormGroupCard(
  title: '9. Warehousing & Logistics',
  subTitle: 'Storage location and shipping details.',
  children: [
    _defaultWarehouse(),
    _binLocation(),
    _weight(),
    _dimensions(),
    _volume(),
    _shippingClass(),
    _packagingType(),
  ],
)
```

---

# 🧩 10. Attributes & Variants

```dart id="g10"
FormGroupCard(
  title: '10. Attributes & Variants',
  subTitle: 'Generate and manage item variants.',
  children: [
    _attributeBuilder(),
    _variantMatrix(),
    _generatedVariantsList(),
  ],
)
```

---

# 🧩 11. Manufacturing

```dart id="g11"
FormGroupCard(
  title: '11. Manufacturing',
  subTitle: 'Production and BOM configuration.',
  children: [
    _bomEnabled(),
    _defaultBOM(),
    _routing(),
    _workCenter(),
    _scrapPercentage(),
    _productionType(),
  ],
)
```

---

# 🧩 12. Quality Control

```dart id="g12"
FormGroupCard(
  title: '12. Quality Control',
  subTitle: 'Inspection and quality rules.',
  children: [
    _qcRequired(),
    _qcTemplate(),
    _acceptanceCriteria(),
    _expiryTracking(),
    _shelfLife(),
  ],
)
```

---

# 🧩 13. Attachments & Media

```dart id="g13"
FormGroupCard(
  title: '13. Attachments & Media',
  subTitle: 'Documents, images, and certificates.',
  children: [
    _itemImages(),
    _datasheets(),
    _certificates(),
    _manuals(),
    _attachments(),
  ],
)
```

---

# 🧩 14. Lifecycle & Status

```dart id="g14"
FormGroupCard(
  title: '14. Lifecycle & Status',
  subTitle: 'Item lifecycle and audit information.',
  children: [
    _isActive(),
    _status(),
    _launchDate(),
    _endOfLifeDate(),
    _approvalStatus(),
    _auditInfo(),
  ],
)
```

---

# 🔥 Key Design Insight

Your ERP form is now structured like:

* SAP Business One
* Odoo Enterprise
* NetSuite
* Microsoft Dynamics

BUT with Flutter-native modular UI.

---

# ⚡ UX Optimization Tip

Make these groups progressive:

## Always visible:

```text
1–6
```

## Collapsible advanced:

```text
7–14
```

---

If you want next step, I can help you:

* auto-generate `_buildFields()` for each section
* or convert this into a dynamic JSON-driven form system (very powerful for ERP builders)
*/


/*Good direction—this is exactly how scalable ERP systems avoid hardcoding 14+ form sections per screen.

A JSON-driven form system lets you:

* add/remove fields without touching UI code
* enable/disable sections by Item Type (service vs inventory)
* version forms (ERP evolution problem)
* configure per company/tenant (multi-tenant ERP)

Below is a clean architecture you can actually build in Flutter.

---

# 🧠 1. Core Idea

Instead of:

```dart
FormGroupCard(...)
```

You render everything from JSON:

```text
Form Definition (JSON)
   ↓
Parser
   ↓
UI Builder
```

---

# 📦 2. JSON Structure Design (ERP-grade)

## Form → Sections → Fields

```json id="f1"
{
  "form": "item_master",
  "sections": [
    {
      "id": "basic_info",
      "title": "1. Basic Information",
      "subtitle": "Core identity of the item",
      "visibleWhen": {
        "itemType": ["inventory", "service", "non_inventory"]
      },
      "fields": [
        {
          "key": "item_name",
          "type": "text",
          "label": "Item Name",
          "required": true
        },
        {
          "key": "item_code",
          "type": "text",
          "label": "Item Code",
          "readonly": true
        }
      ]
    }
  ]
}
```

---

# 🧩 3. Field Types (ERP Standard)

```text id="t1"
text
number
decimal
dropdown
multi_select
switch
date
datetime
textarea
barcode
image
table (variants, BOM, etc.)
```

---

# ⚙️ 4. Flutter Model

```dart id="m1"
class FormDefinition {
  final String form;
  final List<FormSection> sections;

  FormDefinition({required this.form, required this.sections});

  factory FormDefinition.fromJson(Map<String, dynamic> json) {
    return FormDefinition(
      form: json['form'],
      sections: (json['sections'] as List)
          .map((e) => FormSection.fromJson(e))
          .toList(),
    );
  }
}
```

---

# 🧱 5. Section Model

```dart id="m2"
class FormSection {
  final String id;
  final String title;
  final String subtitle;
  final List<FormFieldConfig> fields;
  final Map<String, dynamic>? visibleWhen;

  FormSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.fields,
    this.visibleWhen,
  });

  factory FormSection.fromJson(Map<String, dynamic> json) {
    return FormSection(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      fields: (json['fields'] as List)
          .map((e) => FormFieldConfig.fromJson(e))
          .toList(),
      visibleWhen: json['visibleWhen'],
    );
  }
}
```

---

# 🧩 6. Field Config

```dart id="m3"
class FormFieldConfig {
  final String key;
  final String type;
  final String label;
  final bool required;
  final bool readonly;

  FormFieldConfig({
    required this.key,
    required this.type,
    required this.label,
    this.required = false,
    this.readonly = false,
  });

  factory FormFieldConfig.fromJson(Map<String, dynamic> json) {
    return FormFieldConfig(
      key: json['key'],
      type: json['type'],
      label: json['label'],
      required: json['required'] ?? false,
      readonly: json['readonly'] ?? false,
    );
  }
}
```

---

# 🧠 7. UI Renderer (Core Engine)

```dart id="r1"
Widget buildForm(FormDefinition form, Map<String, dynamic> data) {
  return ListView(
    children: form.sections.map((section) {
      if (!_isVisible(section, data)) {
        return const SizedBox.shrink();
      }

      return FormGroupCard(
        title: section.title,
        subTitle: section.subtitle,
        children: section.fields.map((field) {
          return buildField(field, data);
        }).toList(),
      );
    }).toList(),
  );
}
```

---

# 🧪 8. Field Factory (IMPORTANT)

```dart id="r2"
Widget buildField(FormFieldConfig field, Map<String, dynamic> data) {
  switch (field.type) {
    case 'text':
      return TextFormField(
        decoration: InputDecoration(labelText: field.label),
      );

    case 'number':
      return TextFormField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: field.label),
      );

    case 'dropdown':
      return DropdownButtonFormField(
        items: [],
        onChanged: (_) {},
        decoration: InputDecoration(labelText: field.label),
      );

    case 'switch':
      return SwitchListTile(
        title: Text(field.label),
        value: data[field.key] ?? false,
        onChanged: (_) {},
      );

    default:
      return Text('Unsupported field: ${field.type}');
  }
}
```

---

# 🧠 9. Conditional Visibility (ERP POWER FEATURE)

Example:

```json id="c1"
"visibleWhen": {
  "itemType": ["inventory"]
}
```

Logic:

```dart id="c2"
bool _isVisible(FormSection section, Map<String, dynamic> data) {
  final rules = section.visibleWhen;
  if (rules == null) return true;

  if (rules.containsKey('itemType')) {
    return (rules['itemType'] as List)
        .contains(data['itemType']);
  }

  return true;
}
```

---

# 🚀 10. What This Unlocks (Very Important)

## 1. ERP becomes configurable

No code change needed for:

* adding fields
* adding sections
* changing layout

---

## 2. Multi-company ERP

Company A:

```text
Needs HSN, GST
```

Company B:

```text
Does not need tax section
```

---

## 3. Item Type-based forms

| Item Type | UI Sections                |
| --------- | -------------------------- |
| Service   | no warehouse, no inventory |
| Inventory | full ERP fields            |
| Digital   | no stock, no logistics     |

---

## 4. Feature toggles

You can enable:

```text id="x1"
- Manufacturing module
- QC module
- Variants module
```

per customer

---

# 🧱 11. Where Your Current Code Fits

Your current system:

```dart
FormGroupCard(...)
```

becomes just a **renderer output widget**, not hardcoded structure anymore.

---

# ⚠️ Important Design Advice

Do NOT try to over-engineer at once.

Start with:

1. Sections JSON only
2. Then fields
3. Then conditional visibility
4. Then dynamic validation

---

# 🔥 If You Want Next Step

I can help you build:

### 👉 Full working Flutter dynamic form engine:

* validation system (required, min, max)
* variant table renderer (grid inside JSON)
* dependency fields (dropdown affects other fields)
* API-driven form loading (true ERP SaaS architecture)

Just tell me 👍
*/
