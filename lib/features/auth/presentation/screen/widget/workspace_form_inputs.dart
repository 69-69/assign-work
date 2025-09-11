import 'dart:async';

import 'package:assign_erp/core/constants/account_status.dart';
import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/business_type_to_industries_dropdown.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/auth/data/role/workspace_role.dart';
import 'package:assign_erp/features/auth/presentation/bloc/sign_in/workspace/workspace_auth_bloc.dart';
import 'package:assign_erp/features/auth/presentation/bloc/sign_in/workspace/workspace_creation_stages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

/// Workspace Account Role Dropdown [WorkspaceRoleDropdown]
class WorkspaceRoleDropdown extends StatelessWidget {
  const WorkspaceRoleDropdown({
    super.key,
    required this.onRoleChanged,
    this.initialValue,
  });

  final Function(String?) onRoleChanged;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    final strList = WorkspaceRoleHelper.toStringList();

    return StaticDropdown<String>(
      key: key,
      initialValue: initialValue,
      items: strList,
      label: strList.first,
      getValue: (role) => role,
      getDisplayText: (role) => role,
      onChanged: (String? v) => onRoleChanged(v),
    );
  }
}

/// Workspace Category Dropdown [workspace Category]
class WorkspaceCategory extends StatelessWidget {
  const WorkspaceCategory({super.key, this.initialValue});

  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      buildWhen: (previous, current) =>
          previous.workspaceCategory != current.workspaceCategory,
      builder: (_, state) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BusinessToIndustriesDropdown(
      initialIndustry: initialValue,
      onIndustryChanged: (String? business, String? industry) {
        if (business != null && industry != null) {
          context.read<WorkspaceAuthBloc>().add(
            WorkspaceCategoryChanged('$business - $industry'),
          );
        }
      },
    );
  }

  /*StaticDropdown _buildBody2(BuildContext context, WorkspaceAuthState state) {
    return StaticDropdown<String>(
      initialValue: initialValue,
      label: 'Workspace category',
      items: workspaceCategories,
      getValue: (type) => type,
      getDisplayText: (type) => type,
      onChanged: (String? v) {
        if (v != null) {
          context.read<WorkspaceAuthBloc>().add(
            WorkspaceCategoryChanged(v.trim()),
          );
        }
      },
      buttonDecoration: InputDecoration(
        errorText: state.workspaceName.displayError != null
            ? 'Choose workspace category'
            : null,
      ),
    );
  }*/
}

// Workspace name
class WorkspaceNameInput extends StatelessWidget {
  const WorkspaceNameInput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      buildWhen: (previous, current) =>
          (previous.workspaceCategory != current.workspaceCategory) ||
          previous.workspaceName != current.workspaceName,
      builder: (cxt, state) => state.workspaceCategory.isValid
          ? _workspaceNameFormField(cxt, state)
          : _PendingPlaceholder(tooltip: 'business type'),
    );
  }

  _workspaceNameFormField(BuildContext context, WorkspaceAuthState state) {
    return CustomTextField(
      key: const Key('reg_Workspace_name_Form_Input_textField'),
      keyboardType: TextInputType.text,
      onChanged: (name) => context.read<WorkspaceAuthBloc>().add(
        WorkspaceNameChanged(name.trim()),
      ),
      inputDecoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.all(1.0),
        hintText: "Enter business name",
        label: const Text('Business name', semanticsLabel: 'Business name'),
        alignLabelWithHint: true,
        fillColor: kGrayColor.toAlpha(0.1),
        errorText: state.workspaceName.displayError != null
            ? 'Enter business name. Ex: Cash firms'
            : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.business, size: 15),
      ),
    );
  }
}

