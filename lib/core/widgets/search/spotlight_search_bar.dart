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
  bool _isSearchActive = false;
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sWidth = context.screenWidth * (context.isMobile ? 0.94 : 0.7);
    final tileCount = filteredTiles.length > 4 ? 4 : filteredTiles.length;

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: sWidth,
        height: context.screenHeight * (tileCount + 2) * 0.1,
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
              ? Expanded(child: _buildSearchResultsList(context))
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
              prefixIcon: Icon(Icons.search, color: kPrimaryAccentColor),
              suffixIcon: IconButton(
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
          elevation: 30,
          color: kLightBlueColor.toAlpha(0.8),
          margin: const EdgeInsets.symmetric(vertical: 3.0),
          child: ListTile(
            dense: true,
            title: _buildHighlightedText(tile.label, cxt.textTheme.titleMedium),
            subtitle: _buildHighlightedText(
              tile.description ?? '',
              cxt.textTheme.bodyMedium,
            ),
            leading: Icon(tile.icon, color: kPrimaryAccentColor),
            onTap: () {
              final canAccess = _canAccess(tile.access, cxt);
              if (!canAccess) {
                cxt.showAlertOverlay(
                  "You don't have permission to use this feature",
                  bgColor: kWarningColor,
                  label: "OK",
                );
                return;
              }
              if (tile.param.entries.isEmpty) {
                cxt.goNamed(tile.action);
              } else {
                cxt.goNamed(
                  tile.action,
                  extra: tile.param,
                  pathParameters: tile.param,
                );
              }
              _triggerSearchBar();
            },
          ),
        );
      },
    );
  }

  Widget _buildHighlightedText(String text, TextStyle? style) {
    final query = _controller.text;
    style = style?.copyWith(color: kBgLightColor);

    if (query.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerAll;
    final lowerQuery = query.toLowerAll;

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.toTitle.substring(start), style: style));
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(text: text.toSentence.substring(start, index), style: style),
        );
      }

      spans.add(
        TextSpan(
          text: text.toTitle.substring(index, index + query.length),
          style: style?.copyWith(
            fontWeight: FontWeight.bold,
            color: kPrimaryAccentColor, // Highlight color
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(text: TextSpan(children: spans));
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
