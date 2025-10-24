import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/hosting_type.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/access_control/presentation/cubit/access_control_cubit.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:assign_erp/features/refresh_entire_app.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfileMenuDropdown extends StatelessWidget {
  final Workspace? workspace;
  final Employee? employee;

  const ProfileMenuDropdown({super.key, this.workspace, this.employee});

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = context.isLargeScreen;
    final routePath = GoRouter.of(context).state.matchedLocation;

    // Hide the profile menu on specific routes
    if (routePath == RouteNames.workspaceSignIn ||
        routePath.contains(RouteNames.employeeSignIn)) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.fromLTRB(0, 20, 20, 20),
      child: PopupMenuButton<String>(
        tooltip: 'Tap to open notifications',
        padding: EdgeInsets.zero,
        offset: const Offset(0, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) => _handleMenuAction(context, value),
        itemBuilder: (context) => _buildMenuItems(context),
        child: _buildProfileIcon(context, isLargeScreen),
      ),
    );
  }

  _buildProfileIcon(BuildContext context, bool isLargeScreen) {
    final roleName = context.getRoleName;

    return Padding(
      padding: EdgeInsets.all(2.0),
      child: Wrap(
        spacing: 10,
        direction: Axis.vertical,
        children: [
          if (isLargeScreen) ...[
            _buildUserDetails(context, roleName),
            const SizedBox(width: 10),
          ],
          const CircleAvatar(
            backgroundColor: kLightBlueColor,
            child: Icon(Icons.person, color: kPrimaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails(BuildContext context, String roleName) {
    final clientName = employee?.fullName.toTitle ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            clientName,
            style: context.textTheme.bodyMedium?.copyWith(
              color: kLightBlueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          roleName.toTitle,
          style: context.textTheme.labelSmall?.copyWith(color: kLightBlueColor),
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    return [
      PopupMenuItem(
        value: 'dashboard',
        child: ListTile(
          dense: true,
          mouseCursor: SystemMouseCursors.click,
          leading: const Icon(Icons.dashboard),
          title: const Text('Dashboard'),
        ),
      ),
      PopupMenuItem(
        value: 'refresh',
        child: ListTile(
          dense: true,
          mouseCursor: SystemMouseCursors.click,
          leading: const Icon(CupertinoIcons.refresh),
          title: const Text('Refresh Workspace'),
        ),
      ),
      PopupMenuItem(
        value: 'sign-out',
        child: ListTile(
          dense: true,
          mouseCursor: SystemMouseCursors.click,
          leading: Icon(Icons.logout),
          title: Text('Sign out'),
        ),
      ),
      if (workspace != null) ...[
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _buildWorkspaceCard(context, workspace: workspace),
        ),
      ],
    ];
  }

  void _handleMenuAction(BuildContext context, String value) async {
    switch (value) {
      case 'dashboard':
        context.pop();
        break;
      case 'refresh':
        final isConfirmed = await context.confirmUserActionDialog(
          onAccept: 'Refresh Workspace',
        );
        if (context.mounted && isConfirmed) {
          RefreshEntireApp.restartApp(context);
        }
        break;
      case 'sign-out':
        _handleSignOut(context);
        break;
    }
  }

  Widget _buildWorkspaceCard(BuildContext context, {Workspace? workspace}) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: kPrimaryLightColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workspace!.name.toUpperAll,
            style: context.textTheme.bodyLarge?.copyWith(
              color: kLightBlueColor,
            ),
          ),
          const HorizontalDivider(thickness: 4),
          _buildListTile(
            context,
            title: 'SUB.: ${context.readSubscriptionName}',
            subtitle: 'Validity: ${workspace.expiresOn.toStandardDT}',
          ),
          const HorizontalDivider(thickness: 0.4),
          _buildListTile(
            context,
            title:
                "Multi-Location: ${workspace.maxAllowedDevices > 1 ? 'On' : 'Off'}",
            subtitle: 'Max-Devices: ${workspace.maxAllowedDevices}',
          ),
          const HorizontalDivider(thickness: 0.4),
          _buildListTile(
            context,
            title: 'Hosting: ${workspace.hostingType.getValue}',
            subtitle: 'Store Location: ${employee?.storeNumber}',
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    String title = '',
    String subtitle = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperAll,
          style: context.textTheme.labelLarge?.copyWith(
            color: kWhiteColor,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle.toTitle,
          style: context.textTheme.labelMedium?.copyWith(
            color: kLightGrayColor,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final isConfirmed = await context.confirmUserActionDialog(
      onAccept: 'Sign Out',
    );
    if (context.mounted && isConfirmed) {
      final authBloc = BlocProvider.of<AuthBloc>(context);
      authBloc.add(AuthSignOutRequested());
    }
  }
}

/*class ProfileMenuDropdown2 extends StatelessWidget {
  final Workspace? workspace;
  final Employee? employee;

  const ProfileMenuDropdown2({super.key, this.workspace, this.employee});

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = context.isLargeScreen;
    final routePath = GoRouter.of(context).state.matchedLocation;

    // Hide the profile menu on specific routes
    if (routePath == RouteNames.workspaceSignIn ||
        routePath.contains(RouteNames.employeeSignIn)) {
      return const SizedBox.shrink();
    }

    return CupertinoContextMenu(
      actions: _menuActions(context, workspace: workspace),
      child: Container(
        color: kTransparentColor,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(20),
        child: Tooltip(
          message: 'Long press to show menu',
          child: _buildProfileIcon(context, isLargeScreen),
        ),
      ),
    );
  }

  Widget _buildProfileIcon(BuildContext context, bool isLargeScreen) {
    return Wrap(
      direction: Axis.vertical,
      spacing: 10,
      children: [
        if (isLargeScreen) ...[
          _buildUserDetails(context),
          const SizedBox(width: 10),
        ],
        const CircleAvatar(
          backgroundColor: kLightBlueColor,
          child: Icon(Icons.person, color: kPrimaryColor),
        ),
      ],
    );
  }

  Widget _buildUserDetails(BuildContext context) {
    final clientName = employee?.fullName.toUppercaseFirstLetterEach ?? '';
    final roleName = employee?.role.name.toUppercaseFirstLetter ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          clientName,
          style: context.textTheme.bodyMedium?.copyWith(
            color: kLightBlueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          roleName,
          style: context.textTheme.labelSmall?.copyWith(
            color: kLightBlueColor,
          ),
        ),
      ],
    );
  }

  List<Widget> _menuActions(BuildContext context, {Workspace? workspace}) {
    final actions = <Widget>[
      _buildMenuAction(
        context,
        label: 'Dashboard',
        icon: Icons.dashboard,
        onPressed: () => context.goNamed(RouteNames.mainDashboard),
      ),
      _buildMenuAction(
        context,
        label: 'Refresh App',
        icon: CupertinoIcons.refresh,
        onPressed: () async {
          final isConfirmed = await context.confirmUserActionDialog(
            onAccept: 'Refresh App',
          );
          if (context.mounted && isConfirmed) {
            RefreshEntireApp.restartApp(context);
          }
        },
      ),
      _buildMenuAction(
        context,
        isDefault: true,
        label: 'Sign out',
        icon: Icons.logout,
        onPressed: () => _handleSignOut(context),
      ),
      if (workspace != null) ...{
        _buildWorkspaceCard(context, workspace: workspace),
      },
    ];
    return actions;
  }

  Widget _buildWorkspaceCard(BuildContext context, {Workspace? workspace}) {
    return Container(
      color: kPrimaryLightColor,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (workspace!.workspaceName).toUpperCase(),
            style: context.textTheme.bodyLarge?.copyWith(
              color: kLightBlueColor,
            ),
          ),
          Divider(thickness: 6),

          _buildListTile(
            context,
            title: 'SUB.: ${workspace.license.name}',
            subtitle: 'Validity: ${workspace.expiresOn.toStandardDT}',
          ),
          _buildListTile(
            context,
            title:
                "Multi-Location: ${workspace.maxAllowedDevices > 1 ? 'On' : 'Off'}",
            subtitle: 'Max-Devices: ${workspace.maxAllowedDevices}',
          ),
          HorizontalLine(color: kGrayColor),
          _buildListTile(
            context,
            title: 'Hosting: ${workspace.hostingType.label}',
            subtitle: 'Store Location: ${employee?.storeNumber}',
          ),
        ],
      ),
    );
  }

  CupertinoContextMenuAction _buildMenuAction(
    BuildContext context, {
    VoidCallback? onPressed,
    String label = '',
    IconData? icon,
    bool isDefault = false,
  }) {
    return CupertinoContextMenuAction(
      isDestructiveAction: isDefault,
      onPressed: onPressed,
      trailingIcon: icon,
      child: Text(label),
    );
  }

  CupertinoListTile _buildListTile(
    BuildContext context, {
    String title = '',
    String subtitle = '',
  }) {
    return CupertinoListTile(
      padding: EdgeInsets.zero,
      title: SelectionArea(
        child: Text(
          title.toUppercaseAllLetter,
          style: context.textTheme.labelLarge?.copyWith(
            color: kLightColor,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      subtitle: SelectionArea(
        child: Text(
          subtitle.toUppercaseFirstLetterEach,
          style: context.textTheme.labelMedium?.copyWith(
            color: kLightGrayColor,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  _handleSignOut(BuildContext context) async {
    final isConfirmed = await context.confirmUserActionDialog(
      onAccept: 'Sign Out',
    );
    if (context.mounted && isConfirmed) {
      final authBloc = BlocProvider.of<AuthBloc>(context);
      authBloc.add(AuthSignOutRequested());
    }
  }
}*/
