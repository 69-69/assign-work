import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/animated_hexagon_grid.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/data/role/workspace_role.dart';
import 'package:assign_erp/features/auth/presentation/bloc/index.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/employee_form_inputs.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/form_title.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/left_column_pane.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/right_column_pane.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/show_sign_in_alert.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/workspace_acc_guide.dart';
import 'package:assign_erp/features/auth/presentation/screen/workspace/create/create_workspace_acc.dart';
import 'package:assign_erp/features/refresh_entire_app.dart';
import 'package:assign_erp/features/setup/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeeSignInScreen extends StatefulWidget {
  const EmployeeSignInScreen({super.key});

  @override
  State<EmployeeSignInScreen> createState() => _EmployeeSignInScreenState();
}

class _EmployeeSignInScreenState extends State<EmployeeSignInScreen> {
  final PrintoutSetupCacheService _printoutService =
      PrintoutSetupCacheService();
  final ScrollController _scrollController = ScrollController();
  String? companyLogo;

  @override
  void initState() {
    super.initState();
    _loadCompanyLogo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  _loadCompanyLogo() async {
    final settings = await _printoutService.getSettings();
    if (settings != null) {
      setState(() => companyLogo = settings.companyLogo);
    }
  }

  bool _canAccessOnboarding() {
    final work = (context.read<AuthBloc>().state).workspace;
    return work?.role == WorkspaceRole.developer ||
        work?.role == WorkspaceRole.onboarding;
  }

  @override
  Widget build(BuildContext context) {
    /*MINE-STEVE
    return BlocProvider(
      create: (context) {
        return EmployeeSignInBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        );
      },
      child: */
    return CustomScaffold(
      backButton: const SizedBox.shrink(),
      bgColor: kLightBlueColor,
      body: CustomScrollBar(
        controller: _scrollController,
        padding: EdgeInsets.only(top: 0, bottom: context.bottomInsetPadding),
        child: _buildBody(context),
      ),
      actions: [
        context.reloadAppIconButton(
          onPressed: () => RefreshEntireApp.restartApp(context),
        ),
      ],
      bottomNavigationBar: const SizedBox.shrink(),
    );
  }

  BlocListener<EmployeeSignInBloc, EmployeeSignInState> _buildBody(
    BuildContext context,
  ) {
    return BlocListener<EmployeeSignInBloc, EmployeeSignInState>(
      listenWhen: (oldState, newState) => oldState.status != newState.status,
      listener: (_, state) => context.showEmployeeSignInAlert(state),
      child: Container(
        decoration: const BoxDecoration(
          color: kGrayBlueColor,
          image: DecorationImage(image: AssetImage(appBg), fit: BoxFit.cover),
        ),
        child: AnimatedHexagonGrid(child: _buildLayout(context)),
      ),
    );
  }

  _buildLayout(BuildContext context) {
    final canAccess = _canAccessOnboarding();

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
                  title: context.workspace?.name ?? 'Employee Account',
                  subtitle: 'Organization\'s Workspace',
                ),
                const SizedBox(height: 6),
                _leftColumnPane(),
              ],
            ),
          ),
        ),
        _RightColumnPane(isOnboardingAllowed: canAccess),
      ],
    );
  }

  LeftColumnPane _leftColumnPane() {
    return LeftColumnPane(
      companyLogo: companyLogo,
      title: employeeSignInTitle,
      subtitle: "Please sign in using your credentials now.",
      children: [
        const Flexible(child: EmailInput(label: 'Employee email')),
        const SizedBox(height: 20),
        const Flexible(
          child: EmployeePasscodeInput(
            checkPrevious: true,
            isTemporary: false,
            label: 'Employee passcode',
          ),
        ),
        const Flexible(child: EmployeeSignInButton()),
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
        onPressed: () => _handleSignOut(context),
      ),
      children: [
        if (isOnboardingAllowed) ...[
          _buildOpenCreateWorkspaceButton(context),
          const Divider(),
        ],
        Flexible(child: WorkspaceGuide(isWorkspace: isOnboardingAllowed)),
      ],
    );
  }

  _buildOpenCreateWorkspaceButton(BuildContext context) {
    return context.elevatedIconBtn(
      const Icon(Icons.workspaces_outline, color: kLightColor),
      style: ElevatedButton.styleFrom(backgroundColor: kGrayBlueColor),
      onPressed: () => context.openCreateWorkspacePopUp(),
      label: Text(
        'Setup New Workspace',
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.titleLarge?.copyWith(color: kLightColor),
      ),
    );
  }

  _handleSignOut(BuildContext context) {
    context.read<AuthBloc>().add(AuthSignOutRequested());
  }
}