// Client name
class ClientNameInput extends StatelessWidget {
  const ClientNameInput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      buildWhen: (previous, current) =>
          (previous.workspaceName != current.workspaceName) ||
          previous.clientName != current.clientName,
      builder: (cxt, state) => state.workspaceName.isValid
          ? _nameFormField(cxt, state)
          : _PendingPlaceholder(tooltip: 'business name'),
    );
  }

  _nameFormField(BuildContext context, WorkspaceAuthState state) {
    return CustomTextField(
      key: const Key('reg_client_name_Form_Input_textField'),
      keyboardType: TextInputType.name,
      autofillHints: const [AutofillHints.name],
      onChanged: (clientName) => context.read<WorkspaceAuthBloc>().add(
        ClientNameChanged(clientName.trim()),
      ),
      inputDecoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.all(1.0),
        hintText: "Enter client name",
        label: const Text('Client name', semanticsLabel: 'Client name'),
        alignLabelWithHint: true,
        fillColor: kGrayColor.toAlpha(0.1),
        errorText: state.clientName.displayError != null
            ? 'Invalid Client name'
            : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.person, size: 15),
      ),
    );
  }
}

// Business Address
class AddressInput extends StatelessWidget {
  const AddressInput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      buildWhen: (prev, cur) =>
          (prev.clientName != cur.clientName) || prev.address != cur.address,
      builder: (context, state) {
        return state.clientName.isValid
            ? _addressFormField(context, state)
            : _PendingPlaceholder(tooltip: 'client name');
      },
    );
  }

  _addressFormField(BuildContext context, WorkspaceAuthState state) {
    return CustomTextField(
      key: const Key('reg_address_textField'),
      keyboardType: TextInputType.multiline,
      autofillHints: const [AutofillHints.streetAddressLevel1],
      maxLines: 3,
      onChanged: (number) =>
          context.read<WorkspaceAuthBloc>().add(AddressChanged(number.trim())),
      inputDecoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.all(1.0),
        hintText: "Enter business address",
        label: const Text(
          'Business address',
          semanticsLabel: 'Business address',
        ),
        alignLabelWithHint: true,
        fillColor: kGrayColor.toAlpha(0.1),
        errorText: state.address.displayError != null
            ? 'Invalid business address'
            : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.location_city, size: 15),
      ),
    );
  }
}

