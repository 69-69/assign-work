// ---------------------------
// ⚙️ Account Status Definitions
// ---------------------------

import 'package:assign_erp/core/util/str_util.dart';

enum AccountStatus { enabled, disabled }

/* USAGE:
* final status = AccountStatus.enabled;
* print(status.label); // Output: enable
* */
extension AccountStatusExtension on AccountStatus {
  String get getValue => getEnumName<AccountStatus>(this);
}

class AccountStatusHelper {
  /// Get Account Status from String value [fromString].
  static AccountStatus fromString(String? value) =>
      AccountStatus.values.firstWhere(
        (e) => e.getValue == value,
        orElse: () => AccountStatus.disabled,
      );

  /// [toStringList] Convert enum list to a list of strings
  static List<String> toStringList([bool includeLabel = true]) {
    final list = AccountStatus.values.map((e) => e.getValue).toList();
    return includeLabel ? ['account status', ...list] : list;
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

/// 🏬 Default (Main) Tenant's organization store/shop ID for multi-stores locations
// final mainStoreNumber = 'STO-Main-${DateTime.now().year}';
