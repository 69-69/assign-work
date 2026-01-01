import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/features/user_guide/data/permission/user_guide_permission.dart';
import 'package:flutter/material.dart';

extension UserGuideTiles on dynamic {
  /// User-Guide Navigation Links [userGuideTiles]
  List<DashboardTile> get userGuideTiles {
    final tilesData = [
      {
        'label': 'guide to',
        'icon': Icons.how_to_reg,
        'action': RouteNames.howToConfigApp,
        'param': {},
        'access': _getName(UserGuidePermission.userGuide),
        'description':
            'Add manual with step-by-step instructions for software usage & configuration.',
      },
      {
        'hasSplit': true,
        'label': 'license . renewal',
        'icon': Icons.local_police,
        'action': RouteNames.howToRenewLicense,
        'param': {},
        'access': _getName(UserGuidePermission.licenseRenewalGuide),
        'description': 'create user-manual on renewing or activating software',
      },
    ];

    return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
  }
}

// Get name from enum
String _getName(e) => EnumHelper<UserGuidePermission>(e).getName;
