import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dashboard_metrics.dart';
import 'package:assign_erp/core/widgets/delayed_tooltip.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/nav/side_nav.dart';
import 'package:assign_erp/features/access_control/presentation/cubit/access_control_cubit.dart';
import 'package:assign_erp/features/auth/data/role/workspace_role.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/home/data/permission/main_permission.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Map<String, bool> _sharedToggleState = {'visible': true};

class DashboardTileCard extends StatefulWidget {
  final Color? bgColor;
  final String metricsTitle;
  final String metricsSubtitle;
  final void Function()? onTap;
  final List<DashboardTile> tiles;
  final Map<String, int>? metrics;

  /*USAGE:
  canAccess: (perm) {
    return context.isLicensed(perm) || context.hasPermission(perm);
  },*/
  final bool Function(String)? canAccess;

  const DashboardTileCard({
    super.key,
    this.onTap,
    this.bgColor,
    this.metrics,
    this.canAccess,
    required this.tiles,
    this.metricsTitle = '',
    this.metricsSubtitle = '',
  });

  @override
  State<DashboardTileCard> createState() => _DashboardTileCardState();
}

class _DashboardTileCardState extends State<DashboardTileCard> {
  // late List<DashboardTile> _visibleTiles;
  late double maxCrossAxisExtent;
  bool get isMetricsVisible => _sharedToggleState['visible'] ?? true;

  void _toggleMetricsVisibility() {
    setState(() => _sharedToggleState.update('visible', (val) => !val));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /*final ps = context.read<PermissionService>();

    _visibleTiles = widget.tiles.where((tile) {
      if (tile.requiredPermission == null) return true;
      return ps.has(tile.requiredPermission);
    }).toList();*/

    _updateMaxCrossAxisExtent();
  }

  void _updateMaxCrossAxisExtent() {
    // context.isMobile ? screenW :
    var screenW = context.screenWidth;
    maxCrossAxisExtent = (context.isMiniMobile
        ? screenW
        : (context.isPortraitMode ? screenW / 2 : screenW / 3));
  }

  void _handleHover(bool isHovering) =>
      isHovering ? TooltipController.enable() : TooltipController.disable();
  void _handleTapDown(TapDownDetails _) => TooltipController.enable();
  void _handleTapUp(TapUpDetails _) => TooltipController.disable();
  void _handleFocusChange(bool hasFocus) =>
      hasFocus ? TooltipController.enable() : TooltipController.disable();

  bool _canAccess(String access, BuildContext cxt) {
    final can =
        isUnknownPermission(access) ||
        cxt.isLicensed(access) ||
        cxt.hasPermission(access);
    return can;
  }

  @override
  Widget build(BuildContext context) {
    double pad = 20;

    return widget.tiles.length > 1
        ? _buildBody(context, pad)
        : Center(
            child: ConstrainedBox(
              // Center the card in the screen
              constraints: BoxConstraints(
                maxWidth: maxCrossAxisExtent,
                maxHeight: maxCrossAxisExtent,
              ),
              child: _buildGridView(context, pad),
            ),
          );
  }

