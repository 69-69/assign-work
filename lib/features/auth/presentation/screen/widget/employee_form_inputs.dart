import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/extensions/account_status.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/auth/presentation/bloc/sign_in/employee/employee_sign_in_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

// Email
class EmailInput extends StatelessWidget {
  final bool checkMobileNumber;
  final String label;

  const EmailInput({
    super.key,
    this.checkMobileNumber = false,
    this.label = 'Workspace email',
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeSignInBloc, EmployeeSignInState>(
      buildWhen: (prev, cur) => prev.email != cur.email,
      builder: (context, state) => _emailFormField(context, state),
    );
  }

  _emailFormField(BuildContext context, EmployeeSignInState state) {
    return CustomTextField(
      key: const Key('emp_sign_in_emailInput_textField'),
      textInputType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      onChanged: (email) => context.read<EmployeeSignInBloc>().add(
        EmployeeSignInEmailChanged(email.trim()),
      ),
      inputDecoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.all(1.0),
        hintText: label,
        label: Text(label, semanticsLabel: label),
        alignLabelWithHint: true,
        fillColor: kGrayColor.toAlpha(0.1),
        errorText: state.email.displayError != null ? 'Invalid email' : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.email, size: 15),
      ),
    );
  }
}

/// Employee's Passcode [EmployeePasscodeInput]
/// Passcode required during employee sign-in process,
/// after the organization's workspace sign-in.
class EmployeePasscodeInput extends StatefulWidget {
  /// Check if previous FormTextField is valid before showing Passcode Input Field [isTemporary]
  final bool checkPrevious;
  final bool isTemporary;
  final String label;

  const EmployeePasscodeInput({
    super.key,
    required this.label,
    this.checkPrevious = false,
    this.isTemporary = false,
  });

  @override
  State<EmployeePasscodeInput> createState() => _EmployeePasscodeInputState();
}

class _EmployeePasscodeInputState extends State<EmployeePasscodeInput> {
  bool _secureText = true;
  final TextEditingController _controller = TextEditingController();
  final String helperText =
      'Generate temporary passcode for employee access to the organization\'s workspace.';

  String get _label => widget.label;

  // Whether previous validation (like email/password) should be checked before showing passcode field
  bool get _checkPrevious => widget.checkPrevious;

  // Whether the passcode should be auto-generated
  bool get _autoGenerate => widget.isTemporary;

  void showHide() => setState(() => _secureText = !_secureText);

  // Generates a Temporary passcode and dispatching to the Bloc
  void _generateAndDispatchPasscode() {
    final temp = '$kTemporaryPasscodeLength'.generateUID(type: UIDType.numeric);
    final passcode = '$kTemporaryPasscodePrefix$temp';

    // Update the TextField and trigger the Bloc event
    setState(() => _controller.text = passcode);
    _dispatchPasscodeChangeEvent(passcode);
  }

  @override
  void initState() {
    super.initState();
    // If auto-generation is enabled, generate a passcode
    if (_autoGenerate) {
      // Generate and dispatch the initial passcode once the widget is built
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _generateAndDispatchPasscode(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show passcode field or Temporary passcode tile based on autoGenerate flag
    return _autoGenerate
        ? _buildTemporaryPasscodeTile()
        : _buildPasscodeBlocBuilder();
  }

  /// Builds Temporary passcode input section
  _buildTemporaryPasscodeTile() {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Text(
          'Employee passcode required after organizational workspace sign-in',
          style: context.textTheme.bodyMedium?.copyWith(
            color: kBgLightColor, // Styling for the text
          ),
        ),
      ),
      // Shows the passcode field wrapped in a BlocBuilder
      subtitle: _buildPasscodeBlocBuilder(),
    );
  }

  /// Builds the BlocBuilder for handling state changes of the EmployeeSignInBloc
  Widget _buildPasscodeBlocBuilder() {
    return BlocBuilder<EmployeeSignInBloc, EmployeeSignInState>(
      buildWhen: (prev, curr) {
        // Checks whether passcode, password, or email state has changed
        final passcodeChanged = prev.passcode != curr.passcode;
        final emailChanged = prev.email != curr.email;

        // Only trigger a rebuild if relevant state changes occur
        return passcodeChanged || emailChanged;
      },
      builder: (context, state) {
        // Determine if the passcode field should be displayed based on the autoGenerate flag or form validation
        final shouldRender =
            (_checkPrevious && state.email.isValid) || !_checkPrevious;
        return shouldRender
            ? _buildPasscodeField(
                context,
                state,
              ) // Show passcode field if shouldRender is true
            : const SizedBox.shrink();
      },
    );
  }

