import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/subscription_licenses_enum.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/entitlement/entitlement_selector.dart';
import 'package:assign_erp/core/widgets/entitlement/entitlement_tab_view.dart';
import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';
import 'package:assign_erp/features/access_control/presentation/cubit/access_control_cubit.dart';
import 'package:assign_erp/features/agent/data/permission/agent_permission.dart';
import 'package:assign_erp/features/customer_crm/data/permission/crm_permission.dart';
import 'package:assign_erp/features/inventory_ims/data/permission/inventory_permission.dart';
import 'package:assign_erp/features/pos_system/data/permission/pos_permission.dart';
import 'package:assign_erp/features/procurement/data/permission/procurement_permission.dart';
import 'package:assign_erp/features/setup/data/models/permission_model.dart';
import 'package:assign_erp/features/setup/data/models/tab_content_model.dart';
import 'package:assign_erp/features/setup/data/permission/setup_permission.dart';
import 'package:assign_erp/features/trouble_shooting/data/permission/trouble_shoot_permission.dart';
import 'package:assign_erp/features/warehouse_wms/data/permission/warehouse_permission.dart';
import 'package:flutter/material.dart';

final _tabContent = [
  TabContent<SubscriptionLicenses>(
    label: 'IMS',
    icon: Icons.inventory_sharp,
    accessEnum: SubscriptionLicenses.inventory,
    displayName: inventoryDisplayName,
    permissions: inventoryPermissions,
  ),
  TabContent<SubscriptionLicenses>(
    label: 'PSM',
    icon: Icons.shopping_cart,
    accessEnum: SubscriptionLicenses.procurement,
    displayName: procurementDisplayName,
    permissions: procurementPermission,
  ),
  TabContent<SubscriptionLicenses>(
    label: 'POS',
    icon: Icons.point_of_sale,
    accessEnum: SubscriptionLicenses.pos,
    displayName: posDisplayName,
    permissions: posPermissions,
  ),
  TabContent<SubscriptionLicenses>(
    label: 'WMS',
    icon: Icons.warehouse,
    accessEnum: SubscriptionLicenses.warehouse,
    displayName: wmsDisplayName,
    permissions: warehousePermissions,
  ),
  TabContent<SubscriptionLicenses>(
    label: 'CRM',
    icon: Icons.group,
    accessEnum: SubscriptionLicenses.crm,
    displayName: crmDisplayName,
    permissions: crmPermissions,
  ),
  TabContent<SubscriptionLicenses>(
    label: 'Setup',
    icon: Icons.settings,
    displayName: setupDisplayName,
    permissions: setupPermissions,
  ),
  TabContent<SubscriptionLicenses>(
    label: 'Agent',
    icon: Icons.real_estate_agent_outlined,
    accessEnum: SubscriptionLicenses.agent,
    displayName: agentDisplayName,
    permissions: agentPermissions,
  ),
  TabContent<SubscriptionLicenses>(
    label: 'Trouble Shoot',
    icon: Icons.troubleshoot,
    accessEnum: SubscriptionLicenses.dev,
    displayName: tShootDisplayName,
    permissions: tShootPermission,
  ),
];

class PermissionCard extends StatelessWidget {
  final void Function(Set<Permission>, String) onSelectedFunc;
  final Set<Permission>? initialPermissions;

