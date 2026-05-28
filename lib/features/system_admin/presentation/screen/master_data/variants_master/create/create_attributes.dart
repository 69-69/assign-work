import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/form_validity.dart';
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
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/attribute_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/widget/variants_master_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateAttributes<T> on BuildContext {
  Future<void> openAddAttribute({Attribute? serverAttribute}) =>
      openBottomSheet(
        isExpand: false,
        child: BottomSheetScaffold(
          title: serverAttribute != null
              ? 'Edit ${serverAttribute.type}'.toTitle
              : 'New Attribute(s)',
          body: _AddAttributeForm(serverAttribute: serverAttribute),
        ),
      );
}

class _AddAttributeForm extends StatefulWidget {
  final Attribute? serverAttribute;

  const _AddAttributeForm({this.serverAttribute});

  @override
  State<_AddAttributeForm> createState() => _AddAttributeFormState();
}

class _AddAttributeFormState extends State<_AddAttributeForm> {
  bool _isSubmitting = false;
  final List<Attribute> _attributes = [];
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  bool _isFormValid = false; // _formKey.currentState?.validate() ??

  Attribute? get _serverAttribute => widget.serverAttribute;

  bool get _isServerNull => _serverAttribute == null;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  String get _employeeStore => _employee!.storeNumber;

  AttributeBloc get _bloc => context.read<AttributeBloc>();

  void _syncValidity() => _formKey.syncValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _onSubmit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Attribute
    if (_isFormValid && (_serverAttribute?.isNotEmpty ?? false)) {
      _updatedAttribute();
      return;
    }

