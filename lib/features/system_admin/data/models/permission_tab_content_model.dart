import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';
import 'package:flutter/material.dart';

class PermissionTabContent<T extends Enum> {
  final String label;
  final IconData icon;
  final String? access;
  final String displayName;

  /// [highRiskPermissions] Unique Permissions that trigger a warning dialog,
  /// prompting the admin to reconsider before assigning them.
  final List<String>? highRiskPermissions;
  final List<AccessControl> permissions;

  PermissionTabContent({
    required this.label,
    required this.icon,
    T? accessEnum,
    this.highRiskPermissions,
    required this.displayName,
    required this.permissions,
  }) : access = accessEnum != null ? EnumHelper<T>(accessEnum).getName : null;
}
