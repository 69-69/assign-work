import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/access_control/presentation/cubit/access_control_cubit.dart';
import 'package:assign_erp/features/home/data/permission/main_permission.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SpotlightSearchBar extends StatefulWidget {
  final List<DashboardTile> tiles;
  final void Function(bool isActive)? onSearchActiveChanged;

  const SpotlightSearchBar({
    super.key,
    this.tiles = const [],
    this.onSearchActiveChanged,
  });

  @override
  State<SpotlightSearchBar> createState() => SpotlightSearchBarState();
}

class SpotlightSearchBarState extends State<SpotlightSearchBar> {
  bool _isGridView = false;
  bool _isSearchActive = false;
  late double maxCrossAxisExtent;
  List<DashboardTile> filteredTiles = [];
  final TextEditingController _controller = TextEditingController();

  /// Public method to open the search bar from outside
  void openSearchBar() {
    setState(() => _isSearchActive = true);
    widget.onSearchActiveChanged?.call(true);
  }

  void _triggerSearchBar() {
    setState(() {
      _isSearchActive = false;
      _controller.clear();
      filteredTiles = [];
    });
    widget.onSearchActiveChanged?.call(false);
  }

  // The search logic to filter tiles
  void _onSearchChanged(String query) {
    setState(() {
      filteredTiles = widget.tiles.where((tile) {
        // Filter tiles by matching the query with either label or description
        final label = tile.label.toLowerAll;
        final desc = (tile.description ?? '').toLowerAll;
        final searchQuery = query.toLowerAll;
        return label.contains(searchQuery) || desc.contains(searchQuery);
      }).toList();
    });
  }

  bool _canAccess(String access, BuildContext cxt) {
    final can =
        isUnknownPermission(access) ||
        cxt.readIsLicensed(access) ||
        cxt.readHasPermission(access);
    return can;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMaxCrossAxisExtent();
  }

  void _updateMaxCrossAxisExtent() {
    var screenW = context.screenWidth;
    maxCrossAxisExtent = (context.isMiniMobile
        ? screenW
        : (context.isPortraitMode ? screenW / 2 : screenW / 6));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sWidth = context.screenWidth * (context.isMobile ? 0.94 : 0.7);

    // Measure available height to determine rows per view
    final maxVisible = context.getMaxVisibleHeight(
      rowHeight: 130.0,
      itemCount: filteredTiles.length + 1,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: sWidth,
        height: maxVisible,
        child: _buildBody(context),
      ),
    );
  }

  _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isSearchActive) ...[
          _buildSearchBar(context),
          (filteredTiles.isNotEmpty)
              ? Expanded(
                  child: _isGridView
                      ? _GridViewResults(
                          filteredTiles: filteredTiles,
                          query: _controller.text,
                          canAccess: _canAccess,
                          triggerSearchBar: _triggerSearchBar,
                          maxCrossAxisExtent: maxCrossAxisExtent,
                        )
                      : _ListViewResults(
                          filteredTiles: filteredTiles,
                          query: _controller.text,
                          canAccess: _canAccess,
                          triggerSearchBar: _triggerSearchBar,
                        ),
                )
              : Card(
                  color: kLightBlueColor.toAlpha(0.8),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Center(
                      child: Text(
                        _controller.text.isEmpty
                            ? "Enter to search"
                            : "No results found",
                        style: TextStyle(color: kBgLightColor),
                      ),
                    ),
                  ),
                ),
        ],
      ],
    );
  }

  Widget _buildSearchBar(BuildContext cxt) {
    return Material(
      color: kTransparentColor,
      child: AnimatedContainer(
        height: 50,
        duration: kAnimateDuration,
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: kLightBlueColor.toAlpha(0.8), // kLightBlueColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: _buildSearchField(),
      ),
    );
  }

  Row _buildSearchField() {
    final border = OutlineInputBorder(
      borderSide: BorderSide(width: 0, color: kTransparentColor),
    );
    final isEmpty2 = _controller.text.isEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: CustomTextField(
            controller: _controller,
            autofocus: true,
            textColor: kBgLightColor,
            inputDecoration: InputDecoration(
              isDense: true,
              hintText: "Workspace Search...",
              hintStyle: TextStyle(color: kBgLightColor),
              border: InputBorder.none,
              focusedBorder: border,
              enabledBorder: border,
              prefixIcon: Icon(Icons.search, color: kPrimaryColor),
              suffixIcon: _switchDisplay(isEmpty2),
            ),
            keyboardType: TextInputType.none,
            onChanged: _onSearchChanged,
          ),
        ),
      ],
    );
  }

  Wrap _switchDisplay(bool isEmpty2) {
    return Wrap(
      runSpacing: 10,
      children: [
        IconButton(
          icon: Icon(
            _isGridView ? Icons.grid_view : Icons.view_list,
            color: kPrimaryAccentColor,
          ),
          tooltip: "Switch to ${_isGridView ? "List" : "Grid"} view",
          onPressed: () {
            setState(() => _isGridView = !_isGridView);
          },
        ),
        IconButton(
          icon: const Icon(Icons.clear, color: kTextColor),
          tooltip: "${isEmpty2 ? "Close" : "Clear"} search",
          onPressed: () {
            if (isEmpty2) {
              _triggerSearchBar(); // Close the search bar if there's no text
            } else {
              setState(() => _controller.clear());
            }
          },
        ),
      ],
    );
  }
}

