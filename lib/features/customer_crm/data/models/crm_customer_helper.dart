import 'package:assign_erp/core/util/enum_helper.dart';

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

extension LeadSourceExt on LeadSource {
  String get getName => EnumHelper<LeadSource>(this).getName;

  String get getLabel => EnumHelper<LeadSource>(this).getLabel;
}

extension MarketingPreferencesExt on CommunicationPreferences {
  String get getName => EnumHelper<CommunicationPreferences>(this).getName;
  String get getLabel => EnumHelper<CommunicationPreferences>(this).getLabel;
}

extension CustomerLifecycleExt on CustomerLifecycle {
  String get getName => EnumHelper<CustomerLifecycle>(this).getName;

  String get getLabel => EnumHelper<CustomerLifecycle>(this).getLabel;
}

extension CustomerSegmentExt on CustomerSegment {
  String get getName => EnumHelper<CustomerSegment>(this).getName;

  String get getLabel => EnumHelper<CustomerSegment>(this).getLabel;
}

extension CustomerPriorityExt on CustomerPriority {
  String get getName => EnumHelper<CustomerPriority>(this).getName;

  String get getLabel => EnumHelper<CustomerPriority>(this).getLabel;
}

extension CustomerCategoryExt on CustomerCategory {
  /// [getName] Get the specific Enum Name (e.g. "realEstate")
  String get getName => EnumHelper<CustomerCategory>(this).getName;

  /// Returns a user-friendly label (e.g. "real estate")
  String get getLabel => EnumHelper<CustomerCategory>(this).getLabel;
}

extension CustomerTypeExt on CustomerType {
  String get getName => EnumHelper<CustomerType>(this).getName;

  String get getLabel => EnumHelper<CustomerType>(this).getLabel;
}

extension CustomerStatusExt on CustomerStatus {
  String get getName => EnumHelper<CustomerStatus>(this).getName;

  String get getLabel => EnumHelper<CustomerStatus>(this).getLabel;
}

class CrmCustomerHelper {
  // ===================== Marketing Preferences =====================
  static bool isCommunicationPrefs(String value) =>
      EnumHelper.isValid<CommunicationPreferences>(
        CommunicationPreferences.values,
        value,
        false,
      );

  static CommunicationPreferences marketingPrefsFromString(String? value) =>
      EnumHelper.fromString<CommunicationPreferences>(
        CommunicationPreferences.values,
        value,
      );

  static List<String> marketingPrefsList([bool includeHeader = true]) {
    final label = includeHeader ? 'marketing preferences' : '';
    return EnumHelper.toStringList<CommunicationPreferences>(
      CommunicationPreferences.values,
      label,
    );
  }

  // ===================== Lead Source =====================
  static bool isLeadSource(String value) =>
      EnumHelper.isValid<LeadSource>(LeadSource.values, value, false);

  static LeadSource leadSourceFromString(String? value) =>
      EnumHelper.fromString<LeadSource>(LeadSource.values, value);

  static List<String> leadSourceList([bool includeHeader = true]) {
    final label = includeHeader ? 'lead source' : '';
    return EnumHelper.toStringList<LeadSource>(LeadSource.values, label);
  }

  // ===================== Customer Status =====================
  /// Check if type is valid.
  static bool isStatus(String value) =>
      EnumHelper.isValid<CustomerStatus>(CustomerStatus.values, value, false);

  /// [fromString] Converts String/Label to enum value.
  static CustomerStatus statusFromString(String? value) =>
      EnumHelper.fromString<CustomerStatus>(CustomerStatus.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> statusList([bool includeHeader = true]) {
    final label = includeHeader ? 'customer status' : '';
    return EnumHelper.toStringList<CustomerStatus>(
      CustomerStatus.values,
      label,
    );
  }

  // ===================== Customer Type =====================
  static bool isType(String value) =>
      EnumHelper.isValid<CustomerType>(CustomerType.values, value, false);

  static CustomerType typeFromString(String? value) =>
      EnumHelper.fromString<CustomerType>(CustomerType.values, value);

  static List<String> typeList([bool includeHeader = true]) {
    final label = includeHeader ? 'customer type' : '';
    return EnumHelper.toStringList<CustomerType>(CustomerType.values, label);
  }

  // ===================== Customer Category =====================
  static bool isCategory(String value) => EnumHelper.isValid<CustomerCategory>(
    CustomerCategory.values,
    value,
    false,
  );

  static CustomerCategory categoryFromString(String? value) =>
      EnumHelper.fromString<CustomerCategory>(CustomerCategory.values, value);

  static List<String> categoryList([bool includeHeader = true]) {
    final label = includeHeader ? 'customer category' : '';
    return EnumHelper.toStringList<CustomerCategory>(
      CustomerCategory.values,
      label,
    );
  }

  // ===================== Priority =====================
  static bool isValidPriority(String value) =>
      EnumHelper.isValid<CustomerPriority>(
        CustomerPriority.values,
        value,
        false,
      );

  static CustomerPriority priorityFromString(String? value) =>
      EnumHelper.fromString<CustomerPriority>(CustomerPriority.values, value);

  static List<String> priorityList([bool includeHeader = true]) {
    final label = includeHeader ? 'customer priority' : '';
    return EnumHelper.toStringList<CustomerPriority>(
      CustomerPriority.values,
      label,
    );
  }

  // ===================== Segment =====================
  static bool isSegment(String value) =>
      EnumHelper.isValid<CustomerSegment>(CustomerSegment.values, value, false);

  static CustomerSegment segmentFromString(String? value) =>
      EnumHelper.fromString<CustomerSegment>(CustomerSegment.values, value);

  static List<String> segmentList([bool includeHeader = true]) {
    final label = includeHeader ? 'customer segment' : '';
    return EnumHelper.toStringList<CustomerSegment>(
      CustomerSegment.values,
      label,
    );
  }

  // ===================== Lifecycle =====================
  static bool isLifecycle(String value) =>
      EnumHelper.isValid<CustomerLifecycle>(
        CustomerLifecycle.values,
        value,
        false,
      );

  static CustomerLifecycle lifecycleFromString(String? value) =>
      EnumHelper.fromString<CustomerLifecycle>(CustomerLifecycle.values, value);

  static List<String> lifecycleList([bool includeHeader = true]) {
    final label = includeHeader ? 'customer lifecycle' : '';
    return EnumHelper.toStringList<CustomerLifecycle>(
      CustomerLifecycle.values,
      label,
    );
  }
}
