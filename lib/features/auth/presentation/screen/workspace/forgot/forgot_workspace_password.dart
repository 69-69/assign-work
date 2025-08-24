import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_dialog.dart';
import 'package:assign_erp/features/auth/presentation/bloc/sign_in/workspace/workspace_auth_bloc.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/workspace_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

extension ForgotWorkspacePopUp on BuildContext {
  Future<void> openForgotWorkspacePopUp() => showModalBottomSheet(
    context: this,
    isDismissible: true,
    isScrollControlled: true,
    backgroundColor: kTransparentColor,
    builder: (_) => const ForgotWorkspacePassword(),
  );
}

class ForgotWorkspacePassword extends StatelessWidget {
  const ForgotWorkspacePassword({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildAlertDialog(context);

    /*MINE-STEVE
    return BlocProvider(
      create: (context) {
        return SignInBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        );
      },
      child: _buildAlertDialog(context),
    );*/
  }

  _buildAlertDialog(BuildContext context) {
    return CustomDialog(
      title: DialogTitle(
        title: 'Reset Workspace Password',
        subtitle: "This is your Organization Workspace Password",
      ),
      body: _buildFormBody(context),
      actions: const [ForgotWorkspacePasswordButton()],
    );
  }

  BlocListener<WorkspaceAuthBloc, WorkspaceAuthState> _buildFormBody(
    BuildContext context,
  ) {
    return BlocListener<WorkspaceAuthBloc, WorkspaceAuthState>(
      listenWhen: (oldState, newState) => oldState.status != newState.status,
      listener: (_, state) => _showSignUpAlert(state, context),
      child: Container(
        width: context.screenWidth,
        padding: EdgeInsets.only(bottom: context.bottomInsetPadding),
        child: const AutofillGroup(child: EmailInput()),
      ),
    );
  }

  /// Shows the alert overlay if there is a failure state.
  void _showSignUpAlert(WorkspaceAuthState state, BuildContext context) {
    if (state.password.isValid && state.status.isFailure) {
      const msg = 'Something went wrong! Kindly try again...';

      // Ensure the overlay is displayed with the current context
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.showAlertOverlay(msg, bgColor: kDangerColor);
      });
    } else if (state.status.isSuccess) {
      context.showAlertOverlay(
        duration: 6,
        'A password reset link for account recovery has been sent to the email associated with your workspace.!',
      );
    }
  }
}