  const PermissionCard({
    super.key,
    required this.onSelectedFunc,
    this.initialPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return _buildPermission(context);
  }

  _buildPermission(BuildContext context) {
    // Filter tabs based on access/license
    final filteredTabs = _tabContent.where((tab) {
      if (tab.access == null) return true;
      return context.isLicensed(tab.access!); // Check access for licensed tabs
    }).toList();

    return SizedBox(
      height: context.screenHeight * 0.6,
      child: EntitlementTabView(
        tabs: filteredTabs
            .map(
              (tab) => {
                'label': tab.label,
                'icon': tab.icon,
                'tooltip': tab.displayName,
              },
            )
            .toList(),
        isVerticalTab: true,
        children: _buildEntitlementSelectors(context, filteredTabs),
      ),
    );
  }

  List<Widget> _buildEntitlementSelectors(
    BuildContext context,
    List<TabContent> filteredTabs,
  ) {
    return filteredTabs.map((tab) {
      // Only generate the selector if the tab is accessible based on the license
      if (tab.access != null && !context.isLicensed(tab.access!)) {
        return SizedBox.shrink(); // Skip if no access
      }

      // Return the EntitlementSelector widget
      return EntitlementSelector<Permission>(
        displayName: tab.displayName,
        entitlements: tab.permissions,
        initialEntitlements: initialPermissions,
        toValue: (access) => _toValue(access),
        onSelected: (permissions, module) =>
            onSelectedFunc(permissions, module),
        sectionColor: kPrimaryAccentColor,
      );
    }).toList();
  }

  Permission _toValue(AccessControl ac) =>
      Permission(module: ac.module, permission: ac.accessName);
}

/*final tabsLabels = [
  {'label': 'Agent', 'icon': Icons.real_estate_agent_outlined},
  {'label': 'POS', 'icon': Icons.point_of_sale},
  {'label': 'IMS', 'icon': Icons.inventory_sharp},
  {'label': 'CRM', 'icon': Icons.group},
  {'label': 'WMS', 'icon': Icons.warehouse},
  {'label': 'Setup', 'icon': Icons.settings},
];

class PermissionCard extends StatelessWidget {
  final void Function(String module, {required Set<Permission> permissions})
  onSelectedFunc;
  final Set<Permission>? initialPermissions;

  const PermissionCard({
    super.key,
    required this.onSelectedFunc,
    this.initialPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return _buildPermission(context);
  }

  _buildPermission(BuildContext context) {
    final hasLicense = context.isLicensed('steve');

    return SizedBox(
      height: context.screenHeight * 0.6,
      child: EntitlementTabView(
        tabs: tabsLabels,
        isVerticalTab: true,
        children: [
          EntitlementSelector<Permission>(
            displayName: agentDisplayName,
            entitlements: agentPermissions,
            initialEntitlements: initialPermissions,
            toValue: (access) => _toValue(access),
            onSelected: (perms) =>
                onSelectedFunc(agentDisplayName, permissions: perms),
            sectionColor: kPrimaryAccentColor,
          ),
          EntitlementSelector<Permission>(
            displayName: posDisplayName,
            entitlements: posPermissions,
            initialEntitlements: initialPermissions,
            toValue: (access) => _toValue(access),
            onSelected: (perms) =>
                onSelectedFunc(posDisplayName, permissions: perms),
            sectionColor: kPrimaryAccentColor,
          ),
          EntitlementSelector<Permission>(
            displayName: inventoryDisplayName,
            initialEntitlements: initialPermissions,
            entitlements: inventoryPermissionDetails,
            toValue: (access) => _toValue(access),
            onSelected: (perms) =>
                onSelectedFunc(inventoryDisplayName, permissions: perms),
            sectionColor: kPrimaryAccentColor,
          ),
          EntitlementSelector<Permission>(
            displayName: crmDisplayName,
            entitlements: crmPermissions,
            initialEntitlements: initialPermissions,
            toValue: (access) => _toValue(access),
            onSelected: (perms) =>
                onSelectedFunc(crmDisplayName, permissions: perms),
            sectionColor: kPrimaryAccentColor,
          ),
          EntitlementSelector<Permission>(
            displayName: wmsDisplayName,
            entitlements: warehousePermissions,
            initialEntitlements: initialPermissions,
            toValue: (access) => _toValue(access),
            onSelected: (perms) =>
                onSelectedFunc(wmsDisplayName, permissions: perms),
            sectionColor: kPrimaryAccentColor,
          ),
          EntitlementSelector<Permission>(
            displayName: setupDisplayName,
            entitlements: setupPermissions,
            initialEntitlements: initialPermissions,
            toValue: (access) => _toValue(access),
            onSelected: (perms) =>
                onSelectedFunc(setupDisplayName, permissions: perms),
            sectionColor: kPrimaryAccentColor,
          ),
        ],
      ),
    );
  }

  Permission _toValue(AccessControl ac) =>
      Permission(module: ac.module, permission: ac.accessName);
}*/
