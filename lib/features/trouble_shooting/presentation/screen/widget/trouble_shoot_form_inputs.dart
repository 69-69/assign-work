import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/widget/search_subscription.dart';
import 'package:flutter/material.dart';

/// Subscription Name & Fee TextField [SubscriptionNameAndFee]
class SubscriptionNameAndFee extends StatelessWidget {
  const SubscriptionNameAndFee({
    super.key,
    this.enable,
    this.onFeeChanged,
    this.onNameChanged,
    required this.feeController,
    required this.nameController,
  });

  final TextEditingController nameController;
  final TextEditingController feeController;
  final ValueChanged? onNameChanged;
  final ValueChanged? onFeeChanged;
  final bool? enable;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextField(
          enabled: enable,
          label: 'Subscription name',
          onChanged: onNameChanged,
          controller: nameController,
          keyboardType: TextInputType.name,
        ),
        SubscriptionFee(
          enable: enable,
          onSubscribeFeeChanged: onFeeChanged,
          subscribeFeeController: feeController,
        ),
      ],
    );
  }
}

/// Subscription Fee TextField [SubscriptionFee]
class SubscriptionFee extends StatelessWidget {
  const SubscriptionFee({
    super.key,
    this.enable,
    required this.onSubscribeFeeChanged,
    required this.subscribeFeeController,
  });

  final bool? enable;
  final TextEditingController subscribeFeeController;
  final ValueChanged? onSubscribeFeeChanged;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      enabled: enable,
      label: 'Subscription Fee',
      onChanged: onSubscribeFeeChanged,
      controller: subscribeFeeController,
      keyboardType: TextInputType.number,
      inputDecoration: InputDecoration(
        hintText: 'Subscription Fee',
        label: const Text(
          'Subscription Fee',
          semanticsLabel: 'Subscription Fee',
        ),
        alignLabelWithHint: true,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.payments, size: 15),
      ),
    );
  }
}

/// Subscription Licenses Dropdown [SubscriptionAndTotalDevicesDropdown]
class SubscriptionAndTotalDevicesDropdown extends StatelessWidget {
  final String? initialSub;
  final String? initialTotalDevices;
  final Function(String?) onTotalDevicesChanged;
  final Function(String, String, double, DateTime?, DateTime?) onChanged;

  const SubscriptionAndTotalDevicesDropdown({
    super.key,
    this.initialSub,
    required this.onChanged,
    this.initialTotalDevices,
    required this.onTotalDevicesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StaticDropdown<String>(
          key: key,
          label: 'Total Devices',
          initialValue: initialTotalDevices,
          items: List.generate(20, (i) => '$i'),
          getDisplayText: (total) => total,
          onChanged: onTotalDevicesChanged,
        ),
        SearchSubscription(
          initialValue: initialSub,
          onChanged: (sub) => onChanged(
            sub!.id,
            sub.name,
            sub.fee,
            sub.effectiveFrom,
            sub.expiresOn,
          ),
        ),
      ],
    );
  }
}

/// Expiry & Effective Date Picker [EffectiveAndExpiryDateInput]
class EffectiveAndExpiryDateInput extends StatelessWidget {
  const EffectiveAndExpiryDateInput({
    super.key,
    this.labelExpiry,
    this.labelManufacture,
    this.onQuantityChanged,
    required this.onExpiryChanged,
    required this.onEffectiveChanged,
    this.initialExpiryDate,
    this.initialEffectiveDate,
  });

  final String? initialExpiryDate;
  final String? initialEffectiveDate;
  final String? labelExpiry;
  final String? labelManufacture;
  final ValueChanged? onQuantityChanged;
  final Function(DateTime) onExpiryChanged;
  final Function(DateTime) onEffectiveChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DatePicker(
          initialDate: initialEffectiveDate,
          label: labelManufacture,
          restorationId: 'Effective date',
          selectedDate: onEffectiveChanged,
        ),
        DatePicker(
          initialDate: initialExpiryDate,
          label: labelExpiry,
          restorationId: 'Expiry date',
          selectedDate: onExpiryChanged,
        ),
      ],
    );
  }
}
