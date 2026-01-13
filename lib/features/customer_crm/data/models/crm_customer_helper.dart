import 'package:assign_erp/core/util/enum_util.dart';

/// Customer Type
enum CustomerType { individual, company }

enum CommunicationPreferences { email, sms, push, whatsapp, none }

/// Customer Status (e.g. Lead, Prospect, Active, Inactive)
enum CustomerStatus { lead, prospect, active, inactive }

enum LeadSource { referral, website, campaign, other }

/// Customer Category (e.g. Retail, Wholesale, Corporate)
enum CustomerCategory {
  retail,
  wholesale,
  corporate,
  government,
  distributor,
  vip,
}

/// Customer Priority (Sales / Support importance)
/// Purpose: How important the customer is to the business (used by sales & support).
enum CustomerPriority {
  low, // Small customer, minimal business impact
  medium, // Regular customer, standard attention
  high, // Important customer, more attention, faster support
  critical, // Strategic account, top priority, dedicated account manager
}

/// Customer Segment (Marketing / Analytics)
/// Purpose: Marketing / analytical grouping (often dynamic).
enum CustomerSegment {
  newCustomer,
  returningCustomer,
  highValue,
  priceSensitive,
  loyal,
  atRisk,
  churned,
}

/// Customer Lifecycle Stage
enum CustomerLifecycle { lead, prospect, onboarded, active, dormant, churned }

extension LeadSourceExtension on LeadSource {
  String get getName => EnumUtil<LeadSource>(this).getName;

  String get getLabel => EnumUtil<LeadSource>(this).getLabel;
}

extension MarketingPrefExtension on CommunicationPreferences {
  String get getName => EnumUtil<CommunicationPreferences>(this).getName;
  String get getLabel => EnumUtil<CommunicationPreferences>(this).getLabel;
}

extension CustomerLifecycleExtension on CustomerLifecycle {
  String get getName => EnumUtil<CustomerLifecycle>(this).getName;

  String get getLabel => EnumUtil<CustomerLifecycle>(this).getLabel;
}

extension CustomerSegmentExtension on CustomerSegment {
  String get getName => EnumUtil<CustomerSegment>(this).getName;

  String get getLabel => EnumUtil<CustomerSegment>(this).getLabel;
}

extension CustomerPriorityExtension on CustomerPriority {
  String get getName => EnumUtil<CustomerPriority>(this).getName;

  String get getLabel => EnumUtil<CustomerPriority>(this).getLabel;
}

extension CustomerCategoryExtension on CustomerCategory {
  /// [getName] Get the specific Enum Name (e.g. "realEstate")
  String get getName => EnumUtil<CustomerCategory>(this).getName;

  /// Returns a user-friendly label (e.g. "real estate")
  String get getLabel => EnumUtil<CustomerCategory>(this).getLabel;
}

extension CustomerTypeExtension on CustomerType {
  String get getName => EnumUtil<CustomerType>(this).getName;

  String get getLabel => EnumUtil<CustomerType>(this).getLabel;
}

extension CustomerStatusExtension on CustomerStatus {
  String get getName => EnumUtil<CustomerStatus>(this).getName;

  String get getLabel => EnumUtil<CustomerStatus>(this).getLabel;
}

class CrmCustomerUtil {
  // ===================== Marketing Preferences =====================
  static bool isCommunicationPrefs(String value) =>
      EnumUtil.isValid<CommunicationPreferences>(
        CommunicationPreferences.values,
        value,
        false,
      );

  static CommunicationPreferences marketingPrefsFromString(String? value) =>
      EnumUtil.fromString<CommunicationPreferences>(
        CommunicationPreferences.values,
        value,
      );

  static List<String> marketingPrefsList([bool includeHeader = true]) {
    final label = includeHeader ? 'marketing preferences' : '';
    return EnumUtil.toStringList<CommunicationPreferences>(
      CommunicationPreferences.values,
      label,
    );
  }

  // ===================== Lead Source =====================
  static bool isLeadSource(String value) =>
      EnumUtil.isValid<LeadSource>(LeadSource.values, value, false);

  static LeadSource leadSourceFromString(String? value) =>
      EnumUtil.fromString<LeadSource>(LeadSource.values, value);

  static List<String> leadSourceList([bool includeHeader = true]) {
    final label = includeHeader ? 'lead source' : '';
    return EnumUtil.toStringList<LeadSource>(LeadSource.values, label);
  }

  // ===================== Customer Status =====================
  /// Check if type is valid.
  static bool isStatus(String value) =>
      EnumUtil.isValid<CustomerStatus>(CustomerStatus.values, value, false);

  /// [fromString] Converts String/Label to enum value.
  static CustomerStatus statusFromString(String? value) =>
      EnumUtil.fromString<CustomerStatus>(CustomerStatus.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> statusList([bool includeHeader = true]) {
    final label = includeHeader ? 'customer status' : '';
    return EnumUtil.toStringList<CustomerStatus>(CustomerStatus.values, label);
  }

  // ===================== Customer Type =====================
  static bool isType(String value) =>
      EnumUtil.isValid<CustomerType>(CustomerType.values, value, false);

  static CustomerType typeFromString(String? value) =>
      EnumUtil.fromString<CustomerType>(CustomerType.values, value);

  static List<String> typeList([bool includeHeader = true]) {
    final label = includeHeader ? 'customer type' : '';
    return EnumUtil.toStringList<CustomerType>(CustomerType.values, label);
  }

  // ===================== Customer Category =====================
  static bool isCategory(String value) =>
      EnumUtil.isValid<CustomerCategory>(CustomerCategory.values, value, false);

  static CustomerCategory categoryFromString(String? value) =>
      EnumUtil.fromString<CustomerCategory>(CustomerCategory.values, value);

  static List<String> categoryList([bool includeHeader = true]) {
    final label = includeHeader ? 'customer category' : '';
    return EnumUtil.toStringList<CustomerCategory>(
      CustomerCategory.values,
      label,
    );
  }

  // ===================== Priority =====================
  static bool isValidPriority(String value) =>
      EnumUtil.isValid<CustomerPriority>(CustomerPriority.values, value, false);

  static CustomerPriority priorityFromString(String? value) =>
      EnumUtil.fromString<CustomerPriority>(CustomerPriority.values, value);

  static List<String> priorityList([bool includeHeader = true]) {
    final label = includeHeader ? 'customer priority' : '';
    return EnumUtil.toStringList<CustomerPriority>(
      CustomerPriority.values,
      label,
    );
  }

  // ===================== Segment =====================
  static bool isSegment(String value) =>
      EnumUtil.isValid<CustomerSegment>(CustomerSegment.values, value, false);

  static CustomerSegment segmentFromString(String? value) =>
      EnumUtil.fromString<CustomerSegment>(CustomerSegment.values, value);

  static List<String> segmentList([bool includeHeader = true]) {
    final label = includeHeader ? 'customer segment' : '';
    return EnumUtil.toStringList<CustomerSegment>(
      CustomerSegment.values,
      label,
    );
  }

  // ===================== Lifecycle =====================
  static bool isLifecycle(String value) => EnumUtil.isValid<CustomerLifecycle>(
    CustomerLifecycle.values,
    value,
    false,
  );

  static CustomerLifecycle lifecycleFromString(String? value) =>
      EnumUtil.fromString<CustomerLifecycle>(CustomerLifecycle.values, value);

  static List<String> lifecycleList([bool includeHeader = true]) {
    final label = includeHeader ? 'customer lifecycle' : '';
    return EnumUtil.toStringList<CustomerLifecycle>(
      CustomerLifecycle.values,
      label,
    );
  }
}
