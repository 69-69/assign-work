import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:flutter/material.dart';

/// Form text field [CustomTextField]
///
class CustomTextField extends StatefulWidget {
  final bool? readOnly;
  final bool? enabled;
  final String? label;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool autofocus;

  /// [isAutoGrow] Auto-Wrap + Grow text field
  final bool isAutoGrow;

  /// [maxHeight] Max height of the Auto-Grow text field
  final double maxHeight;
  final Color? fillColor;
  final Color? textColor;
  final bool obscureText;
  final String? helperText;
  final String? initialValue;
  final bool? canRequestFocus;
  final FocusNode? focusNode;
  final TextInputType textInputType;
  final Iterable<String>? autofillHints;
  final InputDecoration? inputDecoration;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const CustomTextField({
    super.key,
    required this.textInputType,
    this.label,
    this.enabled,
    this.readOnly,
    this.maxLines,
    this.minLines,
    this.focusNode,
    this.fillColor,
    this.validator,
    this.onChanged,
    this.textColor,
    this.maxLength,
    this.controller,
    this.helperText,
    this.initialValue,
    this.autofillHints,
    this.canRequestFocus,
    this.textInputAction,
    this.inputDecoration,
    this.maxHeight = 100,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.isAutoGrow = false,
    this.obscureText = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool capsLockOn = false;
  late final TextEditingController _controller;

  bool get _readOnly => widget.readOnly ?? false;
  late final TextEditingController _internalController;

  bool get _canRequestFocus => widget.canRequestFocus ?? true;
  final ScrollController _scrollController = ScrollController();

  TextInputType get _textInputType => widget.textInputType;

  int? get _maxLength {
    if ((widget.maxLength ?? 0) > 0) return widget.maxLength;
    // For Validating Phone numbers, if maxLength is not specified
    if (_textInputType == TextInputType.phone) return 10;
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Create internal controller only if the user did NOT pass one
    // _internalController = widget.controller ?? TextEditingController();
    _internalController = TextEditingController(text: widget.initialValue);
    _controller = widget.controller ?? _internalController;

    if (widget.isAutoGrow) {
      _controller.addListener(_scrollToEnd);
    }
  }

  @override
  void dispose() {
    if (widget.isAutoGrow) {
      _controller.removeListener(_scrollToEnd);
      _scrollController.dispose();
    }

    // IMPORTANT: Dispose ONLY internal controller.
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Whenever text changes, it scroll's or jump to the bottom
        // _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _actionTriggered(String value) {
    setState(() => capsLockOn = _isCapsLockOn(value));

    // Only update the controller's text if it's different
    if (_controller.text != value.toLowerAll) {
      _controller.value = _controller.value.copyWith(
        text: value.toLowerAll,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  bool _isCapsLockOn(String value) {
    bool hasLowerCase = value.contains(RegExp(r'[a-z]'));
    bool hasUpperCase = value.contains(RegExp(r'[A-Z]'));
    return hasUpperCase && !hasLowerCase;
  }

  @override
  Widget build(BuildContext context) {
    return widget.isAutoGrow ? _buildAutoGrowTextField() : _buildTextField();
  }

  ConstrainedBox _buildAutoGrowTextField() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.only(top: 10),
          child: _buildTextField(),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return isInputTypeText() ? _buildLowercaseField() : _buildStandardField();
  }

  _StandardTextField _buildStandardField() {
    final (valid, decoration) = _inputDecoration();

    return _StandardTextField(
      validator: valid,
      enabled: widget.enabled,
      readOnly: _readOnly,
      decoration: decoration,
      controller: _controller,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      focusNode: widget.focusNode,
      maxLength: _maxLength,
      onChanged: widget.onChanged,
      textColor: widget.textColor,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      canRequestFocus: _canRequestFocus,
      // initialValue: widget.initialValue,
      keyboardType: _textInputType,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      // label: widget.label,
      // fillColor: widget.fillColor,
      // helperText: widget.helperText,
      // initialValue: widget.initialValue,
    );
  }

  _LowercaseTextField _buildLowercaseField() {
    final (valid, decoration) = _inputDecoration();

    return _LowercaseTextField(
      validator: valid,
      enabled: widget.enabled,
      readOnly: _readOnly,
      capsLockOn: capsLockOn,
      controller: _controller,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      focusNode: widget.focusNode,
      maxLength: _maxLength,
      textColor: widget.textColor,
      inputDecoration: decoration,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      canRequestFocus: _canRequestFocus,
      onActionTriggered: _actionTriggered,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      // initialValue: widget.initialValue,
    );
  }

  (String? Function(String?), InputDecoration?) _inputDecoration() {
    final helpText = widget.helperText != null ? '($widget.helperText)' : '';

    var decoration =
        widget.inputDecoration ??
        InputDecoration(
          filled: widget.enabled == false,
          fillColor: widget.fillColor ?? Colors.grey.shade300,
          labelText: '${widget.label} $helpText',
          // helperText: helperText,
        );

    var valid =
        widget.validator ??
        (value) {
          if (value == null || value.isEmpty) {
            var s = widget.label ?? widget.inputDecoration?.labelText;
            return 'Please enter $s';
          }
          if (isInputTypeNumber() && double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        };

    return (valid, decoration);
  }

  bool isInputTypeNumber() {
    final textTypes = {
      TextInputType.number,
      TextInputType.phone,
      TextInputType.numberWithOptions,
    };
    return textTypes.contains(_textInputType);
  }

  bool isInputTypeText() {
    final textTypes = {
      TextInputType.text,
      TextInputType.name,
      TextInputType.streetAddress,
    };
    return textTypes.contains(_textInputType);
  }
}

class _StandardTextField extends StatelessWidget {
  final bool? enabled;
  final bool readOnly;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final bool autofocus;
  final Color? textColor;
  final bool obscureText;
  final bool canRequestFocus;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final InputDecoration? decoration;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  // final Color? fillColor;
  // final String? initialValue;
  // final String? label;
  // final String? helperText;

  const _StandardTextField({
    required this.keyboardType,
    this.enabled,
    this.readOnly = false,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.textColor,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.controller,
    this.decoration,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
    this.canRequestFocus = true,
    this.obscureText = false,
    this.autofocus = false,
    // this.initialValue,
    // this.label,
    // this.fillColor,
    // this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: autofocus,
      controller: controller,
      // initialValue: initialValue,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      focusNode: focusNode,
      maxLength: maxLength,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      canRequestFocus: canRequestFocus,
      onFieldSubmitted: (v) => onFieldSubmitted?.call(v),
      style: TextStyle(
        color: enabled == false ? context.onSurfaceColor : textColor,
        overflow: TextOverflow.ellipsis,
      ),
      decoration: decoration,
      validator: validator,
      onChanged: onChanged,
    );
  }
}

class _LowercaseTextField extends StatelessWidget {
  final bool? enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final int? maxLength;
  final bool capsLockOn;
  final Color? textColor;
  final FocusNode? focusNode;
  final bool canRequestFocus;
  final void Function(String)? onChanged;
  final InputDecoration? inputDecoration;
  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onActionTriggered;

  // final String? initialValue;
  // final String? labelText;
  // final String? helperText;

  const _LowercaseTextField({
    this.enabled,
    this.readOnly = false,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.textColor,
    this.controller,
    this.textInputAction,
    this.inputDecoration,
    this.onFieldSubmitted,
    this.onActionTriggered,
    this.autofocus = false,
    this.capsLockOn = false,
    this.canRequestFocus = true,
    // this.labelText,
    // this.helperText,
    // this.initialValue,
  });

  TextEditingController? get _controller => controller;

  bool get _capsLockOn => capsLockOn;

  @override
  Widget build(BuildContext context) {
    return _buildTextField(context);
  }

  TextFormField _buildTextField(BuildContext context) {
    return TextFormField(
      autofocus: autofocus,
      // initialValue: initialValue,
      controller: _controller,
      enabled: enabled,
      readOnly: readOnly,
      focusNode: focusNode,
      canRequestFocus: canRequestFocus,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: TextInputType.text,
      textInputAction: textInputAction,
      style: TextStyle(
        color: enabled == false ? context.onSurfaceColor : textColor,
        overflow: TextOverflow.ellipsis,
      ),
      decoration: inputDecoration?.copyWith(
        errorText: _capsLockOn ? 'Caps Lock is on!' : null,
      ),
      inputFormatters: const [
        // Allow letters and spaces only
        // FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
        // Allow letters only
        // FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
        // Allow only lowercase letters
        // FilteringTextInputFormatter.allow(RegExp('[a-z]')),
      ],
      onFieldSubmitted: (v) {
        onActionTriggered?.call(v);
        onFieldSubmitted?.call(
          v,
        ); // Call the onChanged callback passed from the parent widget
      },
      onChanged: (v) {
        onActionTriggered?.call(v);
        onChanged?.call(
          v,
        ); // Call the onChanged callback passed from the parent widget
      },
      validator: validator,
    );
  }

  /*onChanged: (value) {
      onChanged?.call(value);

      setState(() {
        capsLockOn = _isCapsLockOn(value);
        // Convert text to lowercase
        _controller?.value = _controller!.value.copyWith(
          text: value.toLowerAll,
          // Maintain cursor position
          selection: TextSelection.collapsed(offset: value.length),
        );
      });
    },*/
}
