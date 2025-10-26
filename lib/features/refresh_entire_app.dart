import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/*
* ### ✅ Summary of What It Does

* A widget that allows the entire app (or a subtree) to be programmatically restarted
* by rebuilding it with a new unique key
* This is often used after logout, language/theme change, or hard reset logic.

  ---

  ### ✅ Usage Example in `main.dart`:

  ```dart
  void main() {
    runApp(RefreshEntireApp(child: MyApp()));
  }
  * ** OR **
  *  // Wrap the router’s child in the refresh handler
  return MaterialApp.router(
      routerConfig: _appRouter,
      title: appName.replaceAll('.', ' '),
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      theme: widget.theme,
      builder: (_, child) =>
          RefreshEntireApp(child: _authStateListener(child, _appRouter)),
    );
  ```

  And later, call from anywhere in the widget tree:

  ```dart
  RefreshEntireApp.restartApp(context);
  ```
* */
class RefreshEntireApp extends StatefulWidget {
  final Widget child;

  const RefreshEntireApp({super.key, required this.child});

  static Future<void> restartApp(BuildContext context) async {
    final state = context.findAncestorStateOfType<_RefreshEntireAppState>();

    if (state == null) {
      debugPrint('⚠️ No RefreshEntireApp found in widget tree.');
      _notifyState(context, msg: 'Failed to refresh workspace.');
      return;
    }

    await state.restartApp();

    debugPrint('🔄 Tenant Workspace successfully refreshed');

    if (!context.mounted) return;

    _notifyState(context);
  }

  static void _notifyState(BuildContext context, {String? msg}) {
    context.showAlertOverlay(
      msg ?? 'Workspace successfully refreshed',
      bgColor: msg == null ? kSuccessColor : kDangerColor,
    );
  }

  @override
  State<RefreshEntireApp> createState() => _RefreshEntireAppState();
}

class _RefreshEntireAppState extends State<RefreshEntireApp> {
  Key _subtreeKey = UniqueKey();
  bool _isRestarting = false;

  Future<void> restartApp() async {
    setState(() => _isRestarting = true);
    setState(() => _subtreeKey = UniqueKey());

    await Future.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;

    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isRestarting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.center,
        children: [
          KeyedSubtree(key: _subtreeKey, child: widget.child),
          if (_isRestarting) Positioned.fill(child: _buildStack()),
        ],
      ),
    );
  }

  Stack _buildStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black54),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(appLogoWithBG, width: 64, semanticLabel: appName),
            const SizedBox(height: 5),
            _buildTitle(),
          ],
        ),
      ],
    );
  }

  Wrap _buildTitle() {
    return Wrap(
      spacing: 5,
      alignment: WrapAlignment.center,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        Text(
          'Refreshing Workspace...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.normal,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

/* NEEDED
class RefreshEntireApp2 extends StatefulWidget {
  /// The root widget of your app or subtree you want to be restartable.
  final Widget child;

  const RefreshEntireApp2({super.key, required this.child});

  /// Call this static method from anywhere in the widget tree to trigger a full rebuild.
  static Future<void> restartApp(BuildContext context) async {
    // Find the nearest _RestartWidgetState in the widget tree and call restartApp on it
    final _RefreshEntireApp2State? state = context
        .findAncestorStateOfType<_RefreshEntireApp2State>();
    // state?.restartApp();
    if (state != null) {
      await state.restartApp();
    } else {
      debugPrint('No _RefreshEntireAppState found in context');
    }
  }

  @override
  State<RefreshEntireApp2> createState() => _RefreshEntireApp2State();
}

class _RefreshEntireApp2State extends State<RefreshEntireApp2> {
  /// A unique key used to force the subtree to rebuild when changed
  Key _key = UniqueKey();

  /// This method changes the key, causing KeyedSubtree to rebuild its child,
  /// effectively restarting the widget tree below it.
  // restartApp() => _resetSubtree();
  /// Restart and wait until the next frame is rendered.
  Future<void> restartApp() async {
    _resetSubtree();
    // Wait for the next frame (ensures rebuild is complete)
    await Future.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
  }

  void _resetSubtree() {
    setState(() => _key = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Restarting entire app');
    // Rebuilds the entire subtree when the key changes
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
*/
