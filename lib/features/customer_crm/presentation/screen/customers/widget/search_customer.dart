import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/customer_crm/data/data_sources/remote/get_customers.dart';
import 'package:assign_erp/features/customer_crm/data/models/customer_model.dart';
import 'package:flutter/material.dart';

/// Search Customer to place an Order [SearchCustomer]
class SearchCustomer extends StatefulWidget {
  final bool allowManualEntry;
  final String? initialValue;
  final Function(String, String) onChanged;

  const SearchCustomer({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.allowManualEntry = false,
  });

  @override
  State<SearchCustomer> createState() => _SearchCustomerState();
}

class _SearchCustomerState extends State<SearchCustomer> {
  String? _initialValue;
  bool _isNotFound = false;
  Customer? _customer;

  void _toggleManualEntry([bool value = true]) {
    if (mounted) setState(() => _isNotFound = value);
  }

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomers());
  }

  Future _loadCustomers({String? filter}) async {
    final initial = widget.initialValue ?? '';
    final customers = await GetAllCustomers.byAnyTerm(filter ?? initial);
    if (initial.hasValue && customers.hasValue) {
      setState(() => _customer = customers.first);
    }
    return customers;
  }

  get _allowManualEntry => widget.allowManualEntry;

  @override
  Widget build(BuildContext context) {
    // If not found & allowManual = true, show manual entry field
    return _isNotFound && _allowManualEntry
        ? _buildManualEntryField(context)
        : _buildDropdown(context);
  }

  AsyncSearchDropdown<Customer> _buildDropdown(BuildContext context) {
    return AsyncSearchDropdown<Customer>(
      selectedItem: _customer,
      labelText: 'Select Customer...',
      asyncItems: (String filter, loadProps) async =>
          await _loadCustomers(filter: filter),
      filterFn: (customer, filter) => _filterCustomer(filter, customer),
      itemAsString: (customer) => customer.itemAsString,
      onChanged: (customer) =>
          widget.onChanged(customer!.customerId, customer.name),
      validator: (customer) => customer == null ? 'Select customer' : null,
      onNoDataFound: () {
        if (_allowManualEntry) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _handleNoDataFound(context),
          );
        }
      },
    );
  }

  bool _filterCustomer(String filter, Customer customer) {
    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = customer.filterByAny(term);
    if ((!matches && filter.isNotEmpty) && _allowManualEntry) {
      _toggleManualEntry();
    }
    return matches;
  }

  Widget _buildManualEntryField(BuildContext context) {
    return CustomTextField(
      onChanged: (value) => widget.onChanged.call(value, value),
      keyboardType: TextInputType.text,
      inputDecoration: InputDecoration(
        labelText: 'Customer name',
        suffixIcon: Padding(
          padding: const EdgeInsets.all(2.0),
          child: context.iconButton(
            Icons.arrow_back,
            tooltip: 'Back to customer search',
            onPressed: () => _toggleManualEntry(false),
            bgColor: kGrayColor,
          ),
        ),
      ),
    );
  }

  Future<void> _handleNoDataFound(BuildContext context) async {
    final shouldEnterManually = await context.confirmAction<bool>(
      const Text('Do you want to enter it manually?'),
      title: 'Customer not found',
    );

    if (context.mounted && shouldEnterManually) {
      _toggleManualEntry();
    }
  }
}
