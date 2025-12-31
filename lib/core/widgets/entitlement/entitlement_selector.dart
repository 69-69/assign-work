import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/form/custom_radio_tile.dart';
import 'package:assign_erp/core/widgets/form/custom_switch_tile.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';
import 'package:flutter/material.dart';

class EntitlementSelector<T> extends StatefulWidget {
  final List<AccessControl> entitlements;
  final Set<T>? initialEntitlements;
  final void Function(Set<T>, String module) onSelected;
  final String displayName;
  final Color? sectionColor;
  final bool selectAllByDefault;
  final T Function(AccessControl) toValue;
  final String entitlementType;

  /// [highRiskAccesses] Unique Accesses that trigger a warning dialog,
  /// prompting the admin to reconsider before assigning them.
  final List<String>? highRiskAccesses;

  const EntitlementSelector({
    super.key,
    required this.entitlements,
    required this.onSelected,
    required this.displayName,
    this.sectionColor,
    this.initialEntitlements,
    this.selectAllByDefault = false,
    required this.toValue,
    this.entitlementType = 'Permissions',
    this.highRiskAccesses,
  });

  @override
  State<EntitlementSelector<T>> createState() => _EntitlementSelectorState<T>();
}

class _EntitlementSelectorState<T> extends State<EntitlementSelector<T>> {
  late List<bool> _selectedStates;
  AccessMode _mode = AccessMode.select;

  List<AccessControl> get _entitlements => widget.entitlements;

  Set<T>? get _initialEntitlements => widget.initialEntitlements?.cast<T>();

  late List<AccessControl> _filteredEntitlements;
  final TextEditingController _searchController = TextEditingController();

  String get _entitlementType => widget.entitlementType;

  String get _displayName => '${widget.displayName.toTitle} $_entitlementType';

  String get _subTitle => _entitlementType.isEmpty ? 'license' : 'role';

  List<String> get _keywords => widget.highRiskAccesses ?? [];

