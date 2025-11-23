import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/customer_crm/presentation/screen/customers/widget/search_customer.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/items/widget/search_items.dart';
import 'package:flutter/material.dart';

/// Customer ID TextField [CustomerIDInput]
class CustomerIDInput extends StatelessWidget {
  const CustomerIDInput({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  final String? initialValue;
  final Function(String, String) onChanged;

  @override
  Widget build(BuildContext context) {
    return SearchCustomer(initialValue: initialValue, onChanged: onChanged);
  }
}

/// ItemId & Quantity TextField/Dropdown [ItemIdAndQuantityInput]
class ItemIdAndQuantityInput extends StatelessWidget {
  const ItemIdAndQuantityInput({
    super.key,
    this.initialValue,
    required this.onChanged,
    required this.onQtyChanged,
    required this.qtyController,
  });

  final String? initialValue;
  final ValueChanged onChanged;
  final ValueChanged onQtyChanged;
  final TextEditingController qtyController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SearchItems(
          isDropdown: true,
          initialValue: initialValue,
          onChanged: onChanged,
        ),
        QuantityTextField(controller: qtyController, onChanged: onQtyChanged),
      ],
    );
  }
}

/// Order Status & Order Types Dropdown [_OrderStatusAndTypesDropdown]
class OrderStatusAndTypesDropdown extends StatelessWidget {
  final String? initialType;
  final void Function(dynamic s) onTypeChange;
  final String? initialStatus;
  final void Function(dynamic s) onStatusChange;

  const OrderStatusAndTypesDropdown({
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
        OrdersTypesDropdown(
          initialValue: initialType,
          onValueChanged: onTypeChange,
        ),
        OrdersStatusDropdown(
          initialValue: initialStatus,
          onChanged: onStatusChange,
        ),
      ],
    );
  }
}

/// Shipping & Delivery Date TextField [ShippingAndDeliveryDateInput]
class ShippingAndDeliveryDateInput extends StatelessWidget {
  const ShippingAndDeliveryDateInput({
    super.key,
    this.labelDelivery,
    this.labelShipping,
    this.onQuantityChanged,
    required this.onDeliveryChanged,
    required this.onShippingChanged,
    this.initialDeliveryDate,
    this.initialShippingDate,
  });

  final String? initialDeliveryDate;
  final String? initialShippingDate;
  final String? labelDelivery;
  final String? labelShipping;
  final ValueChanged? onQuantityChanged;
  final Function(DateTime) onDeliveryChanged;
  final Function(DateTime) onShippingChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DatePicker(
          initialDate: initialShippingDate,
          label: labelShipping,
          restorationId: 'Shipping date',
          selectedDate: onShippingChanged,
          helperText: 'Optional',
        ),
        DatePicker(
          initialDate: initialDeliveryDate,
          label: labelDelivery,
          restorationId: 'Delivery date',
          selectedDate: onDeliveryChanged,
          helperText: 'Optional',
        ),
      ],
    );
  }
}

/// Validity date And Order-Source TextField/Dropdown [ValidityAndOrderSource]
class ValidityAndOrderSource extends StatelessWidget {
  const ValidityAndOrderSource({
    super.key,
    this.labelValidity,
    this.initialOrderSource,
    this.initialValidityDate,
    required this.onSourceChanged,
    required this.onValidityChanged,
  });

  final String? initialOrderSource;
  final String? initialValidityDate;
  final String? labelValidity;
  final Function(String?) onSourceChanged;
  final Function(DateTime) onValidityChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StaticDropdown<String>(
          key: key,
          items: orderSources,
          label: 'order source',
          initialValue: initialOrderSource,
          getDisplayText: (source) => source,
          onChanged: onSourceChanged,
        ),
        DatePicker(
          initialDate: initialValidityDate,
          label: labelValidity ?? 'Validity date',
          restorationId: 'Validity date',
          selectedDate: onValidityChanged,
          helperText: 'Optional',
        ),
      ],
    );
  }
}