// MobileNumber
class MobileNumberInput extends StatelessWidget {
  const MobileNumberInput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      buildWhen: (prev, cur) =>
          (prev.address != cur.address) ||
          prev.mobileNumber != cur.mobileNumber,
      builder: (context, state) {
        return state.address.isValid
            ? _mobileFormField(context, state)
            : _PendingPlaceholder(tooltip: 'business address');
      },
    );
  }

  _mobileFormField(BuildContext context, WorkspaceAuthState state) {
    return CustomTextField(
      key: const Key('reg_name_Form_Input_textField'),
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumber],
      onChanged: (number) => context.read<WorkspaceAuthBloc>().add(
        SignInMobileChanged(number.trim()),
      ),
      inputDecoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.all(1.0),
        hintText: "Enter mobile number",
        label: const Text('Mobile number', semanticsLabel: 'Mobile number'),
        alignLabelWithHint: true,
        fillColor: kGrayColor.toAlpha(0.1),
        errorText: state.mobileNumber.displayError != null
            ? 'Invalid Mobile number'
            : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.phone, size: 15),
      ),
    );
  }
}

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
    return checkMobileNumber ? _buildCheck() : _buildNoCheck();
  }

  BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState> _buildCheck() {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      buildWhen: (prev, cur) =>
          (prev.mobileNumber != cur.mobileNumber) || prev.email != cur.email,
      builder: (context, state) => state.mobileNumber.isValid
          ? _emailFormField(context, state)
          : _PendingPlaceholder(tooltip: 'mobile number'),
    );
  }

  BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState> _buildNoCheck() {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      buildWhen: (prev, cur) => prev.email != cur.email,
      builder: (context, state) => _emailFormField(context, state),
    );
  }

  _emailFormField(BuildContext context, WorkspaceAuthState state) {
    return CustomTextField(
      key: const Key('sign_inForm_emailInput_textField'),
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      onChanged: (email) => context.read<WorkspaceAuthBloc>().add(
        SignInEmailChanged(email.trim()),
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

/// This PasswordInput is for either Employee or Workspace during Sign-In [PasswordInput]
class PasswordInput extends StatefulWidget {
  final String label;
  final bool hidePlaceholder;

  /// Check if FormTextField is valid before showing Password Input Field [checkPrevious]
  final bool checkPrevious;

  const PasswordInput({
    super.key,
    this.checkPrevious = true,
    this.hidePlaceholder = false,
    this.label = 'Workspace password',
  });

  @override
  State<PasswordInput> createState() => PasswordInputState();
}

class PasswordInputState extends State<PasswordInput> {
  bool _secureText = true;

  // Show / hide password
  void showHide() => setState(() => _secureText = !_secureText);

  @override
  Widget build(BuildContext context) {
    return widget.checkPrevious ? _buildCheck() : _buildNoCheck();
  }

  /// Check if email is valid before showing Password Input Field [_buildCheck]
  BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState> _buildCheck() {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      buildWhen: (prev, cur) =>
          (prev.email != cur.email) || (prev.password != cur.password),
      builder: (context, state) => state.email.isValid
          ? _passwordFormField(context, state)
          : widget.hidePlaceholder
          ? const SizedBox.shrink()
          : _PendingPlaceholder(tooltip: 'email'),
    );
  }

  /// Don't check if email is valid, before showing Password Input Field [_buildNoCheck]
  BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState> _buildNoCheck() {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      buildWhen: (prev, cur) => prev.password != cur.password,
      builder: (context, state) => _passwordFormField(context, state),
    );
  }

  _passwordFormField(BuildContext context, WorkspaceAuthState state) {
    return CustomTextField(
      key: const Key('auth_Form_passwordInput_textField'),
      maxLines: 1,
      maxLength: 20,
      obscureText: _secureText,
      autofillHints: const [AutofillHints.password],
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (password) =>
          dispatchPasswordChangeEvent(password.trim()),
      onChanged: (password) => dispatchPasswordChangeEvent(password.trim()),
      // validator: (v) => v!.length < 4 ? "Enter valid password" : null,
      inputDecoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.all(1.0),
        fillColor: kGrayColor.toAlpha(0.1),
        hintText: widget.label,
        label: Text(widget.label, semanticsLabel: widget.label),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.lock, size: 15),
        errorText: state.password.displayError != null
            ? 'Invalid password'
            : null,
        alignLabelWithHint: true,
        suffixIcon: IconButton(
          onPressed: showHide,
          icon: Icon(
            _secureText ? Icons.visibility_off : Icons.visibility,
            color: _secureText ? kGrayColor : kTextColor,
            semanticLabel: 'visibility icon',
          ),
        ),
        /*border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),*/
      ),
    );
  }

  void dispatchPasswordChangeEvent(String password) {
    context.read<WorkspaceAuthBloc>().add(
      SignInPasswordChanged(password.trim()),
    );
  }
}

/// Employee's Passcode [TemporaryPasscodeInput]
/// Temporary Employee Passcode required during employee sign-in process,
/// after the organization's workspace sign-in.
class TemporaryPasscodeInput extends StatefulWidget {
  const TemporaryPasscodeInput({super.key});

  @override
  State<TemporaryPasscodeInput> createState() => _TemporaryPasscodeInputState();
}

class _TemporaryPasscodeInputState extends State<TemporaryPasscodeInput> {
  bool _secureText = true;
  final TextEditingController _controller = TextEditingController();
  final String helperText =
      'Generate temporary passcode for employee access to the organization\'s workspace.';

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

