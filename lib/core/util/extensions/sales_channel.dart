import 'package:assign_erp/core/util/enum_util.dart';

enum SalesChannel {
  // In-Store Sales: Transactions happening in physical retail locations (brick-and-mortar stores).
  inStore,

  // Online Sales: Transactions made through e-commerce websites, online stores, or marketplaces.
  online,

  // POS: Transactions made both in-store and mobile through Point of Sale systems.
  pos,

  // Wholesale / Distributor: Sales made in bulk to resellers or distributors who then sell to other businesses or consumers.
  wholesale,

  // Direct Sales: Sales made directly through sales representatives, typically in a B2B context.
  directSales,

  // Channel Partners / Resellers: Third-party companies or individuals who sell your products as part of a partnership.
  channelPartners,

  // Franchise: Sales through franchises, where other businesses operate under your brand and sell your products.
  franchise,

  // Mobile Sales: Sales conducted via mobile apps or platforms, including in-app purchases.
  mobileSales,

  // Subscription Service: Sales through a recurring, subscription-based model where customers receive regular deliveries of products/services.
  subscriptionService,

  // Tele-sales / Call Centers: Sales via phone calls, often used for marketing or customer outreach.
  teleSales,

  // Pop-up Shops / Events: Temporary sales locations or booths at events, fairs, or markets.
  popupShops,

  // B2B Sales (Corporate): Sales made directly to other businesses, typically for bulk or enterprise-level products/services.
  b2bSales,

  // Affiliate / Referral Sales: Sales made through affiliate marketing or referral programs, where third parties promote products for a commission.
  affiliateSales,

  // Social Media Sales: Sales via social platforms like Instagram, Facebook, or TikTok, including social commerce features.
  socialMedia,
}

extension SalesChannelExtension on SalesChannel {
  /// [getName] Get the specific Enum Name (e.g. "material")
  String get getName => EnumUtil<SalesChannel>(this).getName;

  /// Returns a user-friendly label (e.g. "social media")
  String get getLabel => EnumUtil<SalesChannel>(this).getLabel;
}

class SalesChannelUtil {
  /// Check if type is valid.
  static bool isExist(String type) =>
      EnumUtil.isValid<SalesChannel>(SalesChannel.values, type, false);

  /// [fromString] Converts String/Label to enum value.
  static SalesChannel fromString(String? value) =>
      EnumUtil.fromString<SalesChannel>(SalesChannel.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'sales channel' : '';
    return EnumUtil.toStringList<SalesChannel>(SalesChannel.values, label);
  }
}
