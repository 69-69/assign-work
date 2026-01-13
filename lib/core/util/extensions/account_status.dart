// ---------------------------
// ⚙️ Account Status Definitions
// ---------------------------

import 'package:assign_erp/core/util/enum_util.dart';

enum AccountStatus { disabled, enabled }

/* USAGE:
* final status = AccountStatus.enabled;
* print(status.label); // Output: enable
* */
extension AccountStatusExtension on AccountStatus {
  /// [getName] Get the specific Enum Name
  String get getName => EnumUtil<AccountStatus>(this).getName;
}

class AccountStatusUtil {
  /// [fromString] Converts String/Label to enum value.
  static AccountStatus fromString(String? value) =>
      EnumUtil.fromString<AccountStatus>(AccountStatus.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'account status' : '';
    return EnumUtil.toStringList<AccountStatus>(AccountStatus.values, label);
  }
}
// ---------------------------
// 🔐 Authentication & Temporary Passcode
// ---------------------------

/// Temporary passcode used for initial employee sign-in.
///
/// This weak, time-limited passcode (valid for 1 week) is used only for
/// first-time employee sign-ins after the organization's workspace sign-in.
/// When an employee signs in using a passcode that begins
/// with [kTemporaryPasscodePrefix], they will be required to
/// create a new, permanent passcode.
const kTemporaryPasscodePrefix = 'TEMP-';
const int kTemporaryPasscodeLength = 5;

/*
// 🏬 Default (Main) Tenant's organization store/shop ID for multi-stores locations
// final mainStoreNumber = 'STO-Main-${DateTime.now().year}';
/// Converts String/Label string back to enum [fromString].
  static AccountStatus fromString(String? value) =>
      AccountStatus.values.firstWhere(
        (e) => e.getValue == value,
        orElse: () => AccountStatus.disabled,
      );

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeLabel = true]) {
    final list = AccountStatus.values.map((e) => e.getValue).toList();
    return includeLabel ? ['account status', ...list] : list;
  }*/