    // Generate and dispatch the initial passcode once the widget is built
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _generateAndDispatchPasscode(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      buildWhen: (prev, cur) =>
          (prev.password != cur.password) ||
          (prev.temporaryPasscode != cur.temporaryPasscode),
      builder: (context, state) {
        return state.password.isValid
            ? _buildPasscodeField(context, state)
            : _PendingPlaceholder(tooltip: 'password');
      },
    );
  }

  /// Builds the CustomTextField widget for the passcode input
  Widget _buildPasscodeField(BuildContext context, WorkspaceAuthState state) {
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
      subtitle: CustomTextField(
        key: const Key('auth_pass_code_textField'),
        controller: _controller,
        obscureText: _secureText,
        maxLines: 1,
        maxLength: 20,
        autofillHints: const [AutofillHints.password],
        keyboardType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.done,
        onChanged: _dispatchPasscodeChangeEvent,
        onFieldSubmitted: _dispatchPasscodeChangeEvent,
        inputDecoration: _buildInputDecoration(context, state),
      ),
    );
  }

  // Builds the input decoration for the passcode field (either temporal or regular)
  InputDecoration _buildInputDecoration(
    BuildContext context,
    WorkspaceAuthState state,
  ) {
    final label = 'Temporal Passcode';

    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.all(1.0),
      fillColor: kGrayColor.toAlpha(0.1),
      label: Text(label, semanticsLabel: label),
      helperText: helperText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      alignLabelWithHint: true,
      prefixIcon: Icon(Icons.pin, size: 15),
      errorText: state.password.displayError != null
          ? 'Invalid passcode'
          : null,
      suffixIcon: FittedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _toggleVisibility(),
            const SizedBox(width: 4),
            _generateButton(context),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _generateButton(BuildContext context) {
    return context.elevatedButton(
      'Generate',
      tooltip: helperText,
      txtColor: kWhiteColor,
      bgColor: kDangerColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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

  // Dispatches the PasscodeChanged event to the SignInBloc with the updated passcode
  void _dispatchPasscodeChangeEvent(String passcode) {
    context.read<WorkspaceAuthBloc>().add(
      TemporaryPasscodeChanged(passcode.trim()),
    );
  }
}

// Workspace SignIn Button
class WorkspaceSignInButton extends StatelessWidget {
  const WorkspaceSignInButton({super.key, required this.onPressed});

  final Function(bool) onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      builder: (context, state) {
        return _buildButton(
          context,
          isDisabled: !state.password.isValid,
          inProgress: state.status.isInProgress,
          onPress: (state.email.isValid && state.password.isValid)
              ? () {
                  onPressed.call(true);
                  context.read<WorkspaceAuthBloc>().add(SignInRequested());
                }
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
    label: inProgress ? "Please wait..." : "Sign In",
    onPressed: onPress,
    isDisabled: isDisabled,
  );
}

// Create/Register Workspace Button
class CreateWorkspaceButton extends StatelessWidget {
  const CreateWorkspaceButton({super.key, required this.onPressed});

  final Function(bool) onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      builder: (context, state) {
        final currentStage = state.creationStage;
        // final stages = _allStages;
        prettyPrint('steven', currentStage.name);

        return _buildButton(
          context,
          isDisabled: !state.isValid,
          inProgress: state.status.isInProgress,
          onPress: state.isValid
              ? () async {
                  /*onPressed.call(true);
                  context.read<WorkspaceAuthBloc>().add(
                    CreateWorkspaceRequested(),
                  );*/
                  await _workspaceAction(context, currentStage);
                }
              : null,
        );
      },
    );
  }

  _workspaceAction(
    BuildContext context,
    WorkspaceCreationStage currentStage,
  ) async {
    final setupCompleter = Completer<void>();

    await context.progressBarDialog(
      child: BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
        buildWhen: (prev, next) => prev.creationStage == next.creationStage,
        builder: (context, state) {
          prettyPrint('🔄 Stage:', '${state.creationStage}');
          return WorkspaceSetupProgress(onComplete: setupCompleter);
        },
      ),
      request: _registerWorkspace(context, setupCompleter),
      onSuccess: (_) => context.showAlertOverlay('Setup was successful'),
      onError: (error) =>
          context.showAlertOverlay('Setup failed', bgColor: kDangerColor),
    );
  }

  Future<void> _registerWorkspace(
    BuildContext context,
    Completer<void> setupCompleter,
  ) async {
    onPressed.call(true);
    await setupCompleter.future;
    if (context.mounted) {
      onPressed.call(true);
      context.read<WorkspaceAuthBloc>().add(CreateWorkspaceRequested());
    }
  }

  _buildButton(
    BuildContext context, {
    bool inProgress = false,
    bool isDisabled = false,
    required void Function()? onPress,
  }) => context.confirmableActionButton(
    label: inProgress ? "Please wait..." : "Create Workspace",
    onPressed: onPress,
    isDisabled: isDisabled,
  );
}

