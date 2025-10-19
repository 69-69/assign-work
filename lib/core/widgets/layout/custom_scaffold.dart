import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/check_for_app_update.dart';
import 'package:assign_erp/core/widgets/nav/bread_crumbs.dart';
import 'package:assign_erp/core/widgets/nav/breadcrumb_service.dart';
import 'package:assign_erp/core/widgets/nav/notification_dropdown.dart';
import 'package:assign_erp/core/widgets/nav/profile_menu_dropdown.dart';
import 'package:assign_erp/core/widgets/search/spotlight_search_bar.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomScaffold extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final bool noAppBar;
  final Widget body;
  final Widget? drawer;
  final Color? bgColor;
  final dynamic title;
  final String? subTitle;
  final bool isGradientBg;
  final Widget? backButton;
  final List<Widget>? actions;
  final List<DashboardTile> tiles;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionBtnLocation;

  const CustomScaffold({
    super.key,
    required this.body,
    this.tiles = const [],
    this.title,
    this.subTitle,
    this.actions,
    this.bgColor,
    this.drawer,
    this.backButton,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionBtnLocation,
    this.noAppBar = false,
    this.isGradientBg = false,
  });

  @override
  State<CustomScaffold> createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold> {
  bool _isSearchActive = false;
  final GlobalKey<SpotlightSearchBarState> _searchBarKey =
      GlobalKey<SpotlightSearchBarState>();

  Color get _bgColor =>
      widget.bgColor ??
      (widget.isGradientBg ? kLightBlueColor : context.scaffoldBgColor);

  void _onSearchChanged(bool active) {
    setState(() => _isSearchActive = active);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: _isSearchActive ? _buildBodyWithSearchOverlay() : _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButtonLocation: widget.floatingActionBtnLocation,
      floatingActionButton: widget.floatingActionButton,
      drawer: widget.drawer,
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (widget.noAppBar) return null;

    final authState = context.watch<AuthBloc>().state;

    return _AppBar(
      authState: authState,
      title: widget.title,
      showSearchBar: widget.tiles.isNotEmpty,
      appBar: widget.appBar,
      subTitle: widget.subTitle,
      actions: widget.actions,
      drawer: widget.drawer,
      backButton: widget.backButton,
      onPressed: () {
        if (!_isSearchActive) {
          _onSearchChanged(true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _searchBarKey.currentState?.openSearchBar();
          });
        }
      },
    );
  }

  Widget _buildBodyWithSearchOverlay() {
    return Stack(
      children: [
        _buildBody(),
        if (_isSearchActive) ...{
          ModalBarrier(color: kPrimaryColor.toAlpha(0.4), dismissible: false),
        },
        Align(
          alignment: Alignment.center,
          child: SpotlightSearchBar(
            key: _searchBarKey,
            tiles: widget.tiles,
            onSearchActiveChanged: _onSearchChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final uiBody = SafeArea(child: widget.body);

    return widget.isGradientBg
        ? Container(decoration: _linearGradientBg(), child: uiBody)
        : uiBody;
  }

  Widget _buildBottomNavigationBar() {
    return widget.bottomNavigationBar ??
        Row(
          children: const [
            Expanded(child: BuildBreadcrumbs()),
            CheckForAppUpdate(),
          ],
        );
  }

  BoxDecoration _linearGradientBg() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [kPrimaryColor, kLightBlueColor, kLightBlueColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final AuthState authState;
  final dynamic title;
  final String? subTitle;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? backButton;
  final Function()? onPressed;
  final PreferredSizeWidget? appBar;
  final bool showSearchBar;

  const _AppBar({
    required this.authState,
    this.title,
    this.subTitle,
    this.actions,
    this.drawer,
    this.backButton,
    this.onPressed,
    this.appBar,
    this.showSearchBar = false,
  });

  bool _isMobile(BuildContext context) => context.isMobile;

  @override
  Widget build(BuildContext context) {
    return appBar ?? _buildAppBar(context);
  }

  AppBar _buildAppBar(BuildContext context) {
    bool canGoBack = Navigator.of(context).canPop();

    return AppBar(
      leading: canGoBack ? _buildLeading(context) : null,
      leadingWidth: _isMobile(context) ? null : 100,
      automaticallyImplyLeading: canGoBack,
      toolbarHeight: kAppBarHeight,
      centerTitle: true,
      elevation: 20,
      scrolledUnderElevation: 20,
      title: title is Widget ? title : _Title(title: title, subTitle: subTitle),
      actions: _buildActions(),
    );
  }

  List<Widget> _buildActions() {
    return actions ??
        [
          if (showSearchBar) ...[
            _iconButton(
              'Workspace search',
              icon: Icons.search,
              onPressed: onPressed,
            ),
            SizedBox(width: 10),
          ],
          NotificationsDropdown(
            workspace: authState.workspace,
            employee: authState.employee,
          ),
          ProfileMenuDropdown(
            workspace: authState.workspace,
            employee: authState.employee,
          ),
        ];
  }

  IconButton _iconButton(
    String tooltip, {
    required IconData icon,
    void Function()? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: kLightBlueColor),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(kGrayBlueColor.toAlpha(0.2)),
        side: WidgetStateProperty.resolveWith<BorderSide?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.hovered)) {
            return BorderSide(color: kGrayBlueColor, width: 2);
          }
          return null;
        }),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (drawer != null) return null;
    if (backButton != null) return backButton;
    final routePath = BreadcrumbService.currentPath(context);
    final backTitle = routePath.isEmpty
        ? 'Back'
        : BreadcrumbService.generateBreadcrumbs(
            routePath,
            optFallback: 'Back',
          ).last.label;

    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.fromLTRB(10, 20, 0, 20),
      child: _isMobile(context)
          ? BackButton(color: kWhiteColor)
          : InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(15),
              hoverColor: kWhiteColor.toAlpha(0.1),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Tooltip(
                  message: backTitle.toTitle,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.adaptive.arrow_back,
                        color: kWhiteColor,
                        size: 16,
                      ),
                      Expanded(
                        child: Text(
                          backTitle.toTitle,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            color: kWhiteColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ), // const BackButton(color: kWhiteColor),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kAppBarHeight);
}

class _Title extends StatelessWidget {
  final String? title;
  final String? subTitle;

  const _Title({this.title, this.subTitle});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: (subTitle ?? appSubName).toUpperAll,
      child: _buildTitle(context),
    );
  }

  ListTile _buildTitle(BuildContext context) {
    return ListTile(
      dense: true,
      titleAlignment: ListTileTitleAlignment.center,
      title: Text(
        (title ?? appName).toUpperAll,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: const TextStyle(
          color: kLightBlueColor,
          fontWeight: FontWeight.bold,
          overflow: TextOverflow.fade,
        ),
        textScaler: TextScaler.linear(context.textScaleFactor),
      ),
      subtitle: Text(
        (subTitle ?? appSubName).toUpperAll,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: context.textTheme.titleMedium?.copyWith(
          fontSize: 10,
          color: kLightBlueColor,
          overflow: TextOverflow.fade,
        ),
        // textScaler: TextScaler.linear(context.textScaleFactor),
      ),
    );
  }
}

