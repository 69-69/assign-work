import 'package:flutter/material.dart';

extension FormValidityExt on GlobalKey<FormState> {
  void syncValidity({
    required bool currentValidity,
    required void Function(bool) onChanged,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final valid = currentState?.validate() ?? false;

      if (valid != currentValidity) {
        onChanged(valid);
      }
    });
  }
}

extension SecFormValidityExt on Map<String, bool> {
  /// Returns true when all registered form sections are valid.
  bool get isFormValid => values.every((e) => e);

  /// Updates a single section validity and triggers rebuild only if changed.
  void syncSectionValidity(String section, {
    required bool isValid,
    required VoidCallback onChanged,
  }) {
    if (this[section] == isValid) return;

    this[section] = isValid;
    onChanged();
  }
}

/// ---------------------------------------------------------------------------
/// FORM VALIDATION EXTENSIONS
/// ---------------------------------------------------------------------------
///
/// Provides two validation approaches:
///
/// 1. `FormValidityExt`
///    → For normal Flutter forms using `FormState.validate()`.
///
/// 2. `FormValidityExt2`
///    → For large modular forms where each section manages
///      its own validation independently.
///
/// ---------------------------------------------------------------------------
/// USAGE 1 — STANDARD FLUTTER FORM
/// ---------------------------------------------------------------------------
///
/// Best for:
/// - Simple forms
/// - TextFormField validation
/// - Forms fully controlled by `FormState.validate()`
///
/// Example:
///
/// ```dart
/// class _MyFormState extends State<MyForm> {
///   final _formKey = GlobalKey<FormState>();
///
///   bool _isFormValid = false;
///
///   void _syncValidity() {
///     _formKey.syncValidity(
///       currentValidity: _isFormValid,
///       onChanged: (valid) {
///         setState(() => _isFormValid = valid);
///       },
///     );
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Form(
///       key: _formKey,
///       autovalidateMode: AutovalidateMode.onUserInteraction,
///       child: Column(
///         children: [
///           TextFormField(
///             validator: (v) =>
///                 v == null || v.isEmpty ? 'Required' : null,
///             onChanged: (_) => _syncValidity(),
///           ),
///
///           ElevatedButton(
///             onPressed: _isFormValid ? _submit : null,
///             child: const Text('Submit'),
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
///
/// ---------------------------------------------------------------------------
/// USAGE 2 — SECTION-BASED FORM VALIDATION
/// ---------------------------------------------------------------------------
///
/// Best for:
/// - Dynamic forms
/// - Multi-step forms
/// - Expandable sections
/// - Custom form widgets
/// - Forms where `FormState.validate()` is unreliable
///
/// Example:
///
/// ```dart
/// class _ItemMasterFormState extends State<ItemMasterForm> {
///   final Map<String, bool> _sectionValidity = {
///     'basic': false,
///     'uom': false,
///     'planning': false,
///     'costing': false,
///   };
///
///   bool get _isFormValid =>
///       _sectionValidity.isFormValid;
///
///   void _setSectionValidity(
///     String section,
///     bool isValid,
///   ) {
///     _sectionValidity.syncSectionValidity(
///       section: section,
///       isValid: isValid,
///       onChanged: () => setState(() {}),
///     );
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///
///         /// BASIC SECTION
///         DynamicTextFields(
///           onChanged: (data) {
///             final item = ItemMaster.fromMap(data.first);
///
///             _setSectionValidity(
///               'basic',
///               item.name.isNotEmpty &&
///               item.itemType.isNotEmpty,
///             );
///           },
///         ),
///
///         /// UOM SECTION
///         DynamicTextFields(
///           onChanged: (data) {
///             final item = ItemMaster.fromMap(data.first);
///
///             _setSectionValidity(
///               'uom',
///               item.baseUom != null,
///             );
///           },
///         ),
///
///         ElevatedButton(
///           onPressed: _isFormValid ? _submit : null,
///           child: const Text('Save'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// ---------------------------------------------------------------------------
/// WHICH ONE SHOULD YOU USE?
/// ---------------------------------------------------------------------------
///
/// Use `FormValidityExt` when:
/// - Flutter `Form` fully controls validation.
///
/// Use `FormValidityExt2` when:
/// - validation is distributed across widgets/sections
/// - custom widgets manage their own validation
/// - form sections rebuild independently
/// - dynamic fields make `FormState.validate()` unreliable
/// ---------------------------------------------------------------------------
