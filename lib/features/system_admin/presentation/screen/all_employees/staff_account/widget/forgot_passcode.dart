import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/secret_hasher.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_acc/employee_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/staff_account/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension ForgotPasscodeDialog on BuildContext {
  Future<void> openForgotPasscode({required Employee employee}) async =>
      await ForgotPasscode(
        employee: employee,
      ).openCustomDialog(this, isScrollControlled: true, constraints: null);
}

class ForgotPasscode extends StatefulWidget {
  final Employee employee;
  const ForgotPasscode({super.key, required this.employee});

  @override
  State<ForgotPasscode> createState() => _ForgotPasscodeState();
}

class _ForgotPasscodeState extends State<ForgotPasscode> {
  bool _shouldLogoutAfterReset = true;
  final _formKey = GlobalKey<FormState>();
  final _passcodeController = TextEditingController();
  Employee get _employee => widget.employee;

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: CustomDialog(
        title: DialogTitle(
          title: 'Reset Passcode',
          subtitle: "This is a One-time Passcode",
        ),
        body: _buildFormBody(context),
        actions: [
          context.confirmableActionButton(
            label: 'Copy & Use Passcode',
            onPressed: _onSubmit,
          ),
        ],
      ),
    );
  }

  _buildFormBody(BuildContext context) {
    return Container(
      width: context.screenWidth,
      padding: EdgeInsets.only(bottom: context.bottomInsetPadding),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Padding(
          padding: EdgeInsets.only(bottom: 30),
          child: Text(
            "Resets ${_employee.fullName.toTitle}'s account passcode to a temporary one. "
            "After signing in with this passcode, they will be required to create a new, secure passcode",
            // 'Use this at Employee Sign-In. After signing in with this passcode, you’ll be prompted to create your preferred passcode.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TemporaryPasscode(
              controller: _passcodeController,
              onChanged: (s) {
                if (_formKey.currentState!.validate()) setState(() {});
              },
            ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Expanded(child: Text("Auto-Sign out after passcode reset")),
                  InkWell(
                    onTap: () async => await _showInfoDialog(context),
                    child: Icon(Icons.info_outline, size: 18),
                  ),
                ],
              ),
              value: _shouldLogoutAfterReset,
              onChanged: (value) {
                setState(() => _shouldLogoutAfterReset = value ?? true);
              },
            ),
          ],
        ),
      ),
    );
  }

  _onSubmit() async {
    await context.progressBarDialog(
      child: Text(
        "Your passcode has been reset to a temporary one. "
        "After signing in, you'll be required to create a new, secure passcode.",
        textAlign: TextAlign.center,
      ),
      request: _processPasscodeReset(),
      onSuccess: (_) =>
          context.showAlertOverlay('Copied & Passcode Reset successful'),
      onError: (error) => context.showAlertOverlay(
        'Passcode Reset failed',
        bgColor: kDangerColor,
      ),
    );
  }

  Future<void> _processPasscodeReset() async {
    if (_formKey.currentState?.validate() ?? false) {
      final passcode = _passcodeController.text;

      await context.toClipboard(passcode); // Copy to clipboard
      final hashed = SecretHasher.hash(passcode);

      prettyPrint('data ', passcode);

      if (mounted) {
        context.read<EmployeeBloc>().add(
          UpdateSetup<Employee>(
            documentId: _employee.id,
            mapData: {'passCode': hashed},
          ),
        );

        // ✅ Simulate processing delay so dialog shows long enough
        await Future.delayed(kFProgressDelay);

        if (mounted && _shouldLogoutAfterReset) {
          context.read<AuthBloc>().add(AuthSignOutRequested());
        }
      }
    }
  }

  Future<void> _showInfoDialog(BuildContext context) async {
    await context.confirmDone(
      Text(
        "If enabled, you will be signed out immediately after the passcode is reset. "
        "This is useful when resetting an account from a shared or admin device.",
      ),
    );
  }
}