/// SubTotal & UnitPrice TextField [_SubTotalAndUnitPriceInput]
class SubTotalAndUnitPriceInput extends StatelessWidget {
  const SubTotalAndUnitPriceInput({
    super.key,
    required this.unitPriceController,
    required this.subTotalController,
    this.onUnitPriceChanged,
    this.onSubTotalChanged,
  });

  final TextEditingController unitPriceController;
  final TextEditingController subTotalController;
  final ValueChanged? onUnitPriceChanged;
  final ValueChanged? onSubTotalChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        UnitPriceTextField(
          controller: unitPriceController,
          onChanged: onUnitPriceChanged,
        ),
        SubTotalTextField(
          controller: subTotalController,
          onChanged: onSubTotalChanged,
        ),
      ],
    );
  }
}

/// Remarks & Total Amount TextField [RemarksAndTotalAmtTextField]
class RemarksAndTotalAmtTextField extends StatelessWidget {
  final TextEditingController? remarksController;
  final TextEditingController? totalAmtController;
  final ValueChanged? onTotalAmtChanged;
  final ValueChanged? onRemarksChanged;
  final VoidCallback? onEdited;
  final bool? enable;

  const RemarksAndTotalAmtTextField({
    super.key,
    this.remarksController,
    this.onRemarksChanged,
    this.totalAmtController,
    this.onTotalAmtChanged,
    this.onEdited,
    this.enable,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TotalAmountTextField(
          enable: enable,
          onEdited: onEdited,
          controller: totalAmtController,
          onChanged: onTotalAmtChanged,
        ),
        RemarksTextField(
          controller: remarksController,
          onChanged: onRemarksChanged,
        ),
      ],
    );
  }
}

/// Amount Paid & PaymentStatus Dropdown/TextField [AmountPaidAndPaymentStatusDropdown]
class AmountPaidAndPaymentStatusDropdown extends StatelessWidget {
  const AmountPaidAndPaymentStatusDropdown({
    super.key,
    required this.amountPaidController,
    required this.onAmountPaidChanged,
    required this.onStatusChanged,
    this.initialStatus,
  });

  final String? initialStatus;
  final ValueChanged onStatusChanged;
  final ValueChanged onAmountPaidChanged;
  final TextEditingController amountPaidController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AmountPaidTextField(
          controller: amountPaidController,
          onChanged: onAmountPaidChanged,
        ),
        PaymentStatusDropdown(
          initialValue: initialStatus,
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}

///********* TextFields *************///

/// [AmountPaidTextField]
class AmountPaidTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const AmountPaidTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Amount paid',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      validator: (v) => null,
    );
  }
}

/// [TotalAmountTextField]
class TotalAmountTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;
  final VoidCallback? onEdited;
  final bool? enable;

  const TotalAmountTextField({
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
          controller: controller,
          onChanged: onChanged,
          label: 'Total amount',
          keyboardType: TextInputType.number,
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

/// [QuantityTextField]
class QuantityTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const QuantityTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Quantity',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
    );
  }
}

/// [UnitPriceTextField]
class UnitPriceTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const UnitPriceTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Unit price',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
    );
  }
}

/// [SubTotalTextField]
class SubTotalTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const SubTotalTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Sub total',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
    );
  }
}

/// [DiscountPercentTextField]
class DiscountPercentTextField extends StatelessWidget {
  final TextEditingController? controller;
  final double discountAmount;
  final ValueChanged? onChanged;

  const DiscountPercentTextField({
    super.key,
    this.controller,
    this.discountAmount = 0.0,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputDecoration: InputDecoration(
        // helperText: 'Optional',
        labelText: 'Discount Percent (Optional)',
        suffixText: '= $ghanaCedis $discountAmount',
        prefixIcon: const Icon(Icons.percent),
        prefixIconColor: kGrayColor,
      ),
      validator: (v) => null,
    );
  }
}

