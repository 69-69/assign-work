import 'package:flutter/material.dart';

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
  ```

  And later, call from anywhere in the widget tree:

  ```dart
  RefreshEntireApp.restartApp(context);
  ```
* */
class RefreshEntireApp extends StatefulWidget {
  /// The root widget of your app or subtree you want to be restartable.
  final Widget child;

  const RefreshEntireApp({super.key, required this.child});

  /// Call this static method from anywhere in the widget tree to trigger a full rebuild.
  static Future<void> restartApp(BuildContext context) async {
    // Find the nearest _RestartWidgetState in the widget tree and call restartApp on it
    final _RefreshEntireAppState? state = context
        .findAncestorStateOfType<_RefreshEntireAppState>();
    state?.restartApp();
  }

  @override
  State<RefreshEntireApp> createState() => _RefreshEntireAppState();
}

class _RefreshEntireAppState extends State<RefreshEntireApp> {
  /// A unique key used to force the subtree to rebuild when changed
  Key _key = UniqueKey();

  /// This method changes the key, causing KeyedSubtree to rebuild its child,
  /// effectively restarting the widget tree below it.
  restartApp() => _resetSubtree();

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
