import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';

enum UserGuidePermission { userGuide, licenseRenewalGuide }

final tManualDisplayName = 'User Guide';

/// [highRiskPermissions] Unique Permissions that trigger a warning dialog,
/// prompting the admin to reconsider before assigning them.
final highRiskPermissions = [
  EnumHelper(UserGuidePermission.userGuide).getName,
  EnumHelper(UserGuidePermission.licenseRenewalGuide).getName,
];

final List<AccessControl> tManualPermission = [
  AccessControl(
    access: UserGuidePermission.userGuide,
    module: 'user-guide (Paid Training)',
    title: 'User Guide',
    description:
        'Provides access to the full user manual, including instructions on how to use the software.',
  ),
  AccessControl(
    access: UserGuidePermission.licenseRenewalGuide,
    module: 'user-guide (Paid Training)',
    title: 'License Renewal Guide',
    description:
        'Grants access to detailed instructions for renewing your software license.',
  ),
];