  @override
  void initState() {
    super.initState();
    _initSelectedStates();

    _initFilter();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelected(_getSelectedValues(), '');
    });
  }

  void _initSelectedStates() {
    if ((_initialEntitlements == null || _initialEntitlements!.isEmpty) &&
        widget.selectAllByDefault) {
      // New role: select all by default
      _selectedStates = List.filled(_entitlements.length, true);
    } else {
      // Existing role: map from stored T (RolePermissions/<SubscriptionLicense>)
      _selectedStates = _entitlements.map((entitlement) {
        final mapped = widget.toValue(entitlement);
        return _initialEntitlements?.contains(mapped) ?? false;
      }).toList();
    }
  }

  void _updateAllEntitlements(bool enable) {
    setState(
      () => _selectedStates = List.filled(_selectedStates.length, enable),
    );
  }

  void _initFilter() {
    _filteredEntitlements = List.from(_entitlements);

    _searchController.addListener(
      () => _filterEntitlements(_searchController.text),
    );
  }

  void _filterEntitlements(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredEntitlements = List.from(_entitlements);
      } else {
        final q = query.toLowerAll;
        _filteredEntitlements = _entitlements.where((item) {
          return item.title.toLowerAll.contains(q) ||
              item.description.toLowerAll.contains(q);
        }).toList();
      }
    });
  }

  Set<T> _getSelectedValues() {
    final selected = <T>{};
    for (int i = 0; i < _selectedStates.length; i++) {
      if (_selectedStates[i]) {
        final item = _entitlements[i];

        selected.add(widget.toValue(item));
        // widget.toValue(module: item.module, permission: item.accessName),
      }
    }
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    final selectedLength = _getSelectedValues().length;
    final grouped = _groupBy(
      _filteredEntitlements,
      (AccessControl p) => p.module,
    );

    return Column(
      children: [
        Text(
          "$_displayName ${selectedLength > 0 ? "($selectedLength)" : ""}",
          // ad selected length
          textAlign: TextAlign.center,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        CustomRadioList<AccessMode>(
          groupValue: _mode,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _mode = value;
              _updateAllEntitlements(value == AccessMode.allowAll);
              widget.onSelected(_getSelectedValues(), '');
            });
          },
          options: [
            CustomRadioModel<AccessMode>(
              value: AccessMode.allowAll,
              title: Text("Allow all $_displayName for this $_subTitle"),
            ),
            CustomRadioModel<AccessMode>(
              value: AccessMode.select,
              title: Text("Select specific $_displayName for this $_subTitle"),
            ),
          ],
        ),

        const SizedBox(height: 6),
        FilterEntitlements(controller: _searchController, title: _subTitle),
        const SizedBox(height: 6),

        // Entitlement Toggles
        Expanded(child: _buildListView(grouped)),
      ],
    );
  }

  ListView _buildListView(Map<String, List<AccessControl>> grouped) {
    return ListView(
      primary: false,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            _ModuleName(name: entry.key, sectionColor: widget.sectionColor),

            ...entry.value.map((AccessControl item) {
              final index = _entitlements.indexOf(item);

              return _SwitchListCard(
                item: item,
                isSelected: _selectedStates[index],
                onChanged: _mode == AccessMode.select
                    ? (value) async {
                        final shouldProceed = await _shouldProceedWithToggle(
                          item,
                          value,
                        );
                        if (!shouldProceed) return;

                        setState(() => _selectedStates[index] = value);
                        widget.onSelected(_getSelectedValues(), item.module);
                        // _printLicenses(); // ✅ log current state
                      }
                    : null,
              );
            }),
            HorizontalDivider(width: 0.8),
          ],
        );
      }).toList(),
    );
  }

  Future<bool> _shouldProceedWithToggle(
    AccessControl access,
    bool isEnabled,
  ) async {
    if (_keywords == null || !isEnabled) {
      return true; // Only confirm on enabling
    }

    final regExp = RegExp(
      r'\b(' + _keywords.join('|') + r')\b',
      caseSensitive: false,
    );

    if (regExp.hasMatch(access.accessName.toLowerAll)) {
      final label = access.accessLabel.toUpperAll;
      final title = _entitlementType.isEmpty ? 'License' : _entitlementType;
      final confirm = await context.confirmAction(
        Text(
          'Are you sure you want to toggle this $title? This is for $label only.',
        ),
      );
      return confirm;
    }

    return true; // No keyword matched, proceed normally
  }

  // Grouping utility
  Map<K, List<A>> _groupBy<A, K>(List<A> list, K Function(A) keySelector) {
    final Map<K, List<A>> map = {};
    for (final item in list) {
      final key = keySelector(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  /*void _printLicenses() {
    debugPrint("🔘 Mode: $_mode");
    debugPrint("✅ Selected States: $_selectedStates");
    debugPrint("🎯 Selected Licenses: ${_getSelectedValues()}");
  }*/

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ModuleName extends StatelessWidget {
  final String name;
  final Color? sectionColor;

  const _ModuleName({required this.name, this.sectionColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        name.toUpperAll,
        textAlign: TextAlign.center,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: sectionColor ?? context.mainPrimaryColor,
        ),
      ),
    );
  }
}

class _SwitchListCard extends StatelessWidget {
  final ValueChanged<bool>? onChanged;
  final AccessControl item;
  final bool isSelected;

  const _SwitchListCard({
    required this.item,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomSwitchTile(
      title: item.title,
      subtitle: item.description,
      isSelected: isSelected,
      onChanged: onChanged,
    );
  }
}

class FilterEntitlements extends StatelessWidget {
  const FilterEntitlements({
    super.key,
    required this.controller,
    this.title = 'permissions',
  });

  final String title;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      validator: (_) => null,
      keyboardType: TextInputType.none,
      inputDecoration: InputDecoration(
        filled: true,
        labelText: 'Search $title...',
        prefixIcon: Icon(Icons.search),
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6.0),
      ),
    );
  }
}

/*class _EntitlementRadioTile extends StatelessWidget {
  final String title;
  final AccessMode value;
  final AccessMode groupValue;
  final ValueChanged<AccessMode?> onChanged;

  const _EntitlementRadioTile({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.groupValue,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<AccessMode>.adaptive(
      dense: true,
      value: value,
      groupValue: groupValue,
      title: Text(title),
      onChanged: onChanged,
    );
  }
}*/
