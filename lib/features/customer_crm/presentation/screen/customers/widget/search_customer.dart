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
  final bool isPOS;
  final String? initialValue;
  final Function(String, String) onChanged;

  const SearchCustomer({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.isPOS = false,
  });

  @override
  State<SearchCustomer> createState() => _SearchCustomerState();
}

class _SearchCustomerState extends State<SearchCustomer> {
  bool _isNotFound = false;

  void _toggleManualEntry([bool value = true]) {
    if (mounted) setState(() => _isNotFound = value);
  }

  get _isPOS => widget.isPOS;

  @override
  Widget build(BuildContext context) {
    return _isNotFound && _isPOS
        ? _buildManualEntryField(context)
        : _buildDropdown(context);
  }

  AsyncSearchDropdown<Customer> _buildDropdown(BuildContext context) {
    return AsyncSearchDropdown<Customer>(
      labelText: (widget.initialValue ?? 'Select Customer...').toTitleCase,
      asyncItems: (String filter, loadProps) async =>
          await GetAllCustomers.byAnyTerm(filter),
      filterFn: (customer, filter) => _handleFilter(filter, customer),
      itemAsString: (customer) => customer.itemAsString,
      onChanged: (customer) =>
          widget.onChanged(customer!.customerId, customer.name),
      validator: (customer) => customer == null ? 'Add customer' : null,
      onNoDataFound: () {
        if (_isPOS) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _handleNoDataFound(context),
          );
        }
      },
    );
  }

  bool _handleFilter(String filter, Customer customer) {
    final term = filter.isEmpty ? (widget.initialValue ?? '') : filter;
    final isFound = customer.filterByAny(term);
    if ((!isFound && filter.isNotEmpty) && _isPOS) _toggleManualEntry();
    return isFound;
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