/// Delivery Amount And Payment Method TextField [DeliveryAmtPaymentMethodInput]
class DeliveryAmtPaymentMethodInput extends StatelessWidget {
  const DeliveryAmtPaymentMethodInput({
    super.key,
    this.initialValue,
    required this.onChanged,
    required this.onPaymentChanged,
    required this.deliveryController,
  });

  final String? initialValue;
  final ValueChanged onChanged;
  final ValueChanged onPaymentChanged;
  final TextEditingController deliveryController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DeliveryAmountTextField(
          controller: deliveryController,
          onChanged: onChanged,
        ),
        PaymentMethodDropdown(
          initialValue: initialValue,
          onChanged: onPaymentChanged,
        ),
      ],
    );
  }
}

/// TaxPercent & Delivery Amount TextField [TaxPercentAndDiscountPercentInput]
class TaxPercentAndDiscountPercentInput extends StatelessWidget {
  const TaxPercentAndDiscountPercentInput({
    super.key,
    required this.taxController,
    required this.taxAmount,
    required this.onTaxChanged,
    this.discountController,
    required this.discountAmount,
    this.onDiscountChanged,
  });

  final double taxAmount;
  final ValueChanged onTaxChanged;
  final TextEditingController taxController;
  final TextEditingController? discountController;
  final double discountAmount;
  final ValueChanged? onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TaxPercentTextField(
          controller: taxController,
          taxAmount: taxAmount,
          onChanged: onTaxChanged,
        ),
        CustomTextField(
          controller: discountController,
          onChanged: onDiscountChanged,
          keyboardType: TextInputType.number,
          inputDecoration: InputDecoration(
            labelText: 'Discount Percent (Optional)',
            // helperText: 'Optional',
            suffixText: '= $ghanaCedis $discountAmount',
            prefixIcon: const Icon(Icons.percent),
            prefixIconColor: kGrayColor,
          ),
          validator: (v) => null,
        ),
      ],
    );
  }
}

/// [TaxPercentTextField]
class TaxPercentTextField extends StatelessWidget {
  final double taxAmount;
  final ValueChanged? onChanged;
  final TextEditingController? controller;

  const TaxPercentTextField({
    super.key,
    this.controller,
    this.taxAmount = 0.0,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Tax Percent',
      onChanged: onChanged,
      controller: controller,
      keyboardType: TextInputType.number,
      inputDecoration: InputDecoration(
        labelText: 'Tax Percent (Optional)',
        // helperText: 'Optional',
        suffixText: '= $ghanaCedis $taxAmount',
        prefixIcon: const Icon(Icons.percent),
        prefixIconColor: kGrayColor,
      ),
      validator: (v) => null,
    );
  }
}

/// [DeliveryAmountTextField]
class DeliveryAmountTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const DeliveryAmountTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Delivery amount',
      controller: controller,
      onChanged: onChanged,
      helperText: 'Optional',
      keyboardType: TextInputType.number,
      validator: (v) => null,
    );
  }
}

/// Payment Status Dropdown [PaymentStatusDropdown]
class PaymentStatusDropdown extends StatelessWidget {
  const PaymentStatusDropdown({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  final ValueChanged onChanged;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      items: paymentStatus,
      label: 'payment status',
      initialValue: initialValue,
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}

/// Payment Terms Dropdown [PaymentMethodDropdown]
class PaymentMethodDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const PaymentMethodDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      items: paymentMethod,
      label: 'payment method',
      initialValue: initialValue,
      getDisplayText: (method) => method,
      onChanged: onChanged,
    );
  }
}

/// Orders Status [OrdersStatusDropdown]
class OrdersStatusDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const OrdersStatusDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      items: orderStatus,
      label: 'order status',
      initialValue: initialValue,
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}

/// Orders Status [OrdersTypesDropdown]
class OrdersTypesDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onValueChanged;

  const OrdersTypesDropdown({
    super.key,
    required this.onValueChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      items: orderTypes,
      label: 'order type',
      initialValue: initialValue,
      getDisplayText: (type) => type,
      onChanged: onValueChanged,
    );
  }
}