    // Case 2: Form validation or empty Attribute
    if (!_isFormValid && _attributes.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

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

  void _updatedAttribute() {
    final updated = _attributes.first.copyWith(
      id: _serverAttribute!.id,
      updatedBy: _employeeName,
      history: history(AuditAction.updated),
    );
    _bloc.add(UpdateSetup<Attribute>(documentId: updated.id, data: updated));
  }

  void _populateAttributesForm() {
    if (_serverAttribute != null) {
      _attributes
        ..clear()
        ..add(_serverAttribute!);
    }
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _isFormValid = false;
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
    final note = _isServerNull ? 'Attribute created' : 'Changes saved';
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
    _populateAttributesForm();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttributeBloc, SetupState<Attribute>>(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: KeyedSubtree(key: _formResetKey, child: _buildBody(context)),
      ),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FormGroupCard(
          title: 'Attribute properties',
          helperText: '\nTap the + button to add multiple entries',
          children: [
            DynamicTextFields(
              isRepeatable: _isServerNull,
              fieldsConfig: VariantsMasterFormInputs.attributeFields,
              initialData: [?_serverAttribute?.toMap()],
              onChanged: (List<Map<String, dynamic>> data) {
                // if (_isFormValid) setState(() {});

                // Create a new line item
                _attributes
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map(Attribute.fromMap));

                _syncValidity();
              },
            ),
          ],
        ),
        context.confirmableActionButton(
          isDisabled: _isSubmitting || !_isFormValid,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Attribute')
              : (_isSubmitting ? 'Updating...' : null),
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}

/*🔹 Step 4: Best-practice structure
✔️ Product Master (Base Product)
  Name: “Nike Sports T-Shirt 2023”
  Brand: Nike
  Model: 2023
  Type: Sport
✔️ Variant Attributes
  Color
  Size
✔️ Generated Variants (SKUs)
  Red / M
  Red / L
  Blue / M
  Blue / L
Each gets:
  SKU
  Barcode
  Stock (linked to your BIN / warehouse setup 👍)*/

/// Variants Attributes Steps involved:
/*
* You’re on the right track—that structure is exactly how most ERP systems expect it to work. The key now is to design it in a way that’s **clean, scalable, and tightly integrated with your Item Master**.

Let’s walk through how to implement this properly.

---

# 🔹 1. Core Design Overview

You essentially need **3 layers**:

### ✅ A. Variant Attributes (Master Data)

Define reusable attributes and their values.

**Attribute: Color**

* Red
* Blue

**Attribute: Size**

* M
* L

---

### ✅ B. Item Master (Base Product)

This is your **parent item** (non-stock or template item depending on ERP).

Example:

* Item Code: TS-001
* Name: Sports T-Shirt
* Variant Enabled: ✔️ Yes

---

### ✅ C. Item Variants (Child SKUs)

These are the **actual inventory items** generated from combinations.

| SKU        | Color | Size |
| ---------- | ----- | ---- |
| TS-001-R-M | Red   | M    |
| TS-001-R-L | Red   | L    |
| TS-001-B-M | Blue  | M    |
| TS-001-B-L | Blue  | L    |

---

# 🔹 2. How Integration Works

Your **Item Master links to Variant Attributes**, not directly to variants.

### Flow:

1. Assign attributes to item:

   * TS-001 → Color, Size

2. System generates combinations:

   * Red + M
   * Red + L
   * Blue + M
   * Blue + L

3. Each combination becomes:

   * A **child item (SKU)**
   * Linked back to TS-001

---

# 🔹 3. Suggested Table Structure (important for backend clarity)

If you're thinking in database terms:

### 🔸 Attribute Table

| Attribute_ID | Name  |
| ------------ | ----- |
| 1            | Color |
| 2            | Size  |

### 🔸 Attribute Values

| Value_ID | Attribute_ID | Value |
| -------- | ------------ | ----- |
| 1        | 1            | Red   |
| 2        | 1            | Blue  |
| 3        | 2            | M     |
| 4        | 2            | L     |

---

### 🔸 Item Master

| Item_ID | Name           | Variant_Flag |
| ------- | -------------- | ------------ |
| TS-001  | Sports T-Shirt | Yes          |

---

### 🔸 Item Variant Table

| Variant_ID | Item_ID | SKU        |
| ---------- | ------- | ---------- |
| 1          | TS-001  | TS-001-R-M |
| 2          | TS-001  | TS-001-R-L |

---

### 🔸 Variant Mapping Table (CRUCIAL)

| Variant_ID | Attribute | Value |
| ---------- | --------- | ----- |
| 1          | Color     | Red   |
| 1          | Size      | M     |

---

# 🔹 4. SKU Naming Logic (don’t skip this)

Define a **consistent SKU format early**:

Example:

```
[ItemCode]-[ColorCode]-[SizeCode]
TS-001-R-M
```

This avoids chaos later when scaling.

---

# 🔹 5. Inventory Integration (ties to your current work)

Each **variant SKU** should:

* Be stored in your **Warehouse / BIN master**
* Have its **own stock quantity**
* Have its **own barcode (optional but recommended)**

👉 Important:
Inventory is **never tracked at the parent level**, only at the variant level.

---

# 🔹 6. Common mistakes to avoid

* ❌ Creating variants manually instead of generating them
* ❌ Mixing non-variant fields (Brand, Model) into variant logic
* ❌ Not enforcing unique combinations
* ❌ Poor SKU naming (this becomes a nightmare fast)
* ❌ Allowing duplicate attribute values ("Red", "RED", "red")

---

# 🔹 7. What you should do next

1. Create:

   * Attribute Master (Color, Size)
   * Attribute Values

2. Update Item Master:

   * Add “Variant सक्षम / Enabled” flag
   * Link attributes

3. Build or configure:

   * Variant generation logic

4. Ensure:

   * Each variant = separate inventory item

---

If you want, I can help you design:

* A **UI flow** (how users will create items + variants)
* Or a **real ERP example** (like how Odoo or SAP S/4HANA handles this)

That’s usually the next step once the data model is clear.
*/

/// Variants generations:
/*
Variants aren’t really “a Flutter feature”—they’re **business logic + data modeling**, and Flutter just becomes the UI layer that triggers and displays the results. If you try to hardcode variant generation directly in UI widgets, it’ll get messy fast.

Here’s how to structure it cleanly.

---

# 🔹 1. Core idea: generate combinations programmatically

Given:

* Color → [Red, Blue]
* Size → [M, L]

You need to generate the **Cartesian product**:

```
Red + M
Red + L
Blue + M
Blue + L
```

---

# 🔹 2. Dart logic for variant generation

You can write a reusable function like this:

```dart
List<Map<String, String>> generateVariants(
    Map<String, List<String>> attributes) {
  List<Map<String, String>> result = [{}];

  attributes.forEach((attribute, values) {
    List<Map<String, String>> temp = [];

    for (var existing in result) {
      for (var value in values) {
        var newVariant = Map<String, String>.from(existing);
        newVariant[attribute] = value;
        temp.add(newVariant);
      }
    }

    result = temp;
  });

  return result;
}
```

---

### 🔹 Example usage

```dart
void main() {
  var attributes = {
    "Color": ["Red", "Blue"],
    "Size": ["M", "L"]
  };

  var variants = generateVariants(attributes);

  for (var v in variants) {
    print(v);
  }
}
```

---

### 🔹 Output

```
{Color: Red, Size: M}
{Color: Red, Size: L}
{Color: Blue, Size: M}
{Color: Blue, Size: L}
```

---

# 🔹 3. Generating SKU in Flutter

Extend the logic:

```dart
String generateSKU(String itemCode, Map<String, String> variant) {
  return itemCode +
      "-" +
      variant.values.map((e) => e.substring(0, 1)).join("-");
}
```

Example:

```
TS-001-R-M
```

---

# 🔹 4. Flutter UI flow (practical)

### Step 1: Select attributes

* Multi-select chips / dropdowns:

  * Color → Red, Blue
  * Size → M, L

---

### Step 2: Tap “Generate Variants”

Call:

```dart
setState(() {
  variants = generateVariants(selectedAttributes);
});
```

---

### Step 3: Display in table/list

Example UI:

```
Color | Size | SKU
-------------------
Red   | M    | TS-001-R-M
Red   | L    | TS-001-R-L
Blue  | M    | TS-001-B-M
Blue  | L    | TS-001-B-L
```

Use:

* `DataTable` (simple)
* or `ListView.builder` (scalable)

---

# 🔹 5. Where this logic should live (important)

Don’t bury this inside UI widgets.

Better structure:

* `variant_service.dart` → generation logic
* `item_controller.dart` → manages state
* UI → just displays and triggers

---

# 🔹 6. Backend vs Flutter (important decision)

### Option A: Generate in Flutter

✔️ Fast UI preview
✔️ Good for user experience

### Option B: Generate in backend (recommended for ERP)

✔️ Ensures consistency
✔️ Prevents duplicates
✔️ Centralized logic

👉 Best practice:

* Generate in Flutter (preview)
* Final save + validation in backend

---

# 🔹 7. Real-world ERP behavior

Systems like Odoo or SAP S/4HANA:

* Let users pick attributes in UI
* Instantly preview variants
* Store final variants in database with unique IDs

---

# 🔹 8. One thing to watch out for

If a user selects:

* 10 colors
* 10 sizes

👉 You just created **100 variants instantly**

So always:

* Show **variant count before generating**
* Add a **limit or warning**

---

If you want, I can help you build:

* A full Flutter screen (UI + state management)
* Or connect this to your existing **Item Master + Warehouse/BIN setup**

That’s where this becomes a complete ERP flow.

* */


/*
* That table is **not** your Item Master and **not** your Attributes table.

It represents the **Variants (Item Variants / SKU table)**.

---

## 🔹 Why?

Look at what your table contains:

| Color | Size | SKU        |
| ----- | ---- | ---------- |
| Red   | M    | TS-001-R-M |

Each row:

* Has a **specific combination of attribute values**
* Has a **unique SKU**
* Represents a **sellable, stockable item**

👉 That is exactly what a **variant** is.

---

## 🔹 Where each table fits

### ✅ 1. Item Master (Parent)

Only **one record** for the product:

| Item Code | Name           |
| --------- | -------------- |
| TS-001    | Sports T-Shirt |

No Color, no Size here.

---

### ✅ 2. Attributes Tables

Separate structure entirely:

**Attributes**

| Attribute |
| --------- |
| Color     |
| Size      |

**Attribute Values**

| Attribute | Value |
| --------- | ----- |
| Color     | Red   |
| Color     | Blue  |
| Size      | M     |
| Size      | L     |

---

### ✅ 3. Variants Table (THIS is your UI table)

| SKU        | Item Code | Color | Size |
| ---------- | --------- | ----- | ---- |
| TS-001-R-M | TS-001    | Red   | M    |
| TS-001-R-L | TS-001    | Red   | L    |

👉 Your UI table = **frontend view of this variants table**

---

## 🔹 Important distinction

* **Attributes table** → defines possibilities
* **Item master** → defines the product
* **Variants table** → defines actual inventory items

---

## 🔹 One subtle but important detail

In a proper normalized database, your variants table might actually look like:

| Variant_ID | Item_ID | SKU |
| ---------- | ------- | --- |

And then a **mapping table** stores:

* Variant → Color = Red
* Variant → Size = M

But in UI, you flatten it into:

```
Color | Size | SKU
```

---

## 🔹 Final answer (clear)

👉 Your displayed table = **Variants Table (Item Variants / SKU level)**
❌ Not Item Master
❌ Not Attributes Master

---

If you want, I can show you how to connect this exact table to:

* your **BIN / warehouse stock**
* and how each row becomes a **stock ledger entry**

That’s the next step where many ERP designs go wrong.
*/



/*Close—but not quite. You don’t need the **SKU from the Item Master**, you need a **base item code (or parent SKU)** from the Item Master to *build* the variant SKUs.

Let’s clean that up.

---

## 🔹 Correct concept

### ✅ Item Master (Parent)

This holds a **base identifier**, not the final SKU for selling units.

Example:

* Item Code: `TS-001`
* Name: Sports T-Shirt

👉 This is sometimes called:

* Parent SKU
* Template Code
* Item Code

---

### ✅ Variants (Actual SKUs)

These are generated by combining:

* Base Item Code
* Attribute values

Example:

```plaintext
TS-001-R-M
TS-001-R-L
TS-001-B-M
TS-001-B-L
```

---

## 🔹 So the logic is:

```id="1h7xke"
Variant SKU = Item Code + Attribute Codes
```

Example:

* Item Code → TS-001
* Color → Red (R)
* Size → M

👉 Result:

```id="g9sk2a"
TS-001-R-M
```

---

## 🔹 Important clarification

* ❌ Item Master should NOT store full SKUs like `TS-001-R-M`
* ❌ Item Master should NOT have multiple SKUs
* ✅ Item Master has **one base code only**

---

## 🔹 Why this design matters

If you try to store full SKUs in Item Master:

* You lose the parent-child relationship
* Variant grouping becomes messy
* Reporting (by product) becomes harder

---

## 🔹 Best practice

### In Item Master:

* `item_code = TS-001`

### In Variants Table:

* `sku = TS-001-R-M`
* `parent_item = TS-001`

---

## 🔹 Optional (but recommended)

Instead of using full words:

* Red → R
* Blue → B

This keeps SKUs:

* Short
* Consistent
* Easy to scan (especially for barcodes)

---

## 🔹 Final answer (simple)

👉 Yes, you use the **Item Master code**
👉 But you **generate a new SKU for each variant**

---

If you want, I can help you design a **SKU coding standard** (length, separators, abbreviations, edge cases). That decision becomes very hard to change later once data grows.
*/