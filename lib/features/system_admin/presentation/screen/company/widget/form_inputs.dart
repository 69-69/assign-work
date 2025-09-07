import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';

/// Store Name & Location TextField [StoreNameAndLocationInput]
class StoreNameAndLocationInput extends StatelessWidget {
  const StoreNameAndLocationInput({
    super.key,
    required this.nameController,
    required this.locationController,
    this.onNameChanged,
    this.onLocationChanged,
  });

  final TextEditingController nameController;
  final TextEditingController locationController;
  final ValueChanged? onNameChanged;
  final ValueChanged? onLocationChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StoreNameTextField(
          controller: nameController,
          onChanged: onNameChanged,
        ),
        StoreLocationTextField(
          controller: locationController,
          onChanged: onLocationChanged,
        ),
      ],
    );
  }
}

/// Company Name & Email TextField [CompanyNameAndEmailInput]
class CompanyNameAndEmailInput extends StatelessWidget {
  const CompanyNameAndEmailInput({
    super.key,
    required this.nameController,
    required this.emailController,
    this.onNameChanged,
    this.onEmailChanged,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final ValueChanged? onNameChanged;
  final ValueChanged? onEmailChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextField(
          label: 'Company name',
          controller: nameController,
          keyboardType: TextInputType.name,
          onChanged: onNameChanged,
        ),
        CustomTextField(
          label: 'Company email',
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: onEmailChanged,
          validator: (v) => null,
        ),
      ],
    );
  }
}

/// Phone & Alternative Phone TextField [PhoneAndAltPhoneInput]
class PhoneAndAltPhoneInput extends StatelessWidget {
  const PhoneAndAltPhoneInput({
    super.key,
    required this.phoneController,
    required this.altPhoneController,
    this.onPhoneChanged,
    this.onAltPhoneChanged,
  });

  final TextEditingController phoneController;
  final TextEditingController altPhoneController;
  final ValueChanged? onPhoneChanged;
  final ValueChanged? onAltPhoneChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PhoneTextField(controller: phoneController, onChanged: onPhoneChanged),
        AltPhoneTextField(
          controller: altPhoneController,
          onChanged: onAltPhoneChanged,
        ),
      ],
    );
  }
}

/// Address & Fax number TextField [FaxAndAddressTextField]
class FaxAndAddressTextField extends StatelessWidget {
  final TextEditingController? addressController;
  final TextEditingController? faxController;
  final ValueChanged? onAddressChanged;
  final ValueChanged? onFaxChanged;

  const FaxAndAddressTextField({
    super.key,
    this.addressController,
    this.onAddressChanged,
    this.faxController,
    this.onFaxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextField(
          label: 'Fax',
          helperText: 'Optional',
          controller: faxController,
          onChanged: onFaxChanged,
          keyboardType: TextInputType.phone,
          validator: (s) => null,
        ),
        CustomTextField(
          label: 'Address or location...',
          helperText: 'Optional',
          controller: addressController,
          onChanged: onAddressChanged,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
          validator: (s) => null,
        ),
      ],
    );
  }
}

///********* TextFields *************///

/// [RemarksTextField]
class RemarksTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const RemarksTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Remarks...',
      helperText: 'Optional',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.multiline,
      maxLines: 4,
      validator: (s) => null,
    );
  }
}

/// [StoreNameTextField]
class StoreNameTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const StoreNameTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Store name',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
    );
  }
}

/// [StoreLocationTextField]
class StoreLocationTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const StoreLocationTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Store location',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
    );
  }
}

/// [PhoneTextField]
class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const PhoneTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Phone number',
      helperText: 'Optional',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.phone,
      validator: (v) => null,
    );
  }
}

/// [AltPhoneTextField]
class AltPhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const AltPhoneTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Alternative phone number',
      helperText: 'Optional',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.phone,
      validator: (v) => null,
    );
  }
}
