import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/breadcrumb_model.dart';
import 'package:assign_erp/core/widgets/nav/breadcrumb_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuildBreadcrumbs extends StatelessWidget {
  const BuildBreadcrumbs({super.key});

  @override
  Widget build(BuildContext context) {
    /*final config = context.routeConfig;

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
    }*/

    final routePath = BreadcrumbService.currentPath(context);
    if (routePath.isEmpty) {
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
    final breadcrumbs = BreadcrumbService.generateBreadcrumbs(routePath);

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
          color: isLast ? context.onSecondaryContainer : kPrimaryAccentColor,
          fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
