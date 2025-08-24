import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/neumorphism.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:flutter/material.dart';

class CustomTab extends StatefulWidget {
  final List<Map<String, dynamic>> tabs;
  final TabController? controller;
  final double indicatorWeight;
  final List<Widget> children;
  final bool isScrollable;
  final bool hideIcon;
  final bool isColoredTab;
  final bool isVerticalTab;
  final bool showScrollUpButton;
  final int? length;
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
    this.isColoredTab = true,
    this.isScrollable = false,
    this.isVerticalTab = false,
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
  bool _isNavigationRailVisible = false; // State variable for toggle
  get _length => widget.length ?? widget.tabs.length;

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
      if (_tabController.indexIsChanging) {
        return; // Wait until change is complete
      }
      if (widget.onTapChanged != null) {
        widget.onTapChanged!(_tabController.index);
      }
    });
  }

  void _toggleNavigationRail() {
    setState(() {
      _isNavigationRailVisible = !_isNavigationRailVisible; // Toggle visibility
    });
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

    return DefaultTabController(
      length: _length,

      // isVerticalTab = true: create a vertical tabs (side)  else create horizontal tabs
      child: widget.isVerticalTab
          ? _buildVerticalTabs(context)
          : _buildHorizontalTabs(context),
    );
  }

  // Left side vertical tabs
  Row _buildVerticalTabs(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle button for NavigationRail visibility
            context.iconButton(
              _isNavigationRailVisible
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              iconColor: kPrimaryLightColor,
              tooltip:
                  '${_isNavigationRailVisible ? 'Expand' : 'Collapse'} Navigation',
              onPressed: _toggleNavigationRail,
            ),
            Expanded(child: _buildSideNavRail()),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        // This is the main content.
        Expanded(child: _buildTabBarView()),
      ],
    );
  }

  // NavigationRail for vertical tabs
  _buildSideNavRail() {
    return CustomScrollBar(
      controller: ScrollController(),
      showScrollUpButton: widget.showScrollUpButton,
      child: SizedBox(
        height: context.screenHeight * 0.9,
        width: _isNavigationRailVisible ? 50 : 100,
        child: NavigationRail(
          indicatorColor: kTransparentColor,
          selectedIndex: _tabController.index,
          onDestinationSelected: (index) {
            _tabController.animateTo(index);
            _handleTabTap(index);
          },
          labelType: NavigationRailLabelType.all,
          // Set the visual properties for the selected destination
          selectedLabelTextStyle: const TextStyle(
            color: kPrimaryLightColor,
            fontWeight: FontWeight.w500,
          ),
          destinations: widget.tabs.map<NavigationRailDestination>((t) {
            final icon = t['icon'];
            final label = t['label'].toString().toTitleCase;
            return NavigationRailDestination(
              icon: Tooltip(message: label, child: Icon(icon)),
              label: Text(
                _isNavigationRailVisible ? '' : label,
                textAlign: TextAlign.center,
              ),
              padding: EdgeInsets.symmetric(horizontal: 3),
              selectedIcon: Icon(icon, color: kPrimaryLightColor),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Top side horizontal tabs
  Widget _buildHorizontalTabs(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildColoredTabBar(context),
        // This is the main content.
        Expanded(child: _buildTabBarView()),
      ],
    );
  }

  /// This is the TabBarBar content
  Widget _buildColoredTabBar(BuildContext context) {
    return widget.isColoredTab
        ? ColoredBox(
            color: context.secondaryContainerColor,
            child: _buildTabBar(context),
          ).addNeumorphism()
        : _buildTabBar(context);
  }

  /// This is the main TabBarView content
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

  Align _loaderPlaceholder(int index) {
    return Align(
      key: ValueKey<int>(index),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.all(5.0), child: context.loader),
          Expanded(child: Text('${widget.tabs[index]['label']} is loading...')),
        ],
      ),
    );
  }

  TabBar _buildTabBar(BuildContext context) {
    return TabBar(
      indicatorWeight: widget.indicatorWeight,
      controller: _tabController,
      isScrollable: widget.isScrollable,
      indicatorSize: TabBarIndicatorSize.tab,
      padding: widget.padding ?? EdgeInsets.zero,
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      labelColor: kPrimaryLightColor,
      tabs: widget.tabs.map<Widget>((t) {
        final label = t['label'].toString().toTitleCase;
        final isActive = _tabController.index == widget.tabs.indexOf(t);
        return Tab(
          text: label,
          icon: widget.hideIcon
              ? null
              : Tooltip(
                  message: label,
                  child: Icon(
                    t['icon'],
                    color: isActive ? kPrimaryLightColor : null,
                  ),
                ),
          iconMargin: EdgeInsets.zero,
        );
      }).toList(),
      onTap: _handleTabTap,
    );
  }
}
