import 'package:assign_erp/core/util/str_util.dart';
import 'package:flutter/material.dart';

/// Form text field [CustomTextField]
class CustomTextField extends StatelessWidget {
  final int? maxLength;
  final int? maxLines;
  final bool? enable;
  final bool autofocus;
  final Color? fillColor;
  final bool obscureText;
  final String? label;
  final String? helperText;
  final String? initialValue;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final Iterable<String>? autofillHints;
  final InputDecoration? inputDecoration;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;

  const CustomTextField({
    super.key,
    required this.keyboardType,
    this.label,
    this.initialValue,
    this.helperText,
    this.controller,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputDecoration,
    this.enable,
    this.maxLength,
    this.maxLines,
    this.focusNode,
    this.fillColor,
    this.autofillHints,
    this.obscureText = false,
    this.textInputAction,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final helpText = helperText != null ? '($helperText)' : '';

    var decoration =
        inputDecoration ??
        InputDecoration(
          filled: enable == false,
          fillColor: fillColor ?? Colors.grey.shade300,
          labelText: '$label $helpText',
          // helperText: helperText,
        );

    var validator2 =
        validator ??
        (value) {
          if (value == null || value.isEmpty) {
            var s = label ?? inputDecoration?.labelText;
            return 'Please enter $s';
          }
          if (isInputTypeNumber(keyboardType) &&
              double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        };

    return isInputTypeText(keyboardType)
        ? LowercaseTextField(
            enable: enable,
            focusNode: focusNode,
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            inputDecoration: decoration,
            validator: validator2,
          )
        : TextFormField(
            autofocus: autofocus,
            controller: controller,
            initialValue: initialValue,
            focusNode: focusNode,
            enabled: enable,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            obscureText: obscureText,
            autofillHints: autofillHints,
            onChanged: onChanged,
            textInputAction: textInputAction,
            onFieldSubmitted: (v) => onFieldSubmitted?.call(v),
            style: TextStyle(
              color: enable == false ? Colors.black : null,
              overflow: TextOverflow.ellipsis,
            ),
            decoration: decoration,
            validator: validator2,
          );
  }

  bool isInputTypeNumber(TextInputType i) {
    final textTypes = {
      TextInputType.number,
      TextInputType.phone,
      TextInputType.numberWithOptions,
    };
    return textTypes.contains(i);
  }

  bool isInputTypeText(TextInputType i) {
    final textTypes = {
      TextInputType.text,
      TextInputType.name,
      TextInputType.streetAddress,
    };
    return textTypes.contains(i);
  }
}

class LowercaseTextField extends StatefulWidget {
  final int? maxLength;
  final bool autofocus;
  final int? maxLines;
  final bool? enable;
  final String? labelText;
  final String? helperText;
  final InputDecoration? inputDecoration;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const LowercaseTextField({
    super.key,
    this.enable,
    this.maxLines,
    this.focusNode,
    this.labelText,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.helperText,
    this.controller,
    this.textInputAction,
    this.inputDecoration,
    this.onFieldSubmitted,
    this.autofocus = false,
  });

  @override
  State<LowercaseTextField> createState() => _LowercaseTextFieldState();
}

class _LowercaseTextFieldState extends State<LowercaseTextField> {
  TextEditingController? get _controller => widget.controller;
  bool capsLockOn = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: widget.autofocus,
      controller: _controller,
      enabled: widget.enable,
      focusNode: widget.focusNode,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      keyboardType: TextInputType.text,
      textInputAction: widget.textInputAction,
      style: TextStyle(
        color: widget.enable == false ? Colors.black : null,
        overflow: TextOverflow.ellipsis,
      ),
      decoration: widget.inputDecoration?.copyWith(
        errorText: capsLockOn ? 'Caps Lock is on!' : null,
      ),
      inputFormatters: const [
        // Allow letters and spaces only
        // FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
        // Allow letters only
        // FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
        // Allow only lowercase letters
        // FilteringTextInputFormatter.allow(RegExp('[a-z]')),
      ],
      onFieldSubmitted: (value) {
        _actionTriggered(value);

        // Call the onChanged callback passed from the parent widget
        widget.onFieldSubmitted?.call(value);
      },
      onChanged: (value) {
        _actionTriggered(value);

        // Call the onChanged callback passed from the parent widget
        widget.onChanged?.call(value);
      },
      /*onChanged: (value) {
        widget.onChanged?.call(value);

        setState(() {
          capsLockOn = _isCapsLockOn(value);
          // Convert text to lowercase
          _controller?.value = _controller!.value.copyWith(
            text: value.toLowerCase(),
            // Maintain cursor position
            selection: TextSelection.collapsed(offset: value.length),
          );
        });
      },*/
      validator: widget.validator,
    );
  }

  void _actionTriggered(String value) {
    setState(() => capsLockOn = _isCapsLockOn(value));

    // Only update the controller's text if it's different
    if (_controller?.text != value.toLowercaseAll) {
      _controller?.value = _controller!.value.copyWith(
        text: value.toLowercaseAll,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  bool _isCapsLockOn(String value) {
    bool hasLowerCase = value.contains(RegExp(r'[a-z]'));
    bool hasUpperCase = value.contains(RegExp(r'[A-Z]'));
    return hasUpperCase && !hasLowerCase;
  }

  /*@override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }*/
}
