import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/neumorphism.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:flutter/material.dart';

class CustomTab extends StatefulWidget {
  /// [tabs] TabBarView tabs/navigation bar
  final List<CustomTabModel> tabs;
  final TabController? controller;
  final double indicatorWeight;

  /// [children] TabBarView contents
  final List<Widget> children;
  final bool isScrollable;
  final double? contentHeight;
  final bool useDynamicHeight;
  final Color? bgColor;
  final bool isVertical;
  final bool hideIcon;
  final int? length;
  final bool showScrollUpButton;
  final Function(int)? onTapChanged;
  final EdgeInsetsGeometry? padding;

  /// [openThisTab] Open the exact TabView, if provided, else defaulted to '0'
  final int openThisTab;

  const CustomTab({
    super.key,
    this.controller,
    required this.tabs,
    this.length,
    required this.children,
    this.hideIcon = true,
    this.useDynamicHeight = false,
    this.contentHeight,
    this.bgColor,
    this.isScrollable = false,
    this.isVertical = false,
    this.openThisTab = 0,
    this.indicatorWeight = 1.0,
    this.onTapChanged,
    this.padding,
    this.showScrollUpButton = false,
  });

  @override
  State<CustomTab> createState() => _CustomTabState();
}

class _CustomTabState extends State<CustomTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // late List<bool> _loadedTabs;
  Set<int> loadedTabs = {};
  bool _isNavRailExpanded = true; // State variable for toggle
  List<CustomTabModel> get _tabsList => widget.tabs;

  get _length => widget.length ?? _tabsList.length;

  @override
  void initState() {
    super.initState();
    _tabController =
        widget.controller ??
        TabController(
          vsync: this,
          length: _length,
          initialIndex: widget.openThisTab,
        );

    // Ensure the initial tab content is loaded
    loadedTabs.add(widget.openThisTab);
    // Initialize loaded state for tabs
    // _loadedTabs = List<bool>.generate(_length, (index) => false);

    // Listen to tab changes
    _listenToTabChanges();
  }

  void _listenToTabChanges() {
    _tabController.addListener(() {
      // Wait for the transition to complete (for swipes)
      if (_tabController.indexIsChanging) return;

      final index = _tabController.index;

      // This handles tab swipe (not just tap)
      if (!loadedTabs.contains(index)) {
        setState(() {
          loadedTabs.clear(); // Optional: clear previous tab's state
          loadedTabs.add(index);
        });
      }

      if (widget.onTapChanged != null) {
        widget.onTapChanged!(index);
      }
    });
  }

  /*void _listenToTabChanges2() {
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return; // Wait until change is complete
      }
      if (widget.onTapChanged != null) {
        widget.onTapChanged!(_tabController.index);
      }
    });
  }*/

  void _toggleNavigationRail() {
    // Toggle visibility
    setState(() => _isNavRailExpanded = !_isNavRailExpanded);
  }

  void _handleTabTap(int index) {
    if (!loadedTabs.contains(index)) {
      setState(() {
        // Only add the new tab index to loadedTabs, clearing previous indices
        loadedTabs.clear();
        loadedTabs.add(index);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the current tab is always loaded
    // loadedTabs.add(_tabController.index.clamp(0, _length - 1).toInt());
    final isExpanded = context.isMobile ? false : _isNavRailExpanded;
    final isScrollable = widget.isScrollable;
    final bgColor = widget.bgColor;

    return DefaultTabController(
      length: _length,

      // isVerticalTab = true: create a vertical tabs (side)  else create horizontal tabs
      child: widget.isVertical
          ? _VerticalTabBars(
              tabs: _tabsList,
              bgColor: bgColor,
              isScrollable: isScrollable,
              showScrollUpButton: widget.showScrollUpButton,
              isNavRailExpanded: isExpanded,
              onDestinationSelected: (i) {
                _tabController.animateTo(i);
                _handleTabTap(i);
              },
              selectedIndex: _tabController.index,
              content: _buildTabBarView(),
              toggleNavRail: _toggleNavigationRail,
            )
          : _HorizontalTabBars(
              tabs: _tabsList,
              bgColor: bgColor,
              contentHeight: widget.contentHeight,
              useDynamicHeight: widget.useDynamicHeight,
              indicatorWeight: widget.indicatorWeight,
              tabController: _tabController,
              hideIcon: widget.hideIcon,
              padding: widget.padding,
              isScrollable: isScrollable,
              content: _buildTabBarView(),
              handleTabTap: _handleTabTap,
            ),
    );
  }

  /// This is the TabBarView content
  TabBarView _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(
        _length,
        (index) => loadedTabs.contains(index)
            ? widget.children[index]
            : _loaderPlaceholder(index),
      ),
    );
  }

  _loaderPlaceholder(int index) {
    return Container(
      key: ValueKey<int>(index),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              runAlignment: WrapAlignment.center,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                context.loader,
                Text(
                  textAlign: TextAlign.center,
                  'Loading ${_tabsList[index].label.toTitle}...',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalTabBars extends StatelessWidget {
  final TabController tabController;

  final List<CustomTabModel> tabs;
  final Color? bgColor;
  final double? contentHeight;
  final double indicatorWeight;
  final bool hideIcon;
  final bool useDynamicHeight;
  final EdgeInsetsGeometry? padding;
  final bool isScrollable;
  final Widget content;
  final Function(int)? handleTabTap;

  const _HorizontalTabBars({
    required this.tabs,
    this.bgColor,
    this.contentHeight,
    required this.indicatorWeight,
    required this.tabController,
    required this.hideIcon,
    this.useDynamicHeight = false,
    required this.padding,
    required this.isScrollable,
    required this.content,
    required this.handleTabTap,
  });

  @override
  Widget build(BuildContext context) {
    return _buildHorizontalTabs(context);
  }

  // Tab alignment only works when scrollable is true
  TabAlignment? get _tabAlignment => isScrollable ? TabAlignment.start : null;

  /// Top/horizontal tabs [_buildHorizontalTabs]
  Widget _buildHorizontalTabs(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ColoredBox(
            color: bgColor ?? context.outlineColor.toAlpha(0.1),
            // context.secondaryContainerColor
            child: _buildTabBar(context),
          ),
          SizedBox(
            height: contentHeight ?? context.screenHeight,
            child: content,
          ),
        ],
      ),
    );
  }

  /*Widget _buildHorizontalTabs2(BuildContext context) {
    // I refactor to use ListView instead of Column
    return ListView(
      shrinkWrap: true,
      primary: true,
      children: [
        ColoredBox(
          color: bgColor ?? context.secondaryContainerColor,
          child: _buildTabBar(context),
        ),
        // This is the main content.
        SizedBox(height: context.screenHeight, child: content),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ColoredBox(
          color: bgColor ?? context.secondaryContainerColor,
          child: _buildTabBar(context),
        ).addNeumorphism(),
        // This is the main content.
        // Flexible(fit: FlexFit.loose, child: content),
        Expanded(child: content!),
      ],
    );
  }*/

  /// This the TabBars
  TabBar _buildTabBar(BuildContext context) {
    return TabBar(
      indicatorWeight: indicatorWeight,
      controller: tabController,
      isScrollable: isScrollable,
      tabAlignment: _tabAlignment,
      indicatorSize: TabBarIndicatorSize.tab,
      padding: padding ?? EdgeInsets.zero,
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      // labelColor: kPrimaryLightColor,
      tabs: tabs.map<Widget>((t) {
        final label = t.label.toTitle;
        final isActive = tabController.index == tabs.indexOf(t);
        return Tab(
          text: label,
          icon: hideIcon || t.icon == null
              ? null
              : Tooltip(
                  message: t.tooltip?.toTitle ?? label,
                  child: Icon(
                    t.icon,
                    color: isActive ? kPrimaryLightColor : null,
                  ),
                ),
          iconMargin: EdgeInsets.zero,
        );
      }).toList(),
      onTap: handleTabTap,
    );
  }
}

class _VerticalTabBars extends StatelessWidget {
  final Widget content;
  final Color? bgColor;
  final bool isScrollable;
  final int? selectedIndex;
  final bool isNavRailExpanded; // State variable for toggle
  final bool showScrollUpButton;
  final Function()? toggleNavRail;

  // final List<Map<String, dynamic>> tabs;
  final List<CustomTabModel> tabs;
  final void Function(int)? onDestinationSelected;

  const _VerticalTabBars({
    this.bgColor,
    this.selectedIndex,
    this.toggleNavRail,
    required this.tabs,
    required this.content,
    required this.isScrollable,
    this.onDestinationSelected,
    required this.isNavRailExpanded,
    required this.showScrollUpButton,
  });

  @override
  Widget build(BuildContext context) {
    return _buildVerticalTabs(context);
  }

  // Left side vertical tabs
  Row _buildVerticalTabs(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bgColor != null
            ? ColoredBox(
                color: bgColor!,
                child: _buildColumn(context),
              ).addNeumorphism()
            : _buildColumn(context),
        const VerticalDivider(thickness: 1, width: 1),
        // This is the main content.
        Expanded(child: content),
      ],
    );
  }

  Column _buildColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle button for NavigationRail visibility
        IconButton(
          icon: Icon(isNavRailExpanded ? Icons.menu_open : Icons.menu),
          tooltip: '${isNavRailExpanded ? 'Close' : 'Open'} Sidebar',
          onPressed: toggleNavRail,
        ),
        Expanded(child: _buildSideNavRail(context)),
      ],
    );
  }

  // NavigationRail for vertical tabs
  _buildSideNavRail(BuildContext context) {
    return CustomScrollBar(
      controller: ScrollController(),
      showScrollUpButton: showScrollUpButton,
      child: SizedBox(
        height: context.screenHeight,
        width: isNavRailExpanded ? 100 : 50,
        child: _navigationRail(context),
      ),
    );
  }

  NavigationRail _navigationRail(BuildContext context) {
    return NavigationRail(
      backgroundColor: bgColor,
      indicatorColor: kTransparentColor,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      // Set the visual properties for the selected destination
      selectedLabelTextStyle: const TextStyle(
        color: kPrimaryLightColor,
        fontWeight: FontWeight.w500,
      ),
      destinations: tabs.map<NavigationRailDestination>((t) {
        final icon = t.icon;
        final label = t.label.toTitle;
        return NavigationRailDestination(
          icon: icon != null
              ? Tooltip(message: t.tooltip?.toTitle ?? label, child: Icon(icon))
              : SizedBox.shrink(),
          label: Text(
            isNavRailExpanded ? label : '',
            textAlign: TextAlign.center,
          ),
          padding: EdgeInsets.symmetric(horizontal: 3),
          selectedIcon: icon != null
              ? Icon(icon, color: kPrimaryLightColor)
              : SizedBox.shrink(),
        );
      }).toList(),
    );
  }
}
