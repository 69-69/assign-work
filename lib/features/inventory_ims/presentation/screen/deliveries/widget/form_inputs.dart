import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/so/widget/search_orders.dart';
import 'package:flutter/material.dart';

/// Delivery Person & phone TextField [DeliveryPersonAndPhoneInput]
class DeliveryPersonAndPhoneInput extends StatelessWidget {
  const DeliveryPersonAndPhoneInput({
    super.key,
    required this.deliveryPersonController,
    required this.deliveryPhoneController,
    this.onPersonChanged,
    this.onPhoneChanged,
  });

  final TextEditingController deliveryPersonController;
  final TextEditingController deliveryPhoneController;
  final ValueChanged? onPhoneChanged;
  final ValueChanged? onPersonChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DeliveryPersonTextField(
          controller: deliveryPersonController,
          onChanged: onPersonChanged,
        ),
        DeliveryPhoneTextField(
          controller: deliveryPhoneController,
          onChanged: onPhoneChanged,
        ),
      ],
    );
  }
}

/// Order Status & Order Types Dropdown [DeliveryStatusAndTypesDropdown]
class DeliveryStatusAndTypesDropdown extends StatelessWidget {
  final String? initialType;
  final void Function(dynamic s) onTypeChange;
  final String? initialStatus;
  final void Function(dynamic s) onStatusChange;

  const DeliveryStatusAndTypesDropdown({
    super.key,
    this.initialType,
    this.initialStatus,
    required this.onTypeChange,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DeliveryTypeDropdown(
          initialType: initialType,
          onValueChange: onTypeChange,
        ),
        DeliveryStatusDropdown(
          initialStatus: initialStatus,
          onChange: onStatusChange,
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

/// Search Order Number TextField [OrderNumberDropdown]
class OrderNumberDropdown extends StatelessWidget {
  const OrderNumberDropdown({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  final String? initialValue;
  final Function(String, String) onChanged;

  @override
  Widget build(BuildContext context) {
    return SearchOrders(initialValue: initialValue, onChanged: onChanged);
  }
}

/// [DeliveryPersonTextField]
class DeliveryPersonTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const DeliveryPersonTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Delivery person',
      controller: controller,
      onChanged: onChanged,
      helperText: 'Optional',
      keyboardType: TextInputType.name,
      validator: (s) => null,
    );
  }
}

/// [DeliveryPhoneTextField]
class DeliveryPhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const DeliveryPhoneTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Delivery phone',
      helperText: 'Optional',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.phone,
      validator: (s) => null,
    );
  }
}

/// Delivery Transportation [DeliveryTypeDropdown]
class DeliveryTypeDropdown extends StatelessWidget {
  final void Function(dynamic s) onValueChange;
  final String? initialType;

  const DeliveryTypeDropdown({
    super.key,
    required this.onValueChange,
    this.initialType,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      items: deliveryTypes,
      label: 'delivery type',
      initialValue: initialType,
      getValue: (type) => type,
      getDisplayText: (type) => type,
      onChanged: (String? v) => onValueChange(v),
    );
  }
}

/// Delivery Status [DeliveryStatusDropdown]
class DeliveryStatusDropdown extends StatelessWidget {
  final void Function(dynamic s) onChange;
  final String? initialStatus;

  const DeliveryStatusDropdown({
    super.key,
    required this.onChange,
    this.initialStatus,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      items: deliveryStatus,
      label: 'delivery status',
      initialValue: initialStatus,
      getValue: (status) => status,
      getDisplayText: (status) => status,
      onChanged: (String? v) => onChange(v),
    );
  }
}
