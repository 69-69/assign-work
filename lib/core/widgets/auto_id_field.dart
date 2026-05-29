import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';

import 'dialog/prompt_user_for_action.dart';

class AutoIDField extends StatefulWidget {
  final String label;
  final bool allowManualEntry;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final Future<String> Function() onGenerate;

  const AutoIDField({
    super.key,
    required this.onGenerate,
    required this.label,
    this.controller,
    this.onChanged,
    this.allowManualEntry = false,
  });

  @override
  State<AutoIDField> createState() => _AutoIDFieldState();
}

class _AutoIDFieldState extends State<AutoIDField> {
  late final TextEditingController _controller;
  bool _ownsController = false;

  /// true = system generated
  late bool _autoGenerate;
  bool _loading = false;

  bool get _allowManualEntry => widget.allowManualEntry;

  String get _label => widget.label;

  @override
  void initState() {
    super.initState();

    _ownsController = widget.controller == null;

    _controller = widget.controller ?? TextEditingController();

    /// Determine mode based on existing value
    _autoGenerate = _controller.text.isEmpty;

    /// Only auto-generate for new entities
    if (_autoGenerate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _generateID());
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _generateID() async {
    if (!_autoGenerate || _loading) return;

    setState(() => _loading = true);

    try {
      final id = await widget.onGenerate.call();
      _controller.value = TextEditingValue(
        text: id,
        selection: TextSelection.collapsed(offset: id.length),
      );
      widget.onChanged?.call(id);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _toggleMode() {
    setState(() => _autoGenerate = !_autoGenerate);

    /// Generate immediately when switching back to auto
    if (_autoGenerate && _controller.text.isEmpty) {
      _generateID();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: CustomTextField(
        controller: _controller,
        maxLines: 1,
        maxLength: 20,
        keyboardType: TextInputType.text,
        readOnly: _autoGenerate || _loading,
        onChanged: widget.onChanged,
        inputDecoration: InputDecoration(
          isDense: true,
          labelText: _autoGenerate ? '$_label (Auto)' : 'Enter $_label',
          hintText: _autoGenerate
              ? '$_label auto-generated'
              : 'Enter custom $_label',
          prefixIcon: _autoGenerate
              ? IconButton(
                  tooltip: 'Generate new $_label',
                  onPressed: _loading ? null : _generateID,
                  icon: _loading
                      ? SizedBox(width: 14, height: 14, child: context.loader)
                      : const Icon(Icons.refresh),
                )
              : Icon(Icons.edit_note),

          suffixIcon: _allowManualEntry
              ? IconButton(
                  tooltip: _autoGenerate
                      ? 'Switch to Manual Entry'
                      : 'Use Auto Generated $_label',
                  onPressed: _confirmManualEntry,
                  icon: Icon(
                    color: kDangerColor,
                    _autoGenerate ? Icons.edit_outlined : Icons.auto_awesome,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _confirmManualEntry() async {
    final message = _autoGenerate
        ? 'Switch to manual $_label entry'
        : 'Use auto-generated $_label';

    final shouldSwitch = await context.confirmAction<bool>(
      Text(message.toSentence),
      title: 'Change Entry Mode',
    );

    if (context.mounted && shouldSwitch == true) {
      _toggleMode();
    }
  }
}

/*final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.colorScheme.outlineVariant),
    );
    border: border,
    enabledBorder: border,
    focusedBorder: border,*/
