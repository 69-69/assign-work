import 'package:assign_erp/core/util/enum_util.dart';

enum MainPermission {
  unknown, // For unspecified permissions
}

bool isUnknownPermission(String p) =>
    p == EnumUtil<MainPermission>(MainPermission.unknown).getName;