  /// Builds the CustomTextField widget for the passcode input
  Widget _buildPasscodeField(BuildContext context, EmployeeSignInState state) {
    return CustomTextField(
      key: const Key('auth_pass_code_textField'),
      controller: _controller,
      obscureText: _secureText,
      maxLines: 1,
      maxLength: 20,
      autofillHints: const [AutofillHints.password],
      textInputType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      onChanged: _dispatchPasscodeChangeEvent,
      onFieldSubmitted: _dispatchPasscodeChangeEvent,
      inputDecoration: _buildInputDecoration(context, state),
    );
  }

  // Builds the input decoration for the passcode field (either Temporary or regular)
  InputDecoration _buildInputDecoration(
    BuildContext context,
    EmployeeSignInState state,
  ) {
    final isTemporary = _autoGenerate; // Check if it's a Temporary passcode
    final label = isTemporary ? 'Temporary Passcode' : _label;

    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.all(1.0),
      fillColor: kGrayColor.toAlpha(0.1),
      hintText: isTemporary ? null : label,
      label: Text(label, semanticsLabel: label),
      helperText: isTemporary ? helperText : null,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      alignLabelWithHint: true,
      prefixIcon: Icon(Icons.lock, size: 15),
      errorText: state.passcode.displayError != null ? 'Invalid $label' : null,
      suffixIcon: isTemporary
          ? FittedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _toggleVisibility(),
                  const SizedBox(width: 4),
                  _generateButton(context),
                  const SizedBox(width: 4),
                ],
              ),
            )
          : _toggleVisibility(),
    );
  }

  Widget _generateButton(BuildContext context) {
    return context.elevatedButton(
      'Generate',
      tooltip: helperText,
      txtColor: kWhiteColor,
      bgColor: kDangerColor,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      onPressed: _generateAndDispatchPasscode,
    );
  }

  IconButton _toggleVisibility() {
    return IconButton(
      onPressed: showHide,
      icon: Icon(
        _secureText ? Icons.visibility_off : Icons.visibility,
        color: _secureText ? kGrayColor : kTextColor,
        semanticLabel: 'visibility icon',
      ),
    );
  }

  // Dispatches the PasscodeChanged event to the EmployeeSignInBloc with the updated passcode
  void _dispatchPasscodeChangeEvent(String passcode) {
    context.read<EmployeeSignInBloc>().add(
      EmployeePasscodeChanged(passcode.trim()),
    ); // Update the passcode in the state
  }
}

// Employee Button
class EmployeeSignInButton extends StatelessWidget {
  const EmployeeSignInButton({super.key, this.onChanged});

  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeSignInBloc, EmployeeSignInState>(
      builder: (context, state) {
        final inProgress = state.status.isInProgress;

        return _buildButton(
          context,
          isDisabled: !state.isValid || inProgress,
          inProgress: inProgress,
          onPress: (state.email.isValid && state.passcode.isValid)
              ? () => context.read<EmployeeSignInBloc>().add(
                  EmployeeSignInRequested(),
                )
              : null,
        );
      },
    );
  }

  _buildButton(
    BuildContext context, {
    bool inProgress = false,
    bool isDisabled = false,
    required void Function()? onPress,
  }) => context.confirmableActionButton(
    isPaired: false,
    submitLabel: inProgress ? "Please wait..." : "Sign In",
    onSubmit: onPress,
    isDisabled: isDisabled,
  );
}

// Change Employee Passcode Button
class ChangeEmployeePasscodeButton extends StatelessWidget {
  const ChangeEmployeePasscodeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeSignInBloc, EmployeeSignInState>(
      builder: (context, state) {
        return _buildButton(
          context,
          inProgress: state.status.isInProgress,
          onPress: state.passcode.isValid
              ? () {
                  context.read<EmployeeSignInBloc>().add(
                    ChangePasscodeRequested(),
                  );
                }
              : null,
        );
      },
    );
  }

  _buildButton(
    BuildContext context, {
    bool inProgress = false,
    required void Function()? onPress,
  }) => context.confirmableActionButton(
    submitLabel: inProgress ? "Please wait..." : "Create Passcode",
    onSubmit: onPress,
  );
}
