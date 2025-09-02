import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/features/auth/presentation/bloc/sign_in/employee/employee_sign_in_bloc.dart';
import 'package:assign_erp/features/auth/presentation/bloc/sign_in/workspace/workspace_auth_bloc.dart';
import 'package:assign_erp/features/auth/presentation/screen/workspace/license_warning/license_warning.dart';
import 'package:flutter/material.dart';
import 'package:formz/formz.dart';

extension ShowSignInAlert on BuildContext {
  void showEmployeeSignInAlert(EmployeeSignInState state) {
    final isInputValid = state.email.isValid && state.passcode.isValid;
    final hasFailed = state.status.isFailure;
    final rawMessage = state.errorMessage ?? '';
    showSignInAlert(
      rawMessage,
      isInputValid: isInputValid,
      hasFailed: hasFailed,
    );
  }

  void showWorkspaceSignInAlert(WorkspaceAuthState state) {
    final isInputValid = state.email.isValid && state.password.isValid;
    final hasFailed = state.status.isFailure;
    final rawMessage = state.errorMessage ?? '';
    showSignInAlert(
      rawMessage,
      isWorkspace: true,
      isInputValid: isInputValid,
      hasFailed: hasFailed,
    );
  }

  /// Shows the alert overlay if there is a failure state.
  ///
  void showSignInAlert(
    String rawMessage, {
    bool isWorkspace = false,
    bool isInputValid = false,
    bool hasFailed = false,
  }) {
    if (isInputValid && hasFailed) {
      final simplifiedError = rawMessage.split(':').last.trim();

      prettyPrint('show-sign-in-error', simplifiedError);

      const fallbackMsg =
          'Something went wrong. Please tap the red refresh icon above.';

      final msg =
          simplifiedError.toLowerAll.contains(
            'cannot add new events after calling close',
          )
          ? fallbackMsg
          : (simplifiedError.isEmpty ? fallbackMsg : simplifiedError);

      // Ensure the overlay is displayed with the current context
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        showAlertOverlay(msg, bgColor: kDangerColor);

        if (isWorkspace && msg.toLowerAll.contains('license')) {
          await Future.delayed(kRProgressDelay);
          showUpgradeWarningDialog();
        }
      });
    }
  }
}
