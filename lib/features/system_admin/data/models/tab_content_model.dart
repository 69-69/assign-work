import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';
import 'package:flutter/material.dart';

class TabContent<T extends Enum> {
  final String label;
  final IconData icon;
  final String? access;
  final String displayName;
  final List<AccessControl> permissions;

  TabContent({
    required this.label,
    required this.icon,
    T? accessEnum,
    required this.displayName,
    required this.permissions,
  }) : access = accessEnum != null ? EnumHelper<T>(accessEnum).getValue : null;
}
