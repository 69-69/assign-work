import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsDropdown extends StatelessWidget {
  final Workspace? workspace;
  final Employee? employee;

  const NotificationsDropdown({super.key, this.workspace, this.employee});

  @override
  Widget build(BuildContext context) {
    final routePath = GoRouter.of(context).state.matchedLocation;

    // Hide the profile menu on specific routes
    if (routePath == RouteNames.workspaceSignIn ||
        routePath.contains(RouteNames.employeeSignIn)) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.all(20),
      child: PopupMenuButton<String>(
        tooltip: 'Tap to open notifications',
        padding: EdgeInsets.zero,
        offset: const Offset(0, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            padding: EdgeInsets.zero,
            child: _buildNotificationItems(context, workspace: workspace),
          ),
        ],
        child: _buildIcon(context),
      ),
    );
  }

  _buildIcon(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: kGrayBlueColor.toAlpha(0.2),
          child: Icon(Icons.notifications, color: kLightBlueColor),
        ),
        Positioned(
          top: 1.0,
          right: 7.0,
          child: Text(
            '9',
            style: TextStyle(color: kLightBlueColor, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItems(BuildContext context, {Workspace? workspace}) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications'.toUpperAll,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: () => prettyPrint('Tapped', 'Mark all as read'),
                icon: Icon(Icons.check_circle, color: kGrayBlueColor),
                tooltip: 'Mark All as Read',
              ),
            ],
          ),

          const HorizontalDivider(thickness: 4),
          _buildListTile(context, title: 'New request for quote approval'),
          _buildListTile(context, title: 'New Purchase Requisition'),
          const HorizontalDivider(),
        ],
      ),
    );
  }

  ListTile _buildListTile(BuildContext context, {String title = ''}) {
    return ListTile(
      dense: true,
      mouseCursor: SystemMouseCursors.click,
      contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
      title: Padding(
        padding: EdgeInsets.only(bottom: 4.0),
        child: Text(title, style: TextStyle(color: context.onSurfaceColor)),
      ),
      trailing: IconButton(
        onPressed: () => prettyPrint('Tapped', 'Mark as read'),
        icon: Icon(Icons.check_circle, color: kGrayBlueColor),
        tooltip: 'Mark as read',
      ),
      onTap: () => prettyPrint('Tapped', title),
    );
  }
}
