import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';

class CRMFormInputs {
  static Widget buildCustNumber(
    BuildContext context, {
    String count = '',
    String what = 'Customer',
    void Function()? onPressed,
  }) => Align(
    alignment: Alignment.topLeft,
    child: FittedBox(
      child: context.actionInfoButton(
        'Refresh $what ID',
        count: count,
        isTotal: false,
        onPressed: onPressed,
        bgColor: kPrimaryColor,
      ),
    ),
  );

  /// Updates the [list] with objects of type [T] from a list of maps.
  /// Clears the list first to prevent duplication, then adds new objects.
  /// [fromMap] converts each map entry into an object with the index as the ID.
  static updateListFromData<T>(
    List<T> list, {
    required List<Map<String, dynamic>> map,
    required T Function(Map<String, dynamic>, String) fromMap,
  }) {
    return list
      ..clear() // Clear previous entries to prevent duplication
      ..addAll(
        map
            .asMap()
            .entries
            .map((e) => fromMap(e.value, '${e.key + 1}'))
            .toList(),
      );
  }
}

/// Phone & ltPhone TextField [PhoneAndAltPhoneInput]
class PhoneAndAltPhoneInput extends StatelessWidget {
  const PhoneAndAltPhoneInput({
    super.key,
    required this.phoneController,
    required this.altPhoneController,
    required this.onPhoneChanged,
    required this.onAltPhoneChanged,
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
        PhoneTextField(
          phoneController: phoneController,
          onPhoneChanged: onPhoneChanged,
        ),
        AltPhoneTextField(
          altPhoneController: altPhoneController,
          onAltPhoneChanged: onAltPhoneChanged,
        ),
      ],
    );
  }
}

/// CustomerId TextField [CustomerIdInput]
class CustomerIdInput extends StatelessWidget {
  const CustomerIdInput({
    super.key,
    required this.customerIdController,
    this.onCustomerIdChanged,
    this.onCustomerEdited,
    this.enableCustomer,
  });

  final TextEditingController customerIdController;
  final ValueChanged? onCustomerIdChanged;
  final VoidCallback? onCustomerEdited;
  final bool? enableCustomer;

  @override
  Widget build(BuildContext context) {
    return CustomerIdTextField(
      controller: customerIdController,
      onChanged: onCustomerIdChanged,
      onEdited: onCustomerEdited,
      enable: enableCustomer,
    );
  }
}

/// Customer Name & BirthDay TextField [CustomerNameAndBirthDayInput]
class CustomerNameAndBirthDayInput extends StatelessWidget {
  const CustomerNameAndBirthDayInput({
    super.key,
    required this.nameController,
    required this.onDateChanged,
    this.onNameChanged,
    this.initialDate,
  });

  final TextEditingController nameController;
  final Function(DateTime) onDateChanged;
  final ValueChanged? onNameChanged;
  final String? initialDate;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        NameTextField(controller: nameController, onChanged: onNameChanged),
        DatePicker(
          label: 'Birth day',
          helperText: 'Optional',
          initialDate: initialDate,
          restorationId: 'Birth day',
          selectedDate: onDateChanged,
        ),
      ],
    );
  }
}

/// Email & CompanyName TextField [EmailAndCompanyNameInput]
class EmailAndCompanyNameInput extends StatelessWidget {
  const EmailAndCompanyNameInput({
    super.key,
    required this.emailController,
    required this.companyNameController,
    this.onEmailChanged,
    this.onCompanyNameChanged,
  });

  final TextEditingController emailController;
  final TextEditingController companyNameController;
  final ValueChanged? onEmailChanged;
  final ValueChanged? onCompanyNameChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        EmailTextField(controller: emailController, onChanged: onEmailChanged),
        CompanyNameTextField(
          controller: companyNameController,
          onChanged: onCompanyNameChanged,
        ),
      ],
    );
  }
}

/// [AddressTextField]
class AddressTextField extends StatelessWidget {
  final TextEditingController? addressController;
  final ValueChanged? onAddressChanged;

  const AddressTextField({
    super.key,
    this.addressController,
    this.onAddressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: addressController,
      onChanged: onAddressChanged,
      label: 'Address / Location...',
      helperText: 'Optional',
      keyboardType: TextInputType.multiline,
      maxLines: 4,
      validator: (s) => null,
    );
  }
}

/// [AltPhoneTextField]
class AltPhoneTextField extends StatelessWidget {
  final TextEditingController? altPhoneController;
  final ValueChanged? onAltPhoneChanged;

  const AltPhoneTextField({
    super.key,
    this.altPhoneController,
    this.onAltPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: altPhoneController,
      onChanged: onAltPhoneChanged,
      keyboardType: TextInputType.number,
      inputDecoration: const InputDecoration(
        labelText: 'Alternative phone number (if any)',
      ),
      validator: (s) => null,
    );
  }
}

/// [EmailTextField]
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const EmailTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.emailAddress,
      label: 'Email address',
      helperText: 'Optional',
      validator: (s) => null,
    );
  }
}

/// [CompanyNameTextField]
class CompanyNameTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const CompanyNameTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Company name',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
      helperText: 'Optional',
      validator: (s) => null,
    );
  }
}

/// [NameTextField]
class NameTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const NameTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Full name',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
    );
  }
}

/// [CustomerIdTextField]
class CustomerIdTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;
  final VoidCallback? onEdited;
  final bool? enable;

  const CustomerIdTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.onEdited,
    this.enable,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: <Widget>[
        CustomTextField(
          enable: enable,
          label: 'Customer ID',
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.text,
        ),
        TextButton(
          onPressed: onEdited,
          style: TextButton.styleFrom(padding: const EdgeInsets.only(top: 15)),
          child: const Text('Edit'),
        ),
      ],
    );
  }
}

/// [PhoneTextField]
class PhoneTextField extends StatelessWidget {
  final TextEditingController? phoneController;
  final ValueChanged? onPhoneChanged;

  const PhoneTextField({super.key, this.phoneController, this.onPhoneChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: phoneController,
      onChanged: onPhoneChanged,
      keyboardType: TextInputType.number,
      inputDecoration: const InputDecoration(
        labelText: 'Phone number',
        // helperText: '',
      ),
    );
  }
}