/// [_GridViewResults] GridView Builder for tiles
class _GridViewResults extends StatelessWidget {
  final String query;
  final double maxCrossAxisExtent;
  final void Function() triggerSearchBar;
  final List<DashboardTile> filteredTiles;
  final bool Function(String access, BuildContext cxt) canAccess;

  const _GridViewResults({
    required this.query,
    required this.canAccess,
    required this.filteredTiles,
    required this.triggerSearchBar,
    required this.maxCrossAxisExtent,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      primary: false,
      itemCount: filteredTiles.length,
      padding: const EdgeInsets.all(4.0),
      physics: const RangeMaintainingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        // mainAxisExtent: maxCrossAxisExtent,
        // Spacing between rows
        mainAxisSpacing: 6,
        // Spacing between columns
        crossAxisSpacing: 6,
        // Ratio between the width and height of grid items
        childAspectRatio: 1,
      ),
      itemBuilder: (cxt, index) => _itemBuilder(cxt, index),
    );
  }

  Widget _itemBuilder(BuildContext cxt, int index) {
    final tile = filteredTiles[index];

    return InkWell(
      onTap: () {
        final hasPerm = canAccess(tile.access, cxt);
        if (!hasPerm) {
          cxt.showAlertOverlay(
            "You don't have permission to use this feature",
            bgColor: kWarningColor,
            label: "OK",
          );
          return;
        }
        if (tile.param.entries.isEmpty) {
          cxt.goNamed(tile.route);
        } else {
          cxt.goNamed(
            tile.route,
            extra: tile.param,
            pathParameters: tile.param,
          );
        }
        triggerSearchBar();
      },
      child: _buildGridCard(index, tile, cxt),
    );
  }

  Widget _buildGridCard(int index, DashboardTile tile, BuildContext context) {
    final ranColor = randomBgColors[index]; // kLightBlueColor

    return AnimatedContainer(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20.0),
      duration: kAnimateDuration,
      decoration: BoxDecoration(
        color: ranColor.toAlpha(0.8),
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: _buildGridTile(context, tile, ranColor),
    );
  }

  /*String _getTitle(DashboardTile tile) {
    final bool = tile.hasSplit && tile.label.contains('.');
    final title = bool ? '${tile.title} ${tile.subTitle}' : tile.label;
    return title;
  }*/

  _buildGridTile(BuildContext context, DashboardTile tile, Color ranColor) {
    // final title = _getTitle(tile);

    return GridTile(
      header: _HighlightedText(
        text: tile.getTitle,
        query: query,
        isUppercase: true,
        style: context.textTheme.titleSmall?.copyWith(
          overflow: TextOverflow.ellipsis,
        ),
      ),
      footer: Tooltip(
        message: (tile.description ?? '').toSentence,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: _HighlightedText(
          text: tile.description ?? '',
          query: query,
          style: context.textTheme.bodyMedium?.copyWith(
            overflow: TextOverflow.ellipsis,
            // backgroundColor: kBgLightColor.toAlpha(0.7),
          ),
        ),
      ),
      child: Icon(
        tile.icon,
        size: 80,
        color: kLightBlueColor.toAlpha(0.6),
        semanticLabel: tile.getTitle,
      ),
    );
    /*Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _HighlightedText(
            text: tile.label,
            query: query,
            isUppercase: true,
            style: context.textTheme.titleSmall,
          ),
        ),
        Icon(tile.icon, color: kLightBlueColor, size: 80, semanticLabel: title),
        Expanded(
          child: _HighlightedText(
            text: tile.description ?? '',
            query: query,
            style: context.textTheme.bodyMedium,
          ),
        ),
      ],
    );*/
  }
}

