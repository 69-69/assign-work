import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';

enum AppTrainingPermission { appTraining, licenseRenewalGuide }

final appTrainingTitle = 'App Training';

/// [highRiskPermissions] Unique Permissions that trigger a warning dialog,
/// prompting the admin to reconsider before assigning them.
final highRiskPermissions = [
  EnumUtil(AppTrainingPermission.appTraining).getName,
  EnumUtil(AppTrainingPermission.licenseRenewalGuide).getName,
];

final List<AccessControl> allAppTrainingPermission = [
  AccessControl(
    access: AppTrainingPermission.appTraining,
    module: 'app-training (Paid Training)',
    title: 'App Training',
    description:
        'Provides access to the all app training, including instructions on how to use the software.',
  ),
  AccessControl(
    access: AppTrainingPermission.licenseRenewalGuide,
    module: 'app-training (Paid Training)',
    title: 'License Renewal',
    description:
        'Grants access to detailed instructions for renewing your software license.',
  ),
];
