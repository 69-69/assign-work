import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:flutter/material.dart';

/// Model to hold visited route info
class VisitedRoute {
  final String name;
  final DateTime visitedAt;

  VisitedRoute({required this.name, required this.visitedAt});
}

// final List<VisitedRoute> _visitedRoutes = [];

/// [RouteLogger] Route Observer for GoRouter:
/// track visited routes with timestamps, with optional cleanup.
class RouteLogger extends NavigatorObserver {
  final bool removeChar;
  final List<VisitedRoute> _visitedRoutes = [];

  RouteLogger({this.removeChar = true});

  /// Returns an unmodifiable list of visited routes with timestamps
  List<VisitedRoute> get visitedRoutes => List.unmodifiable(_visitedRoutes);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _trackRoute(route.settings.name);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _trackRoute(previousRoute?.settings.name);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _trackRoute(newRoute?.settings.name);

  void _trackRoute(String? name) {
    if (name == null) return;

    final cleanedName = removeChar ? _cleanRouteName(name) : name;

    final alreadyLogged = _visitedRoutes.any((r) => r.name == cleanedName);

    if (!alreadyLogged) {
      final visited = VisitedRoute(
        name: cleanedName,
        visitedAt: DateTime.now(),
      );

      _visitedRoutes.add(visited);
      prettyPrint('visited-areas', '${visited.name} @ ${visited.visitedAt}');
    }
  }

  String _cleanRouteName(String str) {
    return str
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        // .replaceAll(RegExp(r'(screen|app)$', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'\b(screen|app|module)\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
