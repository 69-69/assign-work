import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/supplier_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/product_config/suppliers_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/item_config/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AddSuppliers on BuildContext {
  Future openAddSuppliers({Widget? header}) => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(title: 'Add Suppliers', body: _AddSuppliersForm()),
  );
}

class _AddSuppliersForm extends StatefulWidget {
  const _AddSuppliersForm();

  @override
  State<_AddSuppliersForm> createState() => _AddSuppliersFormState();
}

class _AddSuppliersFormState extends State<_AddSuppliersForm> {
  final ScrollController _scrollController = ScrollController();
  bool isMultipleSuppliers = false;
  final List<Supplier> _suppliers = [];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactPersonNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Supplier get _supplierData => Supplier(
    name: _nameController.text,
    contactName: _contactPersonNameController.text,
    phone: _phoneController.text,
    email: _emailController.text,
    address: _addressController.text,
    createdBy: context.employee?.fullName ?? 'unknown',
  );

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      /// Added Multiple suppliers Simultaneously
      _suppliers.add(_supplierData);

      context.read<SupplierBloc>().add(
        AddSetup<List<Supplier>>(data: _suppliers),
      );

      _formKey.currentState!.reset();

      _clearFields();

      context.showAlertOverlay('Stores successfully created');
      Navigator.pop(context);
    }
  }

  /// Function for Adding Multiple Suppliers Simultaneously
  void _addSupplierToList() {
    if (_formKey.currentState!.validate()) {
      setState(() => isMultipleSuppliers = true);
      _suppliers.add(_supplierData);

      context.showAlertOverlay(
        '${_nameController.text.toTitle} added to batch',
      );
      _clearFields();
    }
  }

  void _clearFields() {
    _nameController.clear();
    _contactPersonNameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _emailController.clear();
  }

  void _removeSupplier(Supplier supplier) {
    setState(() => _suppliers.remove(supplier));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Wrap(
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          if (isMultipleSuppliers && _suppliers.isNotEmpty)
            _buildBatchPreviewChips(),
          _buildBody(context),
        ],
      ),
    );
  }

  // Horizontal scrollable row of chips representing the List of batches
  Widget _buildBatchPreviewChips() {
    return CustomScrollBar(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _suppliers.map((o) {
          return o.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Chip(
                    padding: EdgeInsets.zero,
                    label: Text(
                      o.name.toTitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    deleteButtonTooltipMessage: 'Remove ${o.name}',
                    backgroundColor: kGrayColor.toAlpha(0.3),
                    deleteIcon: const Icon(
                      size: 16,
                      Icons.clear,
                      color: kGrayColor,
                    ),
                    onDeleted: () => _removeSupplier(o),
                  ),
                );
        }).toList(),
      ),
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
        AddressTextField(controller: _addressController),
        const SizedBox(height: 20.0),
        context.elevatedIconBtn(
          Icons.add,
          onPressed: _addSupplierToList,
          label: 'Add to List',
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          label: isMultipleSuppliers
              ? 'Create All Suppliers'
              : 'Create Supplier',
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}