/*class _CustomScaffoldState extends State<CustomScaffold> {
  bool _isSearchActive = false;

  Color get _bgColor =>
      widget.bgColor ??
      (widget.isGradientBg
          ? kLightBlueColor
          : context.scaffoldBackgroundColor);

  void _triggerSearchBar() {
    setState(() => _isSearchActive = !_isSearchActive);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _bgColor,
      appBar: widget.noAppBar
          ? null
          : _AppBar(
              authState: authState,
              title: widget.title,
              appBar: widget.appBar,
              subTitle: widget.subTitle,
              actions: widget.actions,
              drawer: widget.drawer,
              backButton: widget.backButton,
              onPressed: _triggerSearchBar,
            ),
      body: _isSearchActive
          ? Stack(
              children: [
                _buildBody(),
                Align(
                  alignment: Alignment.center,
                  child: SpotlightSearchBar(
                    tiles: widget.tiles,
                    showSearchBar: _isSearchActive,
                  ),
                ),
              ],
            )
          : _buildBody(),
      bottomNavigationBar:
          widget.bottomNavigationBar ??
          Row(
            children: [
              Expanded(child: BuildBreadcrumbs()),
              CheckForAppUpdate(),
            ],
          ),
      floatingActionButtonLocation: widget.floatingActionBtnLocation,
      floatingActionButton: widget.floatingActionButton,
      drawer: widget.drawer,
    );
  }

  Widget _buildBody() {
    final uiBody = SafeArea(child: widget.body);

    return widget.isGradientBg
        ? Container(decoration: _linearGradientBg(), child: uiBody)
        : uiBody;
  }

  BoxDecoration _linearGradientBg() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          kPrimaryColor,
          kLightBlueColor,
          kLightBlueColor,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }
}*/

/*Drawer _drawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.workspace?.clientName ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Text(
                      context.workspace?.role.name ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }*/
