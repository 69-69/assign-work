import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/animated_hexagon_grid.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/domain/repository/auth_repository.dart';
import 'package:assign_erp/features/auth/presentation/bloc/index.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/employee_form_inputs.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/form_title.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/left_column_pane.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/right_column_pane.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/workspace_acc_guide.dart';
import 'package:assign_erp/features/auth/presentation/screen/workspace/create/create_workspace_acc.dart';
import 'package:assign_erp/features/refresh_entire_app.dart';
import 'package:assign_erp/features/setup/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

class ChangeEmployeePasscodeScreen extends StatefulWidget {
  const ChangeEmployeePasscodeScreen({super.key});

  @override
  State<ChangeEmployeePasscodeScreen> createState() =>
      _ChangeEmployeePasscodeScreenState();
}

class _ChangeEmployeePasscodeScreenState
    extends State<ChangeEmployeePasscodeScreen> {
  final PrintoutSetupCacheService _printoutService =
      PrintoutSetupCacheService();
  final ScrollController _scrollController = ScrollController();
  bool isOnboardingAllowed = false;
  bool isTemporaryPasscode = false;
  String? companyLogo;

  @override
  void initState() {
    super.initState();
    _loadCompanyLogo();
  }

  _loadCompanyLogo() async {
    final settings = await _printoutService.getSettings();
    if (settings != null) {
      setState(() => companyLogo = settings.companyLogo);
    }
  }

  void _canAccessOnboarding() {
    // If current workspace-role can create first-time Agent Workspace
    isOnboardingAllowed = WorkspaceRoleGuard.canAccessOnboarding(context);
  }

  /// Shows the alert overlay if there is a failure state.
  void _showSignInAlert(EmployeeSignInState state, BuildContext context) {
    if (state.passcode.isValid && state.status.isFailure) {
      final msg =
          state.errorMessage ??
          'Something went wrong...Sign out and SignIn again!';

      // Ensure the overlay is displayed with the current context
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.showAlertOverlay(msg, bgColor: kDangerColor);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _canAccessOnboarding();

    return BlocProvider(
      create: (context) {
        return EmployeeSignInBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        );
      },
      child: _buildBody(context),
    );
  }

  BlocListener<EmployeeSignInBloc, EmployeeSignInState> _buildBody(
    BuildContext context,
  ) {
    return BlocListener<EmployeeSignInBloc, EmployeeSignInState>(
      listenWhen: (oldState, newState) => oldState.status != newState.status,
      listener: (_, state) => _showSignInAlert(state, context),
      child: CustomScaffold(
        backButton: const SizedBox.shrink(),
        bgColor: kLightBlueColor,
        body: CustomScrollBar(
          controller: _scrollController,
          padding: EdgeInsets.only(top: 0, bottom: context.bottomInsetPadding),
          child: Container(
            decoration: const BoxDecoration(
              color: kGrayBlueColor,
              image: DecorationImage(
                image: AssetImage(appBg),
                fit: BoxFit.cover,
              ),
            ),
            child: AnimatedHexagonGrid(child: _buildCard(context)),
          ),
        ),
        actions: [
          context.reloadAppIconButton(
            onPressed: () => RefreshEntireApp.restartApp(context),
          ),
        ],
        bottomNavigationBar: const SizedBox.shrink(),
      ),
    );
  }

  _buildCard(BuildContext context) {
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
                  title:
                      context.authSession?.employee?.fullName ??
                      'Create Passcode',
                  subtitle: 'Create a new employee passcode',
                ),
                const SizedBox(height: 6),
                _leftColumnPane(),
              ],
            ),
          ),
        ),
        _RightColumnPane(isOnboardingAllowed: isOnboardingAllowed),
      ],
    );
  }

  Widget _leftColumnPane() {
    return LeftColumnPane(
      companyLogo: companyLogo,
      title: 'Create Employee Passcode',
      subtitle:
          "You signed in using a temporary employee passcode. Please create a new, secure employee passcode for your account!",
      children: [
        const Flexible(
          child: EmployeePasscodeInput(
            checkPrevious: false,
            isTemporary: false,
            label: 'New Employee Passcode',
          ),
        ),
        const Flexible(child: ChangeEmployeePasscodeButton()),
      ],
    );
  }
}

class _RightColumnPane extends StatelessWidget {
  final bool isOnboardingAllowed;

  const _RightColumnPane({required this.isOnboardingAllowed});

  @override
  Widget build(BuildContext context) {
    return _buildRightColumn(context);
  }

  _buildRightColumn(BuildContext context) {
    return RightColumnPane(
      signOutButton: context.signOutButton(
        onPressed: () {
          _handleSignOut(context);
          RefreshEntireApp.restartApp(context);
        },
      ),
      children: [
        if (isOnboardingAllowed) ...{
          _buildOpenCreateWorkspaceButton(context),
          const Divider(),
        },
        Flexible(child: WorkspaceGuide(isWorkspace: isOnboardingAllowed)),
      ],
    );
  }

  _buildOpenCreateWorkspaceButton(BuildContext context) {
    return context.elevatedIconBtn(
      Icon(Icons.workspaces_outline, color: kWhiteColor),
      style: ElevatedButton.styleFrom(backgroundColor: kGrayBlueColor),
      onPressed: () => context.openCreateWorkspacePopUp(),
      label: Text(
        'Setup New Workspace',
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.titleLarge?.copyWith(color: kWhiteColor),
      ),
    );
  }

  _handleSignOut(BuildContext context) {
    final authBloc = BlocProvider.of<AuthBloc>(context);
    authBloc.add(AuthSignOutRequested());
  }
}
