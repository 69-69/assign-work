import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_dialog.dart';
import 'package:assign_erp/features/auth/presentation/bloc/sign_in/workspace/workspace_auth_bloc.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/workspace_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

extension UpdateWorkspacePopUp on BuildContext {
  Future<void> openUpdateWorkspacePopUp() async =>
      await ChangeWorkspacePassword().openCustomDialog(
        this,
        isScrollControlled: true,
        constraints: null,
      );
}

class ChangeWorkspacePassword extends StatelessWidget {
  const ChangeWorkspacePassword({super.key});

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
      bgColor: context.scaffoldBgColor,
      title: DialogTitle(
        title: 'Change Workspace Password',
        subtitle:
            "This is your Organization Password: ${context.workspace?.name ?? ''}",
      ),
      body: _buildFormBody(context),
      actions: const [UpdateWorkspacePasswordButton()],
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
        child: const AutofillGroup(
          child: PasswordInput(label: 'New password', checkPrevious: false),
        ),
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
      context.showAlertOverlay('Workspace password updated!');
    }
  }
}
