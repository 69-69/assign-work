// ---------------------------
// ⚙️ Account Status Definitions
// ---------------------------

enum AccountStatus { enabled, disabled }

/* USAGE:
* final status = AccountStatus.enabled;
* print(status.label); // Output: enable
* */
extension AccountStatusExtension on AccountStatus {
  String get label {
    return switch (this) {
      AccountStatus.enabled => 'enable',
      AccountStatus.disabled => 'disable',
    };
  }
}

final employeeAccountStatusList = [
  'account status',
  ...AccountStatus.values.map((e) => e.label),
];

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
