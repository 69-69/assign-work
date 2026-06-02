import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:flutter/material.dart';

class EntitlementTabView extends StatefulWidget {
  final bool isVerticalTab;
  final List<Widget> children;
  final List<CustomTabModel> tabs;
  final bool showNavigationButtons;
  final Widget? nextButton;
  final Widget? previousButton;
  final Future<bool> Function(int currentIndex)? onNext;
  final Future<bool> Function(int currentIndex)? onPrevious;

  /*final void Function(
    String moduleName, {
    required Set<RolePermission> permissions,
  })
  onSelectedFunc;*/

  const EntitlementTabView({
    super.key,
    required this.tabs,
    required this.children,
    this.isVerticalTab = false,
    this.showNavigationButtons = false,
    this.nextButton,
    this.previousButton,
    this.onNext,
    this.onPrevious,
  });

  @override
  State<EntitlementTabView> createState() => EntitlementTabViewState();
}

class EntitlementTabViewState extends State<EntitlementTabView>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  List<CustomTabModel> get _tabs => widget.tabs;

  Future<void> _goToNextTab() async {
    final allowed = await widget.onNext?.call(_tabController.index) ?? true;

    if (!allowed) return;

    if (_tabController.index < _tabs.length - 1) {
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  Future<void> _goToPreviousTab() async {
    final allowed = await widget.onPrevious?.call(_tabController.index) ?? true;

    if (!allowed) return;

    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  /*@override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }*/

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (widget.isVerticalTab) ...[
          _buildVerticalTabBar(context),
          const VerticalDivider(width: 1, thickness: 1),
        ],
        Expanded(
          child: Column(
            spacing: 10,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isVerticalTab) _buildHorizontalTabBar(context),

              Flexible(
                fit: FlexFit.loose,
                child: IndexedStack(
                  index: _tabController.index,
                  children: widget.children,
                ),
              ),

              if (widget.showNavigationButtons) _buildNavButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Row _buildNavButtons() {
    return Row(
      children: [
        widget.previousButton ??
            context.outlinedIconBtn(
              Icon(Icons.navigate_before, color: kTextColor),
              label: 'Previous',
              txtColor: kTextColor,
              borderColor: kGrayColor,
              onPressed: _tabController.index == 0 ? null : _goToPreviousTab,
            ),

        const Spacer(),

        widget.nextButton ??
            context.elevatedIconBtn(
              Icons.navigate_next,
              label: 'Next',
              onPressed: _tabController.index == _tabs.length - 1
                  ? null
                  : _goToNextTab,
              bgColor: kWhiteColor,
              iconAlignment: IconAlignment.end,
            ),
      ],
    );
  }

  Widget _buildHorizontalTabBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: context.textTheme.titleSmall,
        tabs: _tabs
            .map(
              (t) => Tab(
                text: t.label.toString(),
                icon: t.icon != null ? Icon(t.icon) : null,
              ),
            )
            .toList(),
        // onTap: (_) => setState(() {}), // Rebuild to update IndexedStack index
      ),
    );
    /*Tooltip(
      message: '${t.tooltip}'.toSentence,
      child: Tab(
        text: t.label.toString(),
        icon: t.icon != null ? Icon(t.icon) : null,
      ),
    ),*/
  }

  Widget _buildVerticalTabBar(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        height: context.screenHeight * 0.9,
        child: NavigationRail(
          selectedIndex: _tabController.index,
          /*onDestinationSelected: (index) {
            _tabController.animateTo(index);
            setState(() {}); // Rebuild to update IndexedStack index
          },*/
          onDestinationSelected: (index) {
            _tabController.animateTo(index);
          },
          labelType: NavigationRailLabelType.all,
          selectedLabelTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kPrimaryLightColor,
          ),
          destinations: _tabs
              .map(
                (t) => NavigationRailDestination(
                  icon: t.icon != null
                      ? Tooltip(
                          message: '${t.tooltip}'.toTitle,
                          child: Icon(t.icon),
                        )
                      : SizedBox.shrink(),
                  label: Text(t.label),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
