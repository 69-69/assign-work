import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/features/trouble_shooting/data/permission/trouble_shoot_permission.dart';
import 'package:flutter/material.dart';

/// Troubleshoot Tiles Navigation [TroubleShootTiles]
extension TroubleShootTiles on dynamic {
  List<DashboardTile> get troubleShootTiles {
    final tilesData = [
      {
        'hasSplit': true,
        'label': 'Diagnose . Issues',
        'icon': Icons.bug_report_outlined,
        'action': RouteNames.diagnoseIssues,
        'param': {},
        'access': _getName(TroubleShootPermission.manageDiagnostics),
        'description': 'View error logs and diagnose issues in the system.',
      },
      {
        'hasSplit': true,
        'label': 'Tenant . Workspaces',
        'icon': Icons.workspaces_outline,
        'action': RouteNames.allTenantWorkspaces,
        'param': {},
        'access': _getName(TroubleShootPermission.manageTenants),
        'description': 'Manage and monitor all tenant workspaces.',
      },
      {
        'hasSplit': true,
        'label': 'Subscription . Management',
        'icon': Icons.subscriptions,
        'action': RouteNames.manageSubscriptions,
        'param': {},
        'access': _getName(TroubleShootPermission.manageSubscriptions),
        'description': 'Manage Subscription Licenses and Plans',
      },
    ];

    return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
  }
}

// Get name from enum
String _getName(e) => EnumHelper<TroubleShootPermission>(e).getName;
