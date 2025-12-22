import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/customer_crm/data/models/customer_model.dart';
import 'package:assign_erp/features/customer_crm/presentation/bloc/create_acc/customer_acc_bloc.dart';
import 'package:assign_erp/features/customer_crm/presentation/bloc/customer_bloc.dart';
import 'package:assign_erp/features/customer_crm/presentation/screen/customers/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateCustomerForm<T> on BuildContext {
  Future<void> openUpdateCustomer({required Customer customer}) =>
      openBottomSheet(
        isExpand: false,
        child: BottomSheetScaffold(
          title: 'Edit Customer',
          subtitle: customer.name,
          body: _UpdateCustomerBody(customer: customer),
        ),
      );
}

class _UpdateCustomerBody extends StatefulWidget {
  final Customer customer;

  const _UpdateCustomerBody({required this.customer});

  @override
  State<_UpdateCustomerBody> createState() => _UpdateCustomerBodyState();
}

class _UpdateCustomerBodyState extends State<_UpdateCustomerBody> {
  Customer get _customer => widget.customer;

  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedBirthday;

  late final _customerIdController = TextEditingController(
    text: _customer.customerId,
  );
  late final _nameController = TextEditingController(text: _customer.name);
  late final _emailController = TextEditingController(text: _customer.email);
  late final _phoneController = TextEditingController(text: _customer.phone);
  late final _altPhoneController = TextEditingController(
    text: _customer.altPhone,
  );
  late final _addressController = TextEditingController(
    text: _customer.address,
  );
  late final _companyNameController = TextEditingController(
    text: _customer.companyName,
  );

  @override
  void dispose() {
    _altPhoneController.dispose();
    _customerIdController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final item = _customer.copyWith(
        storeNumber: _customer.storeNumber,
        name: _nameController.text,
        birthDay: _selectedBirthday ?? _customer.birthDay,
        customerId: _customerIdController.text,
        phone: _phoneController.text,
        altPhone: _altPhoneController.text,
        email: _emailController.text,
        address: _addressController.text,
        companyName: _companyNameController.text,
        createdBy: _customer.createdBy,
        updatedBy: context.employee!.fullName,
      );

      /// Update Customer
      context.read<CustomerAccountBloc>().add(
        UpdateCustomer<Customer>(documentId: _customer.id, data: item),
      );

      _formKey.currentState!.reset();
      context.showAlertOverlay(
        'Customer with ID: ${_customer.id} has been successfully updated',
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CustomerNameAndBirthDayInput(
          nameController: _nameController,
          initialDate: _customer.getBirthDay,
          onDateChanged: (t) => setState(() => _selectedBirthday = t),
          onNameChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        PhoneAndAltPhoneInput(
          altPhoneController: _altPhoneController,
          phoneController: _phoneController,
          onPhoneChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onAltPhoneChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        EmailAndCompanyNameInput(
          emailController: _emailController,
          companyNameController: _companyNameController,
          onCompanyNameChanged: (t) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onEmailChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        AddressTextField(
          addressController: _addressController,
          onAddressChanged: (v) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(onPressed: _onSubmit),
      ],
    );
  }
}