/// [_ListViewResults] ListView Builder for tiles
class _ListViewResults extends StatelessWidget {
  final String query;
  final void Function() triggerSearchBar;
  final List<DashboardTile> filteredTiles;
  final bool Function(String access, BuildContext cxt) canAccess;

  const _ListViewResults({
    required this.query,
    required this.canAccess,
    required this.filteredTiles,
    required this.triggerSearchBar,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: filteredTiles.length,
      itemBuilder: (context, index) {
        final tile = filteredTiles[index];
        return _buildListCard(context, tile, index);
      },
    );
  }

  /*String _getTitle(DashboardTile tile) {
    final bool = tile.hasSplit && tile.label.contains('.');
    final title = bool ? '${tile.title} ${tile.subTitle}' : tile.label;
    return title;
  }*/

  Card _buildListCard(BuildContext cxt, DashboardTile tile, int index) {
    final ranColor = randomBgColors[index]; // kLightBlueColor
    // final title = _getTitle(tile);

    return Card(
      elevation: 30,
      color: ranColor.toAlpha(0.8),
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      child: ListTile(
        dense: true,
        title: _HighlightedText(
          query: query,
          text: tile.getTitle,
          isUppercase: true,
          style: cxt.textTheme.titleSmall,
        ),
        subtitle: _HighlightedText(
          query: query,
          text: tile.description ?? '',
          style: cxt.textTheme.bodyMedium,
        ),
        leading: Icon(tile.icon, color: kLightBlueColor),
        onTap: () {
          final hasPerm = canAccess(tile.access, cxt);
          if (!hasPerm) {
            cxt.showAlertOverlay(
              "You don't have permission to use this feature",
              bgColor: kWarningColor,
              label: "OK",
            );
            return;
          }
          if (tile.param.entries.isEmpty) {
            cxt.goNamed(tile.route);
          } else {
            cxt.goNamed(
              tile.route,
              extra: tile.param,
              pathParameters: tile.param,
            );
          }
          triggerSearchBar();
        },
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final bool isUppercase;

  const _HighlightedText({
    this.style,
    required this.text,
    required this.query,
    this.isUppercase = false,
  });

  @override
  Widget build(BuildContext context) {
    final styleCopy = style?.copyWith(
      fontSize: 13,
      color: kLightGrayColor,
      overflow: TextOverflow.ellipsis,
    );

    // Optionally convert text to uppercase if required
    String displayText = isUppercase ? text.toUpperAll : text.toSentence;

    if (query.isEmpty) {
      return Text(displayText, style: styleCopy);
    }

    final lowerText = displayText.toLowerAll;
    final lowerQuery = query.toLowerAll;

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(
          TextSpan(text: displayText.substring(start), style: styleCopy),
        );
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(text: displayText.substring(start, index), style: styleCopy),
        );
      }

      spans.add(
        TextSpan(
          text: displayText.substring(index, index + query.length),
          // Highlight color
          style: styleCopy?.copyWith(
            color: kBgLightColor,
            fontWeight: FontWeight.bold,
            // backgroundColor: kBgLightColor.toAlpha(0.7),
          ),
        ),
      ); //469-564-1299 - Celina montessori

      start = index + query.length;
    }

    return RichText(maxLines: 3, text: TextSpan(children: spans));
  }
}

