import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/breadcrumb_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:flutter/material.dart';

class BreadcrumbService {
  static String currentPath(BuildContext context) {
    final config = context.routeConfig;

    // Avoid rendering if no matches exist
    if (config.isEmpty || config.matches.isEmpty) {
      prettyPrint("No matched routes for breadcrumb — skipping.", "Hiding");
      return '';
    }

    final routePath = context.routeFromUri;

    // Skip/hide breadcrumbs on specific routes
    if (routePath == RouteNames.workspaceSignIn ||
        routePath.contains(RouteNames.employeeSignIn)) {
      return '';
    }
    return routePath;
  }

  static String _prettifyLabel(String part) {
    if (part.isEmpty) return 'Home';

    final label = part[0].toUpperAll + part.substring(1);
    return label
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        // .replaceAll(RegExp(r'(screen|app)$', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'\b(screen|app|module)\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toTitle;
  }

  static List<Breadcrumb> generateBreadcrumbs(
    String currentPath, {
    String optFallback = 'Details',
  }) {
    // Normalize path: remove trailing slashes
    final normalizedPath = currentPath.endsWith('/')
        ? currentPath.substring(0, currentPath.length - 1)
        : currentPath;

    final parts = normalizedPath.split('/')..removeWhere((p) => p.isEmpty);

    if (parts.isEmpty) return [];

    List<Breadcrumb> breadcrumbs = [];
    String accumulatedPath = '';

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      final isIdLike =
          RegExp(r'^[0-9]+$').hasMatch(part) ||
          RegExp(r'^[a-zA-Z0-9\-]{6,}$').hasMatch(part);

      // Skip last part if it's an ID
      final isLast = i == parts.length - 1;
      if (isIdLike && isLast) {
        // Update the previous label with the fallback
        if (breadcrumbs.isNotEmpty) {
          final prev = breadcrumbs.removeLast();
          final fallback = _prettifyLabel(parts[i - 1]);
          final defaulted = fallback.isEmpty ? optFallback : fallback;

          breadcrumbs.add(Breadcrumb(label: defaulted, path: prev.path));
        }
        continue; // Skip this part and move to the next iteration
      }

      accumulatedPath += '/$part';

      String label = _prettifyLabel(part);
      breadcrumbs.add(Breadcrumb(label: label, path: accumulatedPath));
    }

    return breadcrumbs;
  }
}
