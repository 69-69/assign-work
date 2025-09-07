import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';

/// Store Name & Location TextField [SupplierNameAndContactPersonNameInput]
class SupplierNameAndContactPersonNameInput extends StatelessWidget {
  const SupplierNameAndContactPersonNameInput({
    super.key,
    required this.supplierNameController,
    required this.contactPersonNameController,
    this.onSupplierNameChanged,
    this.onContactPersonNameChanged,
  });

  final TextEditingController supplierNameController;
  final TextEditingController contactPersonNameController;
  final ValueChanged? onSupplierNameChanged;
  final ValueChanged? onContactPersonNameChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextField(
          label: "Supplier's name",
          controller: supplierNameController,
          onChanged: onSupplierNameChanged,
          keyboardType: TextInputType.name,
        ),
        CustomTextField(
          label: 'Contact Person name',
          helperText: 'Optional',
          controller: contactPersonNameController,
          onChanged: onContactPersonNameChanged,
          keyboardType: TextInputType.name,
          validator: (v) => null,
        ),
      ],
    );
  }
}

/// Company Name & Email TextField [SupplierPhoneAndEmailInput]
class SupplierPhoneAndEmailInput extends StatelessWidget {
  const SupplierPhoneAndEmailInput({
    super.key,
    required this.phoneController,
    required this.emailController,
    this.onPhoneChanged,
    this.onEmailChanged,
  });

  final TextEditingController phoneController;
  final TextEditingController emailController;
  final ValueChanged? onPhoneChanged;
  final ValueChanged? onEmailChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextField(
          label: "Supplier's phone",
          controller: phoneController,
          keyboardType: TextInputType.phone,
          onChanged: onPhoneChanged,
        ),
        CustomTextField(
          label: "Supplier's email",
          helperText: 'Optional',
          controller: emailController,
          onChanged: onEmailChanged,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => null,
        ),
      ],
    );
  }
}

///********* TextFields *************///

/// [AddressTextField]
class AddressTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const AddressTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Supplier address / location...',
      helperText: 'Optional',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.multiline,
      maxLines: 4,
      validator: (s) => null,
    );
  }
}

/// [CategoryTextField]
class CategoryTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const CategoryTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Category name...',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
    );
  }
}