///////

/*class SpotlightSearchBar extends StatefulWidget {
  final bool showSearchBar;
  final List<DashboardTile> dashboardTiles;

  const SpotlightSearchBar({
    super.key,
    this.showSearchBar = false,
    this.dashboardTiles = const [],
  });

  @override
  State<SpotlightSearchBar> createState() => _SpotlightSearchBarState();
}

class _SpotlightSearchBarState extends State<SpotlightSearchBar> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  bool _isSearchActive = false;
  bool _isKeyHeld = false;

  Timer? _longPressTimer;
  Timer? _doubleTapTimer;
  bool _waitingForSecondTap = false;
  List<DashboardTile> filteredTiles = [];

  @override
  void initState() {
    super.initState();
    // Request focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    filteredTiles = widget.dashboardTiles;
  }

  void _onKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.space) {
      // debugPrint("KeyEvent: ${event.runtimeType} - ${event.logicalKey}");

      if (event is KeyDownEvent && !_isKeyHeld) {
        _isKeyHeld = true;

        // Start long press timer
        _longPressTimer = Timer(fAnimateDuration, () {
          debugPrint("Long press triggered");
          _triggerSearchBar();
          _cancelDoubleTap();
        });

        if (_waitingForSecondTap) {
          debugPrint("Double press triggered");
          _triggerSearchBar();
          _cancelDoubleTap();
          _longPressTimer?.cancel();
        } else {
          _waitingForSecondTap = true;
          _doubleTapTimer = Timer(kAnimateDuration, () {
            _waitingForSecondTap = false;
          });
        }
      }

      if (event is KeyUpEvent) {
        _isKeyHeld = false;
        _longPressTimer?.cancel();
      }
    }
  }

  void _cancelDoubleTap() {
    _doubleTapTimer?.cancel();
    _waitingForSecondTap = false;
  }

  // Toggle the search bar visibility
  void _triggerSearchBar() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _controller.clear();
        filteredTiles = widget
            .dashboardTiles; // Reset the filtered list to all tiles when closed
      }
    });
  }

  // The search logic to filter tiles
  void _onSearchChanged(String query) {
    setState(() {
      filteredTiles = widget.dashboardTiles.where((tile) {
        // Filter tiles by matching the query with either label or description
        final label = tile.label.toLowercaseAll;
        final desc = (tile.description ?? '').toLowercaseAll;
        final searchQuery = query.toLowercaseAll;
        return label.contains(searchQuery) || desc.contains(searchQuery);
      }).toList();
    });
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _doubleTapTimer?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var sWidth = context.screenWidth * (context.isMobile ? 0.94 : 0.7);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: SizedBox(
        width: sWidth,
        child: Stack(
          children: [
            if (widget.showSearchBar || _isSearchActive) ...[
              _buildSearchBar(context),
              (filteredTiles.isNotEmpty)
                  ? Expanded(child: _buildSearchResultsList(context))
                  : Card(
                      color: kLightBlueColor,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Center(child: Text("No results found")),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext cxt) {
    return Positioned(
    child: Material(
      color: kTransparentColor,
      child: AnimatedContainer(
        duration: kAnimateDuration,
        height: 50,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: kLightBlueColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: kBgLightColor.toAlpha(0.3), blurRadius: 15),
          ],
        ),
        child: _buildSearchField(),
      ),
    ));
  }

  Row _buildSearchField() {
    final border = OutlineInputBorder(
      borderSide: BorderSide(width: 0, color: kTransparentColor),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: CustomTextField(
            controller: _controller,
            autofocus: true,
            inputDecoration: InputDecoration(
              isDense: true,
              hintText: "Spotlight Search...",
              border: InputBorder.none,
              focusedBorder: border,
              enabledBorder: border,
              prefixIcon: Icon(Icons.search, color: kPrimaryAccentColor),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _triggerSearchBar(),
              ),
            ),
            keyboardType: TextInputType.none,
            onChanged: _onSearchChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsList(BuildContext cxt) {
    return ListView.builder(
      itemCount: filteredTiles.length,
      itemBuilder: (context, index) {
        final tile = filteredTiles[index];
        return Card(
          color: kLightBlueColor,
          elevation: 30,
          margin: const EdgeInsets.symmetric(vertical: 3.0),
          child: ListTile(
            dense: true,
            title: Text(
              tile.label.toTitleCase,
              style: cxt.textTheme.titleMedium,
            ),
            subtitle: Text(
              tile.description?.toUpperCaseFirst ?? '',
              style: cxt.textTheme.bodyMedium,
            ),
            leading: Icon(tile.icon, color: kPrimaryAccentColor),
            onTap: () => cxt.goNamed(tile.action),
          ),
        );
      },
    );
  }
}*/

