import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/breadcrumb_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuildBreadcrumbs extends StatelessWidget {
  const BuildBreadcrumbs({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.routeConfig;

    // Avoid rendering if no matches exist
    if (config.isEmpty || config.matches.isEmpty) {
      prettyPrint("No matched routes for breadcrumb — skipping.", "Hiding");
      return const SizedBox.shrink();
    }

    final routePath = context.routeFromUri;

    // Skip/hide breadcrumbs on specific routes
    if (routePath == RouteNames.workspaceSignIn ||
        routePath.contains(RouteNames.employeeSignIn)) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: 30,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: buildBreadcrumbs(context, routePath: routePath),
    );
  }

  Widget buildBreadcrumbs(BuildContext context, {required String routePath}) {
    final breadcrumbs = generateBreadcrumbs(routePath);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        direction: Axis.horizontal,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (int i = 0; i < breadcrumbs.length; i++) ...[
            /*MouseRegion(
              cursor: i == breadcrumbs.length - 1
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: _buildGestureDetector(i, breadcrumbs, context),
            ),*/
            _buildInkWell(i, breadcrumbs, context),
            if (i != breadcrumbs.length - 1)
              const Text(' > ', style: TextStyle(color: kGrayColor)),
          ],
        ],
      ),
    );
  }

  _buildInkWell(int i, List<Breadcrumb> breadcrumbs, BuildContext context) {
    final isLast = i == breadcrumbs.length - 1;

    return InkWell(
      mouseCursor: isLast ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onTap: isLast ? null : () => context.go(breadcrumbs[i].path),
      child: Text(
        breadcrumbs[i].label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isLast
              ? context.colorScheme.onSecondaryContainer
              : kPrimaryAccentColor,
          fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  List<Breadcrumb> generateBreadcrumbs(String currentPath) {
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
          final defaulted = fallback.isEmpty ? 'Details' : fallback;

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

  String _prettifyLabel(String part) {
    if (part.isEmpty) return 'Home';

    final label = part[0].toUpperAll + part.substring(1);
    return label
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'(screen|app)$', caseSensitive: false), '')
        .trim()
        .toTitle;
  }
}

/*class BuildBreadcrumbs2 extends StatelessWidget {
  const BuildBreadcrumbs2({super.key});

  @override
  Widget build(BuildContext context) {
    final routePath = GoRouter.of(context).state.matchedLocation;

    if (routePath == RouteNames.workspaceSignIn ||
        routePath.contains(RouteNames.employeeSignIn)) {
      return const SizedBox.shrink();
    }
    final delegate = GoRouter.of(context).routerDelegate;
    final config = delegate.currentConfiguration;

    // Avoid rendering if no matches exist
    if (config.isEmpty || config.matches.isEmpty) {
      prettyPrint("No matched routes for breadcrumb — skipping.", "Hiding");
      return const SizedBox.shrink();
    }

    final routePathCheck = config.uri.path;
    // final routePath = GoRouter.of(context).location;

    // Skip/hide breadcrumbs on specific routes
    if (routePathCheck == RouteNames.workspaceSignIn ||
        routePathCheck.contains(RouteNames.employeeSignIn)) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: 30,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: buildBreadcrumbs(context, routePath: routePath),
    );
  }

  Widget buildBreadcrumbs(BuildContext context, {required String routePath}) {
    final breadcrumbs = generateBreadcrumbs(routePath);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8), // Optional padding
      child: Wrap(
        direction: Axis.horizontal,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (int i = 0; i < breadcrumbs.length; i++) ...[
            MouseRegion(
              cursor: i == breadcrumbs.length - 1
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: _buildGestureDetector(i, breadcrumbs, context),
            ),
            if (i != breadcrumbs.length - 1)
              const Text(' > ', style: TextStyle(color: kGrayColor)),
          ],
        ],
      ),
    );
  }

  _buildGestureDetector(
    int i,
    List<Breadcrumb> breadcrumbs,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () {
        if (i != breadcrumbs.length - 1) {
          context.go(breadcrumbs[i].path);
        }
      },
      child: Text(
        breadcrumbs[i].label,
        style: TextStyle(
          color: i == breadcrumbs.length - 1
              ? context.colorScheme.onSecondaryContainer
              : kPrimaryAccentColor,
          fontWeight: i == breadcrumbs.length - 1
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }

  List<Breadcrumb> generateBreadcrumbs(String currentPath) {
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

      // ❗ Skip last part if it's an ID
      final isLast = i == parts.length - 1;
      if (isIdLike && isLast) {
        // Don't add it to breadcrumbs — instead update the previous label
        if (breadcrumbs.isNotEmpty) {
          final prev = breadcrumbs.removeLast();
          final fallback = _prettifyLabel(parts[i - 1]);
          final defaulted = fallback.isEmpty ? 'Details' : fallback;

          breadcrumbs.add(Breadcrumb(label: defaulted, path: prev.path));
        }
        continue;
      }

      accumulatedPath += '/$part';

      String label = _prettifyLabel(part);
      breadcrumbs.add(Breadcrumb(label: label, path: accumulatedPath));
    }

    return breadcrumbs;
  }

  String _prettifyLabel(String part) {
    if (part.isEmpty) return 'Home';

    final label = part[0].toUpperCase() + part.substring(1);
    return label
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'(screen|app)$', caseSensitive: false), '')
        .trim()
        .toUppercaseFirstLetterEach;
  }
}*/
