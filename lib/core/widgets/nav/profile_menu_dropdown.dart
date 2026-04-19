import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/extensions/hosting_type.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
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
  final bool isAppbar;
  final Function(bool)? isProfileOpen;

  const ProfileMenuDropdown({
    super.key,
    this.workspace,
    this.employee,
    this.isAppbar = true,
    this.isProfileOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = context.isLargeScreen;
    final routePath = GoRouter.of(context).state.matchedLocation;

    // Hide the profile menu on specific routes
    if (routePath == RouteNames.workspaceSignIn ||
        routePath.contains(RouteNames.employeeSignIn)) {
      return const SizedBox.shrink();
    }

    final borderRadius = BorderRadius.circular(8);
    final roleName = context.getRoleName;

    return Container(
      width: isAppbar ? null : 200,
      alignment: Alignment.center,
      margin: isAppbar
          ? EdgeInsets.fromLTRB(0, 20, 20, 20)
          : EdgeInsets.only(top: 10),
      decoration: isAppbar
          ? null
          : BoxDecoration(
              color: kPrimaryColor.toAlpha(0.8),
              borderRadius: borderRadius,
            ),
      child: PopupMenuButton<String>(
        tooltip: 'Menu',
        padding: EdgeInsets.zero,
        offset: const Offset(0, 60),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        onOpened: () {
          _isProfileOpen(true);
          // context.read<AccessControlCubit>().getNotifications();
        },
        onCanceled: _isProfileOpen,
        onSelected: (v) async => await _handleMenuAction(context, v),
        itemBuilder: (context) => _buildMenuItems(context, roleName: roleName),
        child: isAppbar
            ? _appBarProfileMenu(context, isLargeScreen, roleName: roleName)
            : _sideProfileMenu(context, roleName: roleName),
      ),
    );
  }

  void _isProfileOpen([bool open = false]) {
    if (isProfileOpen != null) {
      isProfileOpen!(open);
    }
  }

  CircleAvatar _buildCircleAvatar({double? radius, Color? bgColor}) {
    return CircleAvatar(
      maxRadius: radius,
      backgroundColor: bgColor ?? kLightBlueColor,
      child: Icon(Icons.person, color: kPrimaryColor),
    );
  }

  _sideProfileMenu(BuildContext context, {String? roleName}) {
    return Padding(
      padding: EdgeInsets.all(5.0),
      child: Row(
        children: [
          _buildCircleAvatar(radius: 16, bgColor: kWhiteColor),
          const SizedBox(width: 5),
          _buildUserDetails(context, roleName: roleName, color: kWhiteColor),
        ],
      ),
    );
  }

  _appBarProfileMenu(
    BuildContext context,
    bool isLargeScreen, {
    String? roleName,
  }) {
    return Padding(
      padding: EdgeInsets.all(2.0),
      child: Wrap(
        spacing: 10,
        direction: Axis.vertical,
        children: [
          if (isLargeScreen) ...[
            _buildUserDetails(context, roleName: roleName),
            const SizedBox(width: 10),
          ],
          _buildCircleAvatar(),
        ],
      ),
    );
  }

  Widget _buildUserDetails(
    BuildContext context, {
    String? roleName,
    Color? color,
  }) {
    final clientName = employee?.fullName.toTitle ?? '';
    final fontStyle = isAppbar
        ? context.textTheme.bodyMedium
        : context.textTheme.bodySmall;

    final txtColor = color ?? kLightBlueColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            clientName,
            style: fontStyle?.copyWith(
              color: txtColor,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          roleName.toTitle,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelSmall?.copyWith(
            color: txtColor,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildItem({
    required String value,
    required dynamic icon,
    required dynamic label,
  }) {
    return PopupMenuItem(
      value: value,
      child: ListTile(
        dense: true,
        mouseCursor: SystemMouseCursors.click,
        leading: icon is IconData ? Icon(icon) : icon,
        title: label is String ? Text(label) : label,
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context, {
    String? roleName,
  }) {
    List<PopupMenuEntry<String>> items = [];

    items.add(
      _buildItem(
        value: 'profile',
        icon: _buildCircleAvatar(radius: 16),
        label: _buildUserDetails(
          context,
          roleName: roleName,
          color: context.onPrimaryContainer,
        ),
      ),
    );
    if (isAppbar) {
      items.add(
        _buildItem(
          value: 'dashboard',
          icon: Icons.dashboard,
          label: 'Dashboard',
        ),
      );
    }

    items.addAll([
      _buildItem(
        value: 'refresh',
        icon: CupertinoIcons.refresh,
        label: 'Refresh Workspace',
      ),
      _buildItem(value: 'sign-out', icon: Icons.logout, label: 'Sign out'),
    ]);

    if (workspace != null) {
      items.add(
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _buildWorkspaceCard(context, workspace: workspace),
        ),
      );
    }

    return items;
  }

  Future<void> _handleMenuAction(BuildContext context, String value) async {
    switch (value) {
      case 'profile':
        await context.confirmAction<bool>(
          Text(
            'Change profile photo or notify Admin to update profile information.',
          ),
          title: "Change Profile",
          onAcceptLabel: "Notify Admin",
          onRejectLabel: "Change",
        );
        break;
      case 'dashboard':
        if (Navigator.of(context, rootNavigator: false).canPop()) {
          Navigator.of(context).pop();
        }
        break;
      case 'refresh':
        final isConfirmed = await context.confirmUserActionDialog(
          onAcceptLabel: 'Refresh',
          msg: 'Save your changes before refreshing the workspace.',
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
        color: kPrimaryColor.toAlpha(0.9),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const HorizontalDivider(
            thickness: 0.4,
            space: 1,
            divColor: kGrayBlueColor,
          ),
          _buildListTile(
            context,
            title:
                "Multi-Location: ${workspace.maxAllowedDevices > 1 ? 'On' : 'Off'}",
            subtitle: 'Max-Devices: ${workspace.maxAllowedDevices}',
          ),
          const HorizontalDivider(
            thickness: 0.4,
            space: 1,
            divColor: kGrayBlueColor,
          ),

          _buildListTile(
            context,
            title: 'Hosting: ${workspace.hostingType.getName}',
            subtitle: 'Store Branch: ${employee?.storeNumber}',
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
    return ListTile(
      dense: true,
      minTileHeight: 20.0,
      horizontalTitleGap: 0,
      minVerticalPadding: 3.0,
      contentPadding: EdgeInsets.zero,
      mouseCursor: SystemMouseCursors.click,
      visualDensity: VisualDensity.compact,
      title: Text(
        title.toUpperAll,
        style: context.textTheme.bodySmall?.copyWith(
          color: kLightGrayColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      subtitle: Text(
        subtitle.toTitle,
        style: context.textTheme.labelSmall?.copyWith(
          color: kLightGrayColor,
          overflow: TextOverflow.ellipsis,
          fontWeight: FontWeight.normal,
        ),
      ),
      onTap: () => context.goNamed(RouteNames.switchStoresAccount),
    );
    /*return Column(
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
    );*/
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final isConfirmed = await context.confirmUserActionDialog(
      onAcceptLabel: 'Sign Out',
    );
    if (context.mounted && isConfirmed) {
      final authBloc = BlocProvider.of<AuthBloc>(context);
      authBloc.add(AuthSignOutRequested());
    }
  }
}

/*
  List<PopupMenuEntry<String>> _buildMenuItems2(BuildContext context) {
    return [
      if (isAppbar) ...{
        PopupMenuItem(
          value: 'dashboard',
          child: ListTile(
            dense: true,
            mouseCursor: SystemMouseCursors.click,
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
          ),
        ),
      },
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

class ProfileMenuDropdown2 extends StatelessWidget {
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
            subtitle: 'Store Branch: ${employee?.storeNumber}',
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
