import 'package:assign_erp/core/util/enum_helper.dart';

enum MainPermission {
  unknown, // For unspecified permissions
}

bool isUnknownPermission(String p) =>
    p == EnumHelper<MainPermission>(MainPermission.unknown).getValue;
