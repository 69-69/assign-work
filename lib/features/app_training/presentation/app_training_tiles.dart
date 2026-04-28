import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/features/app_training/data/permission/app_training_permission.dart';
import 'package:flutter/material.dart';

extension AppTrainingTiles on dynamic {
  /// App training Navigation Links [appTrainingTiles]
  List<DashboardTile> get appTrainingTiles {
    final tilesData = [
      {
        'label': 'training',
        'icon': Icons.how_to_reg,
        'route': RouteNames.howToConfigApp,
        'param': {},
        'access': _getName(AppTrainingPermission.appTraining),
        'description':
            'Create training modules with step-by-step instructions for software usage & configuration.',
      },
      {
        'hasSplit': true,
        'label': 'license . renewal',
        'icon': Icons.local_police,
        'route': RouteNames.howToRenewLicense,
        'param': {},
        'access': _getName(AppTrainingPermission.licenseRenewalGuide),
        'description': 'how to renew and activate software license',
      },
    ];

    return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
  }
}

// Get name from enum
String _getName(e) => EnumUtil<AppTrainingPermission>(e).getName;
