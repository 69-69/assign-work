import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/contact_person_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/features/procurement/data/data_sources/remote/get_suppliers.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Search Suppliers [SearchSuppliers]
class SearchSuppliers extends StatefulWidget {
  final bool showContactPerson;
  final String? initialSupplier;
  final String? initialContactPerson;
  final void Function(String id)? onContactPersonChanged;
  final void Function(String id, String name) onSupplierChanged;

  const SearchSuppliers({
    super.key,
    this.showContactPerson = true,
    this.initialSupplier,
    this.initialContactPerson,
    this.onContactPersonChanged,
    required this.onSupplierChanged,
  });

  @override
  State<SearchSuppliers> createState() => _SearchSuppliersState();
}

class _SearchSuppliersState extends State<SearchSuppliers> {
  Supplier? _supplier;
  String? _initialSupplier;
  List<ContactPerson>? _selectedContactPersons;

  @override
  void initState() {
    super.initState();
    _initialSupplier = widget.initialSupplier;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSuppliers());
  }

  Future _loadSuppliers({String? filter}) async {
    final initial = widget.initialSupplier ?? '';
    final filterBy = filter.isNullOrEmpty ? initial : filter;
    final suppliers = await GetSuppliers.byAnyTerm(filterBy);
    if (initial.isNotNullNorEmpty && suppliers.isNotNullNorEmpty) {
      setState(() => _supplier = suppliers.first);
    }
    return suppliers;
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      children: [
        _buildSuppliersDropdown(context),
        // Conditionally render contact persons dropdown based on `showContactPerson`
        if (widget.showContactPerson &&
            _selectedContactPersons.isNotNullNorEmpty) ...{
          _buildContactPersonsDropdown(context),
        },
      ],
    );
  } // eclarson@smu.edu

  /// Suppliers [_buildSuppliersDropdown]
  AsyncSearchDropdown<Supplier> _buildSuppliersDropdown(BuildContext context) {
    return AsyncSearchDropdown<Supplier>(
      selectedItem: _supplier,
      labelText: 'Select Supplier...',
      asyncItems: (String filter, _) async =>
          await _loadSuppliers(filter: filter),
      filterFn: (supplier, filter) =>
          _filterSupplier(filter, supplier, context),
      itemAsString: (supplier) => supplier.itemAsString,
      onChanged: (supplier) {
        setState(() => _selectedContactPersons = supplier?.contactPersons);

        widget.onSupplierChanged(supplier!.id, supplier.name);
      },
      validator: (supplier) => supplier == null ? 'Supplier is required' : null,
      onNoDataFound: () {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handleNoDataFound(context),
        );
      },
    );
  }

  /// Supplier Contact Persons [_buildContactPersonsDropdown]
  Widget _buildContactPersonsDropdown(BuildContext context) {
    final label = 'Supplier Contact Person';
    final initial = _selectedContactPersons?.firstWhereOrNull(
      (person) => person.id == widget.initialContactPerson,
    );

    return StaticDropdown<ContactPerson>(
      label: label,
      items: [
        ContactPerson.empty(name: label),
        ...?_selectedContactPersons,
      ],
      initialValue: initial,
      getDisplayText: (person) => person.itemAsString,
      onChanged: (person) {
        final id = person?.id;
        if (id.isNotNullNorEmpty) {
          widget.onContactPersonChanged?.call(id!.trim());
        }
      },
    );
  }

  bool _filterSupplier(String filter, Supplier supplier, BuildContext context) {
    final term = filter.isEmpty ? (_initialSupplier ?? '') : filter;
    final matches = supplier.filterByAny(term);
    if (!matches && filter.isNotEmpty) _handleNoDataFound(context);
    return matches;
  }

  Future<void> _handleNoDataFound(BuildContext context) async {
    final isNewSupplier = await context.confirmAction<bool>(
      const Text('Do you want to create a new supplier manually?'),
      title: 'Supplier not found',
    );

    if (context.mounted && isNewSupplier) {
      context.goNamed(
        RouteNames.productConfig,
        pathParameters: {'openTab': '3'},
      );
    }
  }
}
