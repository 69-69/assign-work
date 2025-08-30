import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/customer_crm/presentation/screen/customers/widget/search_customer.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/items/widget/search_items.dart';
import 'package:flutter/material.dart';

/// ItemId & UnitPrice TextField/Dropdown [UnitPriceAndQuantityInput]
class UnitPriceAndQuantityInput extends StatelessWidget {
  const UnitPriceAndQuantityInput({
    super.key,
    this.initialValue,
    required this.onUnitChanged,
    required this.onQtyChanged,
    required this.qtyController,
    required this.unitPriceController,
  });

  final String? initialValue;
  final ValueChanged onUnitChanged;
  final ValueChanged onQtyChanged;
  final TextEditingController qtyController;
  final TextEditingController unitPriceController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        UnitPriceTextField(
          controller: unitPriceController,
          onChanged: onUnitChanged,
        ),
        QuantityTextField(controller: qtyController, onChanged: onQtyChanged),
      ],
    );
  }
}

/// ItemId & Customer TextField/Dropdown [CustomerAndItemId]
class CustomerAndItemId extends StatelessWidget {
  const CustomerAndItemId({
    super.key,
    this.initialItem,
    this.initialCustomer,
    required this.onItemChanged,
    required this.onCustomerChanged,
  });

  final String? initialItem;
  final String? initialCustomer;
  final ValueChanged onItemChanged;
  final Function(String, String) onCustomerChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SearchItems(
          isDropdown: true,
          initialValue: initialItem,
          onChanged: onItemChanged,
        ),
        CustomerIDInput(
          initialValue: initialCustomer,
          onChanged: onCustomerChanged,
        ),
      ],
    );
  }
}

/// Order Status & SubTotal Dropdown [SubTotalAndOrderStatus]
class SubTotalAndOrderStatus extends StatelessWidget {
  final String? initialStatus;
  final Function(String)? onSubTotalChange;
  final void Function(dynamic s) onStatusChange;
  final TextEditingController subTotalController;

  const SubTotalAndOrderStatus({
    super.key,
    this.initialStatus,
    required this.onSubTotalChange,
    required this.onStatusChange,
    required this.subTotalController,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SubTotalTextField(
          controller: subTotalController,
          onChanged: onSubTotalChange,
        ),
        OrdersStatusDropdown(
          initialValue: initialStatus,
          onChange: onStatusChange,
        ),
      ],
    );
  }
}

/// Remarks & Total Amount TextField [TotalAmountAndPayMethod]
class TotalAmountAndPayMethod extends StatelessWidget {
  final TextEditingController? totalAmtController;
  final ValueChanged? onTotalAmtChanged;
  final VoidCallback? onEdited;
  final bool? enable;
  final ValueChanged onPaymentChanged;
  final String? initialPayMethod;

  const TotalAmountAndPayMethod({
    super.key,
    this.totalAmtController,
    this.onTotalAmtChanged,
    this.onEdited,
    this.enable,
    this.initialPayMethod,
    required this.onPaymentChanged,
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
        PaymentMethodDropdown(
          initialValue: initialPayMethod,
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

///********* TextFields *************///

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
    return SearchCustomer(
      initialValue: initialValue,
      onChanged: onChanged,
      isPOS: true,
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
  final Function(String)? onChanged;

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

/// Payment Method Dropdown [PaymentMethodDropdown]
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
      getValue: (method) => method,
      getDisplayText: (method) => method,
      onChanged: (String? v) => onChanged(v),
    );
  }
}

/// Orders Status [OrdersStatusDropdown]
class OrdersStatusDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChange;

  const OrdersStatusDropdown({
    super.key,
    required this.onChange,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      items: orderStatus,
      label: 'order status',
      initialValue: initialValue,
      getValue: (status) => status,
      getDisplayText: (status) => status,
      onChanged: (String? v) => onChange(v),
    );
  }
}
