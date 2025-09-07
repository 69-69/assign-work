import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/hosting_type.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/access_control/presentation/cubit/access_control_cubit.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/home/data/permission/main_permission.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SideNav extends StatefulWidget {
  final List<DashboardTile> tiles;
  final bool Function(String)? canAccess;

  const SideNav({super.key, required this.tiles, this.canAccess});

  @override
  State<SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<SideNav> with SingleTickerProviderStateMixin {
  bool _isDrawerOpen = false;
  late bool _cachedIsMobile;
  late final AnimationController _controller;
  Animation<double>? _widthAnimation;

  Workspace? _workspace;
  Employee? _employee;

  @override
  void initState() {
    super.initState();
    _getWorkspace();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _cachedIsMobile = context.isMobile);
    });

    _controller = AnimationController(vsync: this, duration: kAnimateDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedIsMobile = context.isMobile;
    final beginWidth = _cachedIsMobile ? 200.0 : 50.0;
    _widthAnimation ??= Tween<double>(
      begin: beginWidth,
      end: 200.0,
    ).animate(_controller);
    _workspace ??= context.workspace;
    _employee ??= context.employee;
  }

  void _getWorkspace() {
    setState(() {
      _workspace = context.workspace;
      _employee = context.employee;
    });
  }

  bool get _shouldExpand => _cachedIsMobile || _isDrawerOpen;

  double get _dynamicWidth =>
      _shouldExpand ? (_widthAnimation?.value ?? 200) : 50;

  Color get _bgColor =>
      _shouldExpand ? kPrimaryLightColor : kTransparentColor; // secondaryColor
  Color get _iconColor =>
      _shouldExpand ? kWhiteColor : kLightBlueColor; // surfaceTintColor

  bool _canAccess(String access, BuildContext cxt) {
    final can =
        isUnknownPermission(access) ||
        cxt.isLicensed(access) ||
        cxt.hasPermission(access);
    return can;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Toggle the drawer open state and update the animation accordingly
  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      _isDrawerOpen ? _controller.forward() : _controller.reverse();
    });
  }

  void _toggleInDrawer() {
    setState(() {
      _isDrawerOpen = true;
      _controller.forward();
    });
  }

  void _toggleExitDrawer() {
    setState(() {
      _isDrawerOpen = false;
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          margin: EdgeInsets.only(left: 20),
          child: IconButton(
            alignment: Alignment.center,
            icon: const Icon(Icons.menu, color: kWhiteColor),
            style: ElevatedButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              // backgroundColor: kBrightPrimaryColor.toAlpha(0.6),
            ),
            onPressed: () =>
                _cachedIsMobile ? _buildMobileDrawer(context) : _toggleDrawer(),
          ),
        ),
        if (!_cachedIsMobile) Expanded(child: _buildDesktopDrawer(context)),
      ],
    );
  }

  void _buildMobileDrawer(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierLabel: "SideNav",
      barrierDismissible: true,
      builder: (BuildContext cxt) {
        return Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: _dynamicWidth,
            margin: EdgeInsets.fromLTRB(20, 100, 0, 0),
            height: cxt.screenHeight,
            child: _buildCard(cxt),
          ),
        );
      },
      /*transitionDuration: kAnimateDuration,
        transitionBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          );
        },*/
    );
  }

  AnimatedContainer _buildDesktopDrawer(BuildContext context) {
    return AnimatedContainer(
      margin: EdgeInsets.only(left: 20, right: _isDrawerOpen ? 20 : 0),
      height: context.screenHeight - (kAppBarHeight + 40),
      duration: kAnimateDuration,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return _cachedIsMobile
              ? _buildCard(context)
              : MouseRegion(
                  onEnter: (_) => _toggleInDrawer(),
                  onExit: (_) => _toggleExitDrawer(),
                  child: _buildCard(context),
                );
        },
      ),
    );
  }

  // Build the main content of the side navigation
  Widget _buildCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Material(
          color: kTransparentColor,
          child: _WorkspaceInfoCard(
            workspace: _workspace,
            employee: _employee,
            shouldExpand: _shouldExpand,
            dynamicWidth: _dynamicWidth,
            bgColor: _shouldExpand ? context.colorScheme.primary : _bgColor,
            iconColor: _iconColor,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildNav(context)),
      ],
    );
  }

  bool _shouldShowDashboardTile(BuildContext cxt) =>
      cxt.routeFromUri != '/${RouteNames.homeDashboard}';

  List<DashboardTile> _buildTiles(BuildContext cxt) {
    final List<DashboardTile> tiles = [];

    if (_shouldShowDashboardTile(cxt)) {
      // Add the dashboard tile if it's not on the main/home dashboard route
      tiles.add(
        DashboardTile(
          icon: Icons.dashboard,
          label: 'Dashboard',
          action: RouteNames.homeDashboard,
          description: 'Access to dashboard',
          access: getEnumName<MainPermission>(MainPermission.unknown),
        ),
      );
    }

    tiles.addAll(widget.tiles);
    return tiles;
  }

  Widget _buildNav(BuildContext context) {
    final tiles = _buildTiles(context);

    return SingleChildScrollView(
      primary: true,
      padding: EdgeInsets.only(bottom: 20),
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      child: _buildTileList(tiles, context),
    );
  }

  Widget _buildTileList(List<DashboardTile> tiles, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...tiles.map(
          (tile) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildLinks(context, tile: tile),
          ),
        ),
        _buildLogout(context),
      ],
    );
  }

  // Build individual navigation links
  Widget _buildLinks(BuildContext context, {required DashboardTile tile}) {
    final canAccess = widget.canAccess != null
        ? widget.canAccess!(tile.access)
        : _canAccess(tile.access, context);

    return TextButton.icon(
      style: _btnStyle(context),
      onPressed: canAccess
          ? () {
              tile.label.contains('dashboard')
                  ? context.pop()
                  : (tile.param.entries.isEmpty
                        ? context.goNamed(tile.action)
                        : context.goNamed(
                            tile.action,
                            extra: tile.param,
                            pathParameters: tile.param,
                          ));
            }
          : null,
      label: Text(
        softWrap: false,
        tile.label.toUpperAll,
        style: context.textTheme.bodySmall?.copyWith(
          color: kWhiteColor,
          overflow: TextOverflow.ellipsis,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(tile.icon, color: _iconColor),
    );
  }

  // Button style
  ButtonStyle _btnStyle(BuildContext context) {
    final base = TextButton.styleFrom(
      elevation: 30,
      padding: const EdgeInsets.all(6),
      backgroundColor: _bgColor,
      fixedSize: Size(_dynamicWidth, 50),
      disabledBackgroundColor: kGrayColor,
      alignment: _shouldExpand ? Alignment.centerLeft : Alignment.center,
      animationDuration: kAnimateDuration,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    );
    return _cachedIsMobile
        ? base
        : base.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (_shouldExpand && states.contains(WidgetState.disabled)) {
                return kGrayColor;
              }
              if (states.contains(WidgetState.hovered)) {
                return context.colorScheme.primary;
              }
              return _bgColor;
            }),
          );
  }

  // Build the logout button
  Widget _buildLogout(BuildContext context) {
    return TextButton.icon(
      style: _btnStyle(context).copyWith(
        backgroundColor: _shouldExpand
            ? WidgetStatePropertyAll(context.errorColor)
            : null,
      ),
      onPressed: () async {
        final isConfirmed = await context.confirmUserActionDialog(
          onAccept: 'Sign Out',
        );
        if (context.mounted && isConfirmed) {
          _handleSignOut(context);
        }
      },
      label: Text(
        'SIGN OUT',
        style: context.textTheme.bodySmall?.copyWith(
          color: kWhiteColor,
          overflow: TextOverflow.ellipsis,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(Icons.logout, color: _iconColor),
    );
  }

  // Handle the sign-out process
  void _handleSignOut(BuildContext context) {
    final authBloc = BlocProvider.of<AuthBloc>(context);
    authBloc.add(AuthSignOutRequested());
  }
}

class _WorkspaceInfoCard extends StatelessWidget {
  const _WorkspaceInfoCard({
    required this.shouldExpand,
    required this.dynamicWidth,
    required this.bgColor,
    required this.iconColor,
    this.workspace,
    this.employee,
  });

  final bool shouldExpand;
  final double dynamicWidth;
  final Color bgColor;
  final Color iconColor;
  final Workspace? workspace;
  final Employee? employee;

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  _buildBody(BuildContext context) {
    return workspace == null
        ? const SizedBox.shrink()
        : AnimatedContainer(
            width: dynamicWidth,
            padding: const EdgeInsets.all(6.0),
            duration: kAnimateDuration,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: _buildCard(context),
          );
  }

  Column _buildCard(BuildContext context) {
    // final miniScreen = context.screenHeight <= 600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          mouseCursor: SystemMouseCursors.click,
          title: Text(
            workspace!.name.toUpperAll,
            style: context.textTheme.bodyMedium?.copyWith(
              color: kWhiteColor,
              fontWeight: FontWeight.w600,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          leading: workspace != null
              ? Icon(Icons.workspaces, color: iconColor)
              : Image.asset(
                  appLogoWithBG,
                  scale: 24,
                  alignment: Alignment.centerLeft,
                ),
          onTap: () => context.goNamed(RouteNames.switchStoresAccount),
        ),
        if (shouldExpand) ...[
          Divider(thickness: 6),
          _buildListTile(
            context,
            title: 'SUB.: ${context.getSubscriptionName}',
            subtitle: 'Validity: ${workspace?.expiresOn.toStandardDT}',
          ),
          _buildListTile(
            context,
            title:
                "Multi-Location: ${workspace!.maxAllowedDevices > 1 ? 'On' : 'Off'}",
            subtitle: 'Max-Devices: ${workspace?.maxAllowedDevices}',
          ),
          _buildListTile(
            context,
            title: 'Hosting: ${workspace!.hostingType.getValue}',
            subtitle: 'Store Location: ${employee?.storeNumber}',
          ),
        ],
      ],
    );
  }

  ListTile _buildListTile(
    BuildContext context, {
    String title = '',
    String subtitle = '',
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      mouseCursor: SystemMouseCursors.click,
      title: Text(
        title.toUpperAll,
        style: context.textTheme.bodySmall?.copyWith(
          color: kWhiteColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      subtitle: Text(
        subtitle.toTitle,
        style: context.textTheme.labelSmall?.copyWith(
          color: kWhiteColor,
          overflow: TextOverflow.ellipsis,
          fontWeight: FontWeight.normal,
        ),
      ),
      onTap: () => context.goNamed(RouteNames.switchStoresAccount),
    );
  }
}

/*
// Build the toggle button for the side navigation drawer
  Widget _toggleButton(BuildContext context) {
    return TextButton.icon(
      style: _btnStyle(context).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          return states.contains(WidgetState.hovered)
              ? kGrayBlueColor
              : _bgColor;
        }),
      ),
      icon: Icon(_isDrawerOpen ? Icons.close : Icons.menu, color: _iconColor),
      onPressed: _toggleDrawer,
      label: Text(
        _isDrawerOpen ? 'Close' : 'Menu',
        style: context.textTheme.titleMedium?.copyWith(
          color: kLightBlueColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

Build the toggle button for the side navigation drawer
  Widget _profileButton(BuildContext context) {
    return TextButton.icon(
      style: _btnStyle(context),
      icon: _workspace != null
          ? Icon(Icons.workspaces, color: _iconColor)
          : Image.asset(
              appLogoWithBG,
              scale: 24,
              alignment: Alignment.centerLeft,
            ),
      onPressed: () => context.goNamed(RouteNames.swicthStoresAccount),
      label: Text(
        (_workspace?.workspaceName ?? appName).toUpperCase(),
        style: context.textTheme.titleMedium?.copyWith(
          color: kLightBlueColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }*/

/*// Build the navigation links list
  Widget _buildNav2(BuildContext context) {
    // Check if we're not on the main dashboard route
    final isNotOnDashboard = context.routeFromUri != RouteNames.mainDashboard;

    // Build the dashboard tile conditionally
    final List<DashboardTile> tiles = [
      if (isNotOnDashboard)
        DashboardTile(
          icon: Icons.dashboard,
          label: 'Dashboard',
          action: RouteNames.mainDashboard,
          description: 'Access to dashboard',
        ),
      ...widget.tiles,
    ];

    return SingleChildScrollView(
      primary: true,
      padding: EdgeInsets.zero,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...tiles.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildLinks(context, tile: s),
            ),
          ),
          _buildLogout(),
        ],
      ),
    );
  }*/
