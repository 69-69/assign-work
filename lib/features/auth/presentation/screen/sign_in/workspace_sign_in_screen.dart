import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/animated_hexagon_grid.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/layout/custom_scroll_bar.dart';
import 'package:assign_erp/features/auth/presentation/bloc/sign_in/workspace/workspace_auth_bloc.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/form_title.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/left_column_pane.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/right_column_pane.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/show_sign_in_alert.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/workspace_acc_guide.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/workspace_form_inputs.dart';
import 'package:assign_erp/features/auth/presentation/screen/workspace/forgot/forgot_workspace_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkspaceSignInScreen extends StatelessWidget {
  const WorkspaceSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    /*MINE-STEVE
    return BlocProvider(
      create: (context) {
        return SignInBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        );
      },
      child:*/
    return CustomScaffold(
      backButton: const SizedBox.shrink(),
      bgColor: kLightBlueColor,
      body: CustomScrollBar(
        controller: ScrollController(),
        padding: EdgeInsets.only(top: 0, bottom: context.bottomInsetPadding),
        child: _buildBody(context),
      ),
      actions: [],
      bottomNavigationBar: const SizedBox.shrink(),
    );
  }

  BlocListener<WorkspaceAuthBloc, WorkspaceAuthState> _buildBody(
    BuildContext context,
  ) {
    return BlocListener<WorkspaceAuthBloc, WorkspaceAuthState>(
      listenWhen: (oldState, newState) => oldState.status != newState.status,
      listener: (_, state) => context.showWorkspaceSignInAlert(state),
      child: Container(
        decoration: const BoxDecoration(
          color: kGrayBlueColor,
          image: DecorationImage(image: AssetImage(appBg), fit: BoxFit.cover),
        ),
        child: AnimatedHexagonGrid(
          child: AutofillGroup(child: _buildLayout(context)),
        ),
      ),
    );
  }

  _buildLayout(BuildContext context) {
    return AdaptiveLayout(
      firstFlex: 3,
      isSizedBox: false,
      children: [
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: Center(
            child: Column(
              children: [
                FormTitle(
                  title: welcomeTitle,
                  subtitle: 'Everything you need to run your business',
                  // All-in-one Productivity Tool
                ),
                const SizedBox(height: 6),
                _leftColumnPane(),
              ],
            ),
          ),
        ),
        _RightColumnPane(),
      ],
    );
  }

  Widget _leftColumnPane() {
    return LeftColumnPane(
      title: 'Workspace Sign In',
      subtitle: "First, Sign In with your Company's workspace ID.",
      children: [
        const Flexible(child: EmailInput()),
        const SizedBox(height: 20),
        const Flexible(child: PasswordInput(hidePlaceholder: true)),
        const SizedBox(height: 5),
        Flexible(child: WorkspaceSignInButton(onPressed: (v) {})),
      ],
    );
  }
}

class _RightColumnPane extends StatelessWidget {
  const _RightColumnPane();

  @override
  Widget build(BuildContext context) {
    return _buildRightColumn(context);
  }

  _buildRightColumn(BuildContext context) {
    return RightColumnPane(
      children: [
        _buildForgotPasswordBtn(context),
        const Divider(),
        const Flexible(
          child: WorkspaceGuide(isForgotPassword: true, isWorkspace: false),
        ),
      ],
    );
  }

  _buildForgotPasswordBtn(BuildContext cxt) {
    return cxt.elevatedIconBtn(
      Icon(Icons.help_outline, color: kWhiteColor),
      style: ElevatedButton.styleFrom(backgroundColor: kGrayBlueColor),
      label: Text(
        "Forgot Password?",
        semanticsLabel: "Forgot Password",
        overflow: TextOverflow.ellipsis,
        style: cxt.textTheme.titleLarge?.copyWith(color: kWhiteColor),
      ),
      onPressed: () async => await cxt.openForgotWorkspacePopUp(),
    );
  }
}