/*
class SpotlightSearchBar2 extends StatefulWidget {
  const SpotlightSearchBar2({super.key});

  @override
  State<SpotlightSearchBar2> createState() => _SpotlightSearchBarState2();
}

class _SpotlightSearchBarState2 extends State<SpotlightSearchBar2> {
  bool _isSearchActive = false;
  final TextEditingController _controller = TextEditingController();

  DateTime? _lastSpacePressTime;
  final Duration _doublePressThreshold = Duration(milliseconds: 300);
  void _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.space,
        )) {
      final isShortcutPressed = Platform.isMacOS
          ? HardwareKeyboard.instance.isMetaPressed
          : HardwareKeyboard.instance.isControlPressed;

      if (isShortcutPressed) {
        final now = DateTime.now();

        if (_lastSpacePressTime != null &&
            now.difference(_lastSpacePressTime!) < _doublePressThreshold) {
          _toggleSearchBar();
        }

        _lastSpacePressTime = now;
      }
    }
  }

  void _toggleSearchBar() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _onKeyEvent,
      child: Stack(
        children: [
          Center(
            child: Text("Double press Command + Space to toggle Spotlight"),
          ),
          if (_isSearchActive) _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 50,
      left: 50,
      right: 50,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _controller.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Timer? _longPressTimer;
  bool _longPressTriggered = false;

  void _onKeyEvent(KeyEvent event) {
    final isShortcutPressed = Platform.isMacOS
        ? HardwareKeyboard.instance.isMetaPressed
        : HardwareKeyboard.instance.isControlPressed;

    if (event is KeyDownEvent &&
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.space,
        ) &&
        isShortcutPressed &&
        !_longPressTriggered) {
      _longPressTriggered = true;

      _longPressTimer = Timer(Duration(milliseconds: 500), () {
        _toggleSearchBar();
      });
    }

    if (event is KeyUpEvent && event.logicalKey == LogicalKeyboardKey.space) {
      _longPressTimer?.cancel();
      _longPressTriggered = false;
    }
  }


class _SpotlightSearchBarState extends State<SpotlightSearchBar> {
  bool _isSearchActive = false;
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  // Function to listen for keyboard input (e.g., Command+Space)
  void _onKeyEvent(KeyEvent event) {
    // Check if it's a key down event
    if (event is KeyDownEvent &&
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.space,
        )) {
      final isShortcutPressed = Platform.isMacOS
          ? HardwareKeyboard
                .instance
                .isMetaPressed // ⌘ Command key on macOS
          : HardwareKeyboard
                .instance
                .isControlPressed; // Ctrl key on Windows/Linux

      if (isShortcutPressed) {
        setState(() {
          _isSearchActive = !_isSearchActive;
          if (!_isSearchActive) {
            _controller.clear();
          }
        });
      }
    }
  }
  void _onKeyEvent2(RawKeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.space &&
        event.isControlPressed) {
      setState(() {
        _isSearchActive = !_isSearchActive;
        if (!_isSearchActive) {
          _controller.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _onKeyEvent, // 👈 Use onKeyEvent instead of onKey
      child: Stack(
        children: [
          Center(child: Text("Press Command + Space to toggle Spotlight")),
          if (_isSearchActive)
            _buildSearchBar(), // You can extract your animated container here for cleanliness
        ],
      ),
    );
  }

  AnimatedPositioned _buildSearchBar() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 50,
      left: 50,
      right: 50,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _controller.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
