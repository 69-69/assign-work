import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/extensions/hosting_type.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/nav/profile_menu_dropdown.dart';
import 'package:assign_erp/features/access_control/presentation/cubit/access_control_cubit.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/home/data/permission/main_permission.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _size = 40.0;

class SideNav extends StatefulWidget {
  final List<DashboardTile> tiles;
  final bool Function(String)? canAccess;

  const SideNav({super.key, required this.tiles, this.canAccess});

  @override
  State<SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<SideNav> with SingleTickerProviderStateMixin {
  bool _isDrawerOpen = false;
  bool _isProfileOpen = false;
  late bool _cachedIsMobile;
  late final AnimationController _controller;
  Animation<double>? _widthAnimation;

  Workspace? _workspace;
  Employee? _employee;

  @override
  void initState() {
    super.initState();
    _getWorkspace();

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncDeviceType());

    _controller = AnimationController(vsync: this, duration: kAnimateDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedIsMobile = context.isMobile;
    final beginWidth = _cachedIsMobile ? 200.0 : _size;

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

  bool get _shouldExpand => _isProfileOpen || _cachedIsMobile || _isDrawerOpen;

  double get _dynamicWidth =>
      _shouldExpand ? (_widthAnimation?.value ?? 200) : _size;

  Color get _bgColor => _shouldExpand
      ? kPrimaryColor.toAlpha(0.8)
      : kTransparentColor; // secondaryColor
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
      /*if (!_isDrawerOpen) {
        _isProfileOpen = false;
      }*/
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
      _isProfileOpen = false;
      _controller.reverse();
    });
  }

  void _syncDeviceType() {
    setState(() => _cachedIsMobile = context.isMobile);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          margin: EdgeInsets.only(left: 18.0),
          child: IconButton(
            alignment: Alignment.center,
            tooltip: '${_isDrawerOpen ? 'Close' : 'Open'} sidebar',
            icon: Icon(
              _isDrawerOpen ? Icons.menu_open : Icons.menu,
              color: kWhiteColor,
            ),
            style: ElevatedButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ).copyWith(backgroundColor: _buildResolveWith(context)),
            onPressed: () =>
                _cachedIsMobile ? _showMobileDrawer(context) : _toggleDrawer(),
          ),
        ),
        if (!_cachedIsMobile) Expanded(child: _buildDesktopDrawer(context)),
      ],
    );
  }

  WidgetStateProperty<Color?> _buildResolveWith(BuildContext context) {
    return WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (_shouldExpand && states.contains(WidgetState.disabled)) {
        return kGrayColor;
      }
      if (states.contains(WidgetState.hovered)) {
        return context.mainPrimaryColor;
      }
      return _bgColor;
    });
  }

  void _showMobileDrawer(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierLabel: "SideNav",
      barrierDismissible: true,
      builder: (BuildContext cxt) {
        return Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: _dynamicWidth,
            margin: EdgeInsets.fromLTRB(20, 120, 0, 20),
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
            bgColor: _shouldExpand ? context.mainPrimaryColor : _bgColor,
            iconColor: _iconColor,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildNav(context)),
        if (_shouldExpand) ...{
          Material(
            color: kTransparentColor,
            child: ProfileMenuDropdown(
              isAppbar: false,
              workspace: _workspace,
              employee: _employee,
              isProfileOpen: (v) => setState(() {
                Future.delayed(Duration(milliseconds: 20), () {
                  _isProfileOpen != v;
                  _toggleDrawer();
                });
              }),
            ),
          ),
        },
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
          route: RouteNames.homeDashboard,
          description: 'Access to dashboard',
          access: EnumUtil<MainPermission>(MainPermission.unknown).getName,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tiles
            .map(
              (tile) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SizedBox(
                  width: _dynamicWidth,
                  child: _buildLinks(context, tile: tile),
                ),
              ),
            )
            .toList(),
      ),
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
                        ? context.goNamed(tile.route)
                        : context.goNamed(
                            tile.route,
                            extra: tile.param,
                            pathParameters: tile.param,
                          ));
            }
          : null,
      label: _shouldExpand
          ? Text(
              softWrap: false,
              tile.getTitle.toUpperAll,
              style: context.textTheme.bodySmall?.copyWith(
                color: kWhiteColor,
                overflow: TextOverflow.ellipsis,
                fontWeight: FontWeight.w500,
              ),
            )
          : const SizedBox.shrink(),
      icon: Icon(tile.icon, color: _iconColor),
    );
  }

  // Button style
  ButtonStyle _btnStyle(BuildContext context) {
    final base = TextButton.styleFrom(
      elevation: 30,
      padding: const EdgeInsets.all(6),
      backgroundColor: _bgColor,
      fixedSize: Size(_dynamicWidth, _size),
      disabledBackgroundColor: kGrayColor,
      alignment: _shouldExpand ? Alignment.centerLeft : Alignment.center,
      animationDuration: kAnimateDuration,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    );
    return _cachedIsMobile
        ? base
        : base.copyWith(backgroundColor: _buildResolveWith(context));
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
        _buildHeader(context),
        if (shouldExpand) ...[
          const HorizontalDivider(divColor: kGrayBlueColor, thickness: 4),
          _buildListTile(
            context,
            title: 'SUB.: ${context.getSubscriptionName}',
            subtitle: 'Validity: ${workspace?.expiresOn.toStandardDT}',
          ),
          const HorizontalDivider(
            thickness: 0.4,
            space: 1,
            divColor: kGrayBlueColor,
          ),
          _buildListTile(
            context,
            title:
                "Multi-Location: ${workspace!.maxAllowedDevices > 1 ? 'On' : 'Off'}",
            subtitle: 'Max-Devices: ${workspace?.maxAllowedDevices}',
          ),
          const HorizontalDivider(
            thickness: 0.4,
            space: 1,
            divColor: kGrayBlueColor,
          ),
          _buildListTile(
            context,
            title: 'Hosting: ${workspace!.hostingType.getName}',
            subtitle: 'Store Branch: ${employee?.storeNumber}',
          ),
        ],
      ],
    );
  }

  ListTile _buildHeader(BuildContext context) {
    return ListTile(
      dense: true,
      minTileHeight: 20.0,
      horizontalTitleGap: 8.0,
      minVerticalPadding: 3.0,
      contentPadding: EdgeInsets.zero,
      mouseCursor: SystemMouseCursors.click,
      visualDensity: VisualDensity.compact,
      title: Text(
        workspace!.name.toUpperAll,
        style: context.textTheme.bodyMedium?.copyWith(
          color: kWhiteColor,
          fontWeight: FontWeight.w600,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      leading: workspace != null
          ? Icon(
              Icons.workspaces,
              color: iconColor,
              semanticLabel: workspace!.name,
            )
          : Image.asset(
              appLogoWithBG,
              scale: 24,
              alignment: Alignment.centerLeft,
              semanticLabel: workspace!.name,
            ),
      onTap: () => context.goNamed(RouteNames.switchStoresAccount),
    );
  }

  ListTile _buildListTile(
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
  }
}

/*// Build the logout button
  Widget _buildLogout(BuildContext context) {
    return TextButton.icon(
      style: _btnStyle(context).copyWith(
        backgroundColor: _shouldExpand
            ? WidgetStatePropertyAll(context.errorColor)
            : null,
      ),
      onPressed: () async {
        final isConfirmed = await context.confirmUserActionDialog(
          onAcceptLabel: 'Sign Out',
        );
        if (context.mounted && isConfirmed) {
          _handleSignOut(context);
        }
      },
      label: _shouldExpand
          ? Text(
              'SIGN OUT',
              style: context.textTheme.bodySmall?.copyWith(
                color: kWhiteColor,
                overflow: TextOverflow.ellipsis,
                fontWeight: FontWeight.w500,
              ),
            )
          : const SizedBox.shrink(),
      icon: Icon(Icons.logout, color: _iconColor),
    );
  }

  // Handle the sign-out process
  void _handleSignOut(BuildContext context) {
    final authBloc = BlocProvider.of<AuthBloc>(context);
    authBloc.add(AuthSignOutRequested());
  }*/
