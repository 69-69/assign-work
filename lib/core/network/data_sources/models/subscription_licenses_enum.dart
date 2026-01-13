import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';

/// [SubscriptionLicenses] Enum representing different subscription licenses available
/// for a workspace. These licenses grant various levels of access to different
/// system modules based on the type of subscription a workspace or organization holds.
enum SubscriptionLicenses {
  /// [pos] Point of Sale (P.O.S) License: Grants customers access to the Point of Sale system.
  pos,

  /// [crm] CRM License: Grants customers full access to the Customer Relationship Management system.
  crm,

  /// [warehouse] Warehouse (W.M.S) License: Grants customers access to the Warehouse Management System.
  warehouse,

  /// [inventory] Inventory (I.M.S) License: Grants customers access to the Inventory Management System.
  inventory,

  /// [salesDistribution] Sales Distribution License: Grants customers access to the Sales Distribution system.
  salesDistribution,

  /// [procurement] Procurement License: Grants customers access to the Procurement system.
  procurement,

  /// [agent] Agent License: Allows agents to manage their own and client's (tenants) workspaces.
  agent,

  /// [dev] Developer/TroubleShoot License: Used by developers for testing and troubleshooting purposes.
  dev,

  /// [onboarding] Onboarding License: Used for creating first-time Agent workspaces.
  onboarding,

  /// [cloud] Cloud License: Grants customers access to the Cloud system.
  cloud,

  /// [cloudBackup] Cloud Backup License: Grants customers access to the Cloud Backup system.
  cloudBackup,

  /// [paidTraining] Training License: Grants customers access to the Training materials (like tutorials).
  paidTraining,
}

/// [highRiskLicenses] Unique Subscription Licenses that trigger a warning dialog,
/// prompting the admin to reconsider before assigning them.
final highRiskLicenses = [
  EnumUtil(SubscriptionLicenses.dev).getName,
  EnumUtil(SubscriptionLicenses.agent).getName,
  EnumUtil(SubscriptionLicenses.onboarding).getName,
];

/// Example list of [AccessControl] objects representing the various
/// subscription licenses that can be associated with a workspace.
/// This list may be used to define specific control over access or functionality
/// that each license grants within the system.
final List<AccessControl> subscriptionLicenses = [
  // Example access control for each license type. In practice, each AccessControl
  // instance will define specific roles, permissions, or actions based on the license.
  /*AccessControl(
    module: 'full suite',
    title: 'Full Access License',
    description: 'Unrestricted access to all system operations and packages.',
    access: SubscriptionLicenses.full,
  ),*/
  AccessControl(
    module: 'point of sale',
    title: 'POS License',
    description: 'Access to the Point of Sale system.',
    access: SubscriptionLicenses.pos,
  ),

  AccessControl(
    module: 'customer management',
    title: 'CRM License',
    description: 'Access to the Customer Relationship Management system.',
    access: SubscriptionLicenses.crm,
  ),

  AccessControl(
    module: 'inventory management',
    title: 'Inventory License',
    description: 'Access to the Inventory Management System.',
    access: SubscriptionLicenses.inventory,
  ),

  AccessControl(
    module: 'sales distribution',
    title: 'Sales Distribution License',
    description: 'Access to the Sales Distribution system.',
    access: SubscriptionLicenses.salesDistribution,
  ),

  AccessControl(
    module: 'procurement management',
    title: 'Procurement License',
    description: 'Access to the Procurement system.',
    access: SubscriptionLicenses.procurement,
  ),

  AccessControl(
    module: 'warehouse management',
    title: 'Warehouse License',
    description: 'Access to the Warehouse Management System.',
    access: SubscriptionLicenses.warehouse,
  ),

  AccessControl(
    module: 'agent franchise',
    title: 'Agent License',
    description: 'Allows agents to manage their own and clients\' workspaces.',
    access: SubscriptionLicenses.agent,
  ),

  AccessControl(
    module: 'developer',
    title: 'Developer License',
    description: 'For developers to test and troubleshoot the system.',
    access: SubscriptionLicenses.dev,
  ),

  AccessControl(
    module: 'initial onboarding',
    title: 'Onboarding License',
    description: 'Used for creating first-time Agent workspaces.',
    access: SubscriptionLicenses.onboarding,
  ),
];

final List<AccessControl> addonsLicenses = [
  AccessControl(
    module: 'hosting and storage',
    title: 'Cloud License',
    description: 'Grants access to cloud systems and storage services.',
    access: SubscriptionLicenses.cloud,
  ),

  AccessControl(
    module: 'cloud sync backup',
    title: 'Cloud Backup License',
    description: 'Enables access to cloud backup and data synchronization.',
    access: SubscriptionLicenses.cloudBackup,
  ),

  AccessControl(
    module: 'paid training',
    title: 'Training License',
    description:
        'Provides access to training materials, including tutorials and employee training resources.',
    access: SubscriptionLicenses.paidTraining,
  ),
];

final licenseDisplayName = 'Subscription Licenses';
final addonsDisplayName = 'Addons Subscription';

/* Function to convert enum values to a string [licenseAsString]
String licenseAsString(SubscriptionLicenses e) => e.toString().split('.').last;

/// Function to convert enum values to a list of strings [workspaceRolesToList]
List<String> subscriptionLicensesToList<T>() {
  // Convert the modified list to a list of strings
  return SubscriptionLicenses.values.map((e) => licenseAsString(e)).toList();
}

SubscriptionLicenses getLicenseByString(String license) => SubscriptionLicenses
    .values
    .firstWhere((e) => licenseAsString(e) == license);*/