class UpdateWorkspacePasswordButton extends StatelessWidget {
  const UpdateWorkspacePasswordButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      builder: (context, state) {
        return _buildButton(
          context,
          inProgress: state.status.isInProgress,
          onPress: state.password.isValid
              ? () async => await _updateWorkspacePassword(context)
              : null,
        );
      },
    );
  }

  Future<dynamic> _updateWorkspacePassword(BuildContext context) =>
      // Simulate delayed to complete Workspace Password Update
      Future.delayed(kRProgressDelay, () async {
        if (context.mounted) {
          context.read<WorkspaceAuthBloc>().add(UpdatePasswordRequested());
        }
      });

  _buildButton(
    BuildContext context, {
    bool inProgress = false,
    required void Function()? onPress,
  }) => context.confirmableActionButton(
    label: inProgress ? "Updating..." : "Change Workspace Password",
    onPressed: onPress,
  );
}

class ForgotWorkspacePasswordButton extends StatelessWidget {
  const ForgotWorkspacePasswordButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceAuthBloc, WorkspaceAuthState>(
      builder: (context, state) {
        return _buildButton(
          context,
          inProgress: state.status.isInProgress,
          onPress: state.email.isValid
              ? () => context.read<WorkspaceAuthBloc>().add(
                  PasswordRecoveryRequested(),
                )
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
    label: inProgress ? "Please wait..." : "Send Reset Link",
    onPressed: onPress,
  );
}

class _PendingPlaceholder extends StatelessWidget {
  final String? tooltip;
  const _PendingPlaceholder({this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Complete ${tooltip ?? 'previous step'} before continuing',
      child: SizedBox(
        height: 50,
        child: Opacity(
          opacity: 0.4,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: kGrayColor.toAlpha(0.5)),
            ),
            child: Center(
              child: Text('Pending...', textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}

// Workspace Setup Progress
class WorkspaceSetupProgress extends StatefulWidget {
  final Completer<void> onComplete;

  const WorkspaceSetupProgress({super.key, required this.onComplete});

  @override
  State<WorkspaceSetupProgress> createState() => _WorkspaceSetupProgressState();
}

class _WorkspaceSetupProgressState extends State<WorkspaceSetupProgress> {
  int _currentStageIndex = 0;
  late Timer _timer;

  List<WorkspaceCreationStage> get allStages => Workflow.allStages;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(kDProgressDelay, (timer) {
      if (_currentStageIndex < allStages.length - 1) {
        setState(() => _currentStageIndex++);
      } else {
        _timer.cancel();
        if (!widget.onComplete.isCompleted) {
          widget.onComplete.complete(); // ✅ notify parent
          // You can trigger logout or navigation here if needed
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    if (!widget.onComplete.isCompleted) {
      widget.onComplete.complete();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildInfoText(context),
        const SizedBox(height: 16),
        ..._buildStagesList(),
      ],
    );
  }

  Widget _buildInfoText(BuildContext context) {
    return Text(
      'Please wait...\n\n'
      'Setting up new Workspace...\n'
      'You\'ll be logged out after setup is complete.\n'
      'Check your email and click the verification link to finish the process.',
      textAlign: TextAlign.center,
      style: context.textTheme.bodyMedium?.copyWith(height: 1.5),
    );
  }

  List<Widget> _buildStagesList() {
    return allStages.asMap().entries.map((entry) {
      int index = entry.key;
      WorkspaceCreationStage stage = entry.value;

      return _StageText(
        key: Key(stage.name),
        stage: stage,
        isActive: index == _currentStageIndex,
        isCompleted: index < _currentStageIndex,
      );
    }).toList();
  }
}

class _StageText extends StatelessWidget {
  final WorkspaceCreationStage stage;
  final bool isActive;
  final bool isCompleted;

  const _StageText({
    super.key,
    required this.stage,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    Color stageColor = isCompleted
        ? kSuccessColor
        : (isActive ? kDangerColor : kGrayColor);

    return ListTile(
      dense: true,
      titleAlignment: ListTileTitleAlignment.center,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      minVerticalPadding: 0,
      horizontalTitleGap: 3.0,
      leading: isCompleted
          ? CircleAvatar(
              backgroundColor: stageColor,
              radius: 9,
              child: Icon(Icons.check, color: kWhiteColor, size: 14),
            )
          : null,
      title: AnimatedDefaultTextStyle(
        duration: fAnimateDuration,
        style: context.textTheme.bodyMedium!.copyWith(
          color: stageColor,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
        child: Text(stage.stageMessage),
      ),
    );
  }
}