  Row _buildBody(BuildContext context, double pad) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SideNav(tiles: widget.tiles),
        Expanded(
          child: widget.metrics != null
              ? Column(
                  children: [
                    _buildMetricCard(context),

                    // create full-width card for summary of the inventory in the dash
                    const SizedBox(height: 6.0),
                    Expanded(child: _buildGridView(context, pad)),
                  ],
                )
              : _buildGridView(context, pad),
        ),
      ],
    );
  }

  /// Metrics Card for showing metrics
  AnimatedSwitcher _buildMetricCard(BuildContext context) {
    return AnimatedSwitcher(
      duration: kAnimateDuration,
      child: isMetricsVisible
          ? DashboardMetrics(
              title: widget.metricsTitle,
              subtitle: widget.metricsSubtitle,
              metrics: widget.metrics!,
              onPressed: _toggleMetricsVisibility,
            )
          : _buildShowMetricsButton(context),
    );
  }

  /// Show Metrics Button
  Container _buildShowMetricsButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      alignment: Alignment.centerRight,
      child: context.elevatedIconBtn(
        Icon(Icons.analytics_outlined, color: kWhiteColor),
        label: Text(
          'Show Metrics',
          style: context.textTheme.bodyMedium?.copyWith(color: kWhiteColor),
        ),
        onPressed: _toggleMetricsVisibility,
        style: ElevatedButton.styleFrom(
          backgroundColor: kBrightPrimaryColor.toAlpha(0.6),
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
        ),
      ),
    );
  }

  /// GridView Builder for tiles
  GridView _buildGridView(BuildContext context, double pad) {
    // List<DashboardTile> tiles = List.from(widget.tiles)..removeAt(0);

    return GridView.builder(
      primary: false,
      itemCount: widget.tiles.length,
      padding: EdgeInsets.fromLTRB(0, 10, pad, pad),
      physics: const RangeMaintainingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        // mainAxisExtent: maxCrossAxisExtent,
        // Spacing between rows
        mainAxisSpacing: 20,
        // Spacing between columns
        crossAxisSpacing: 20,
        // Ratio between the width and height of grid items
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final tile = widget.tiles[index];

        return _builder(context, tile, index: index);
      },
    );
  }

  _builder(BuildContext context, DashboardTile tile, {int index = 0}) {
    final canAccess = widget.canAccess != null
        ? widget.canAccess!(tile.access)
        : _canAccess(tile.access, context);

    final viewCard = tile.label.contains('logo')
        ? _buildLogoCard(context, tile)
        : _buildIconCard(tile, context);

    return _buildCard(
      context,
      tile: tile,
      index: index,
      viewCard: viewCard,
      canAccess: canAccess,
    );
  }

  Widget _buildCard(
    BuildContext context, {
    int index = 0,
    required DashboardTile tile,
    required bool canAccess,
    required Widget viewCard,
  }) {
    return InkWell(
      mouseCursor: canAccess
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onHover: _handleHover,
      onTapDown: _handleTapDown,
      onFocusChange: _handleFocusChange,
      onTapUp: _handleTapUp,
      onTap: _buildOnTapHandler(context, tile, canAccess),
      child: _buildCardContainer(context, index, tile, canAccess, viewCard),
    );
  }

  GestureTapCallback? _buildOnTapHandler(
    BuildContext context,
    DashboardTile tile,
    bool canAccess,
  ) {
    if (!canAccess) return null;

    return widget.onTap ??
        () async {
          final shouldStop = await checkLiveChatSupportAccess(
            context,
            tile.action,
          );
          if (shouldStop) return;

          if (!context.mounted) return;

          if (tile.param.entries.isEmpty) {
            context.goNamed(tile.action);
          } else {
            context.goNamed(
              tile.action,
              extra: tile.param,
              pathParameters: tile.param,
            );
          }
        };
  }

  Widget _buildCardContainer(
    BuildContext context,
    int index,
    DashboardTile tile,
    bool canAccess,
    Widget viewCard,
  ) {
    final ranColor = randomBgColors[index];

    return AnimatedContainer(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20.0),
      duration: kAnimateDuration,
      decoration: BoxDecoration(
        color: canAccess ? (widget.bgColor ?? ranColor) : ranColor.toAlpha(0.2),
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: canAccess ? null : Border.all(color: ranColor, width: 4),
      ),
      child: DelayedTooltip(
        message: _buildTooltipMessage(tile, canAccess),
        bgColor: canAccess ? null : kDangerColor,
        child: context.isMiniMobile
            ? viewCard
            : _buildGridTile(tile, context, viewCard),
      ),
    );
  }

  String _buildTooltipMessage(DashboardTile tile, bool canAccess) {
    return (canAccess
            ? (tile.description ?? '')
            : "You don't have permission to use this feature")
        .toSentence;
  }

  GridTile _buildGridTile(DashboardTile tile, BuildContext context, viewCard) {
    return GridTile(
      header: Text(
        tile.label.toUpperAll,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: kWhiteColor),
        textScaler: TextScaler.linear(context.textScaleFactor),
      ),
      footer: context.isMobile
          ? null
          : Text(
              (tile.description ?? '').toSentence,
              textAlign: TextAlign.start,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kWhiteColor),
            ),
      child: viewCard,
    );
  }

  _buildIconCard(DashboardTile tile, BuildContext context) {
    final parts = tile.label.split(' - ');
    final title = parts.first;
    final subTitle = parts.length > 1 ? parts[1] : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: null,
            icon: Expanded(
              child: Icon(
                tile.icon,
                color: kLightBlueColor,
                size: context.screenWidth * 0.1,
                semanticLabel: title,
              ),
            ),
            label: context.isMobile
                ? const SizedBox.shrink()
                : _buildListTile(title, context, subTitle),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              alignment: Alignment.center,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> checkLiveChatSupportAccess(
    BuildContext context,
    String route,
  ) async {
    final role = context.workspace?.role;

    if (route == RouteNames.liveChatSupport && role != WorkspaceRole.tenant) {
      await context.confirmAction<bool>(
        Text('Please use Agent Support/Chat for assistance.'),
        title: "Live Chat Support",
        onAcceptLabel: "Ok",
        onRejectLabel: "Cancel",
      );
      return true; // prompt was shown; further action should stop
    }

    return false; // no prompt; proceed normally
  }

  ListTile _buildListTile(String title, BuildContext context, String subTitle) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title.toUpperAll,
        textAlign: TextAlign.center,
        style: context.textTheme.titleMedium?.copyWith(
          color: kLightBlueColor,
          overflow: TextOverflow.ellipsis,
          fontWeight: FontWeight.bold,
        ),
        textScaler: TextScaler.linear(context.textScaleFactor),
      ),
      subtitleTextStyle: context.textTheme.titleSmall?.copyWith(
        overflow: TextOverflow.ellipsis,
        color: kLightBlueColor,
      ),
      subtitle: subTitle.isEmpty
          ? null
          : Text(
              subTitle.toUpperAll,
              textAlign: TextAlign.center,
              textScaler: TextScaler.linear(context.textScaleFactor),
            ),
    );
  }

  _buildLogoCard(BuildContext context, DashboardTile tile) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Image.asset(
          appLogo,
          fit: BoxFit.contain,
          width: maxCrossAxisExtent * 0.3,
        ),
        if (!context.isMobile) ...[
          const SizedBox(width: 10),
          Text(
            tile.label.toUpperAll,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(color: kWhiteColor),
            textScaler: TextScaler.linear(context.textScaleFactor),
          ),
        ],
      ],
    );
  }
}
