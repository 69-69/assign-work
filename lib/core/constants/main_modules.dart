import 'package:flutter/material.dart';

enum MainModuleId {
  pos,
  crm,
  agent,
  invent,
  system,
  trouble,
  guide,
  sales,
  support,
  procure,
  warehouse,
}

// Updated map with tuple-like structure (label and icon)
const Map<MainModuleId, ({String label, IconData icon})> mainModules = {
  MainModuleId.pos: (label: 'POS', icon: Icons.point_of_sale),
  MainModuleId.crm: (label: 'CRM', icon: Icons.group),
  MainModuleId.agent: (label: 'Agent', icon: Icons.real_estate_agent_outlined),
  MainModuleId.invent: (label: 'Inventory', icon: Icons.inventory_sharp),
  MainModuleId.system: (
    label: 'System . Admin',
    icon: Icons.admin_panel_settings,
  ),
  MainModuleId.trouble: (label: 'Troubleshoot', icon: Icons.troubleshoot),
  MainModuleId.guide: (label: 'User . Guide', icon: Icons.library_books),
  MainModuleId.sales: (
    label: 'Sales & Distribution',
    icon: Icons.local_shipping,
  ),
  MainModuleId.support: (label: 'Support', icon: Icons.support_agent),
  MainModuleId.procure: (
    label: 'Procurement & Supplier',
    icon: Icons.add_shopping_cart,
  ),
  MainModuleId.warehouse: (label: 'Warehouse', icon: Icons.warehouse),
};

extension MainModuleExtension on MainModuleId {
  String get getLabel => mainModules[this]?.label ?? '';

  IconData get getIcon => mainModules[this]?.icon ?? Icons.help;
}

class MainModulesHelper<T> {
  /// Convert enum values to a list of labels and icons
  static List<Set<({IconData icon, String label})>> toStringList({
    List<MainModuleId>? keysToExclude,
  }) {
    return mainModules.entries
        .where((entry) => !(keysToExclude?.contains(entry.key) ?? false))
        .map((entry) => {(label: entry.value.label, icon: entry.value.icon)})
        .toList();
  }
}
