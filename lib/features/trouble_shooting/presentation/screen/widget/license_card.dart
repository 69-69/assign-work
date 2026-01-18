import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/subscription_licenses_enum.dart';
import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/nav/tab/entitlement_selector.dart';
import 'package:assign_erp/core/widgets/nav/tab/entitlement_tab_view.dart';
import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/license_model.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/license_tab_content_model.dart';
import 'package:flutter/material.dart';

final _tabContent = [
  LicenseTabContent(
    label: 'License',
    icon: Icons.security,
    displayName: licenseDisplayName,
    licenses: subscriptionLicenses,
    highRiskLicenses: highRiskLicenses,
  ),
  LicenseTabContent(
    label: 'Addons',
    icon: Icons.extension,
    displayName: addonsDisplayName,
    licenses: addonsLicenses,
  ),
];

class LicenseCard extends StatelessWidget {
  final void Function(Set<License>, String) onSelectedFunc;
  final Set<License>? initialLicenses;

  const LicenseCard({
    super.key,
    required this.onSelectedFunc,
    this.initialLicenses,
  });

  @override
  Widget build(BuildContext context) {
    return _buildPermission(context);
  }

  _buildPermission(BuildContext context) {
    return SizedBox(
      height: context.screenHeight * 0.6,
      child: EntitlementTabView(
        tabs: _tabContent
            .map(
              (tab) => CustomTabModel(
                label: tab.label,
                icon: tab.icon,
                tooltip: tab.displayName,
              ),
            )
            .toList(),
        isVerticalTab: true,
        children: _buildEntitlementSelectors(context, _tabContent),
      ),
    );
  }

  License _toValue(AccessControl ac) =>
      License(module: ac.module, license: ac.accessName);

  List<Widget> _buildEntitlementSelectors(
    BuildContext context,
    List<LicenseTabContent> tabs,
  ) {
    return tabs.map((tab) {
      return EntitlementSelector<License>(
        entitlementType: 'license',
        displayName: tab.displayName,
        entitlements: tab.licenses,
        initialEntitlements: initialLicenses,
        toValue: (access) => _toValue(access),
        onSelected: (licenses, module) => onSelectedFunc(licenses, module),
        sectionColor: kPrimaryAccentColor,
        highRiskAccesses: tab.highRiskLicenses,
      );
    }).toList();
  }
}
