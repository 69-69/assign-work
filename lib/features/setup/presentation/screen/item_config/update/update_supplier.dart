import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/setup/data/models/index.dart';
import 'package:assign_erp/features/setup/presentation/bloc/product_config/suppliers_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/setup/presentation/screen/item_config/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateSupplier on BuildContext {
  Future openUpdateSupplier({required Supplier supplier}) => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(
      title: 'Edit Supplier',
      subtitle: supplier.name.toTitle,
      body: _UpdateSupplierForm(supplier: supplier),
    ),
  );
}

class _UpdateSupplierForm extends StatefulWidget {
  final Supplier supplier;

  const _UpdateSupplierForm({required this.supplier});

  @override
  State<_UpdateSupplierForm> createState() => _UpdateSupplierFormState();
}

class _UpdateSupplierFormState extends State<_UpdateSupplierForm> {
  Supplier get _supplier => widget.supplier;

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: _supplier.name);
  late final _contactPersonNameController = TextEditingController(
    text: _supplier.contactPersonName,
  );
  late final _phoneController = TextEditingController(text: _supplier.phone);
  late final _emailController = TextEditingController(text: _supplier.email);
  late final _addressController = TextEditingController(
    text: _supplier.address,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final item = _supplier.copyWith(
        name: _nameController.text,
        contactPersonName: _contactPersonNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        address: _addressController.text,
        createdBy: _supplier.createdBy,
        updatedBy: context.employee!.fullName,
      );

      /// Update Suppliers
      context.read<SupplierBloc>().add(
        UpdateSetup<Supplier>(documentId: _supplier.id, data: item),
      );

      context.showAlertOverlay(
        '${_nameController.text.toTitle} successfully updated',
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(context),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 20.0),
        SupplierNameAndContactPersonNameInput(
          supplierNameController: _nameController,
          contactPersonNameController: _contactPersonNameController,
          onSupplierNameChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onContactPersonNameChanged: (s) => setState(() {}),
        ),
        const SizedBox(height: 20.0),
        SupplierPhoneAndEmailInput(
          phoneController: _phoneController,
          emailController: _emailController,
          onEmailChanged: (s) => setState(() {}),
          onPhoneChanged: (s) => setState(() {}),
        ),
        const SizedBox(height: 20.0),
        AddressTextField(controller: _emailController),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(onPressed: _onSubmit),
      ],
    );
  }
}
