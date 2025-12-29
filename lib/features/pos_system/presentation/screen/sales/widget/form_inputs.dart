import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/customer_crm/presentation/screen/customers/widget/search_customer.dart';
import 'package:flutter/material.dart';

/// Order-Number And Product-Id TextField [OrderNumberAndItemId]
class OrderNumberAndItemId extends StatelessWidget {
  const OrderNumberAndItemId({
    super.key,
    required this.itemIdController,
    required this.orderNumberController,
    required this.onItemIdChanged,
    required this.onIdChanged,
    this.enableOrderNumber,
    this.onOrderNumberEdited,
    this.enableItemId,
    this.onItemIdEdited,
  });

  final TextEditingController itemIdController;
  final TextEditingController orderNumberController;
  final ValueChanged? onItemIdChanged;
  final ValueChanged? onIdChanged;
  final VoidCallback? onItemIdEdited;
  final VoidCallback? onOrderNumberEdited;
  final bool? enableItemId;
  final bool? enableOrderNumber;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ItemIdTextField(
          controller: itemIdController,
          onChanged: onItemIdChanged,
          onEdited: onItemIdEdited,
          enable: enableItemId,
        ),
        OrderNumberTextField(
          controller: orderNumberController,
          onEdited: onOrderNumberEdited,
          onChanged: onIdChanged,
          enable: enableOrderNumber,
        ),
      ],
    );
  }
}

/// Quantity & UnitPrice TextField [UnitPriceAndQuantity]
class UnitPriceAndQuantity extends StatelessWidget {
  const UnitPriceAndQuantity({
    super.key,
    required this.unitPriceController,
    required this.quantityController,
    this.onUnitPriceChanged,
    this.onQuantityChanged,
  });

  final TextEditingController unitPriceController;
  final TextEditingController quantityController;
  final ValueChanged? onUnitPriceChanged;
  final ValueChanged? onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        UnitPriceTextField(
          controller: unitPriceController,
          onChanged: onUnitPriceChanged,
        ),
        QuantityTextField(
          controller: quantityController,
          onChanged: onQuantityChanged,
        ),
      ],
    );
  }
}

/// Orders Status [SaleStatusDropdown]
class SaleStatusDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onStatusChange;

  const SaleStatusDropdown({
    super.key,
    required this.onStatusChange,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      items: saleStatus,
      label: 'sale status',
      initialValue: initialValue,
      getDisplayText: (status) => status,
      onChanged: onStatusChange,
    );
  }
}

/// Receipt Number & CustomerId TextField [ReceiptNumberAndCustomerId]
class ReceiptNumberAndCustomerId extends StatelessWidget {
  const ReceiptNumberAndCustomerId({
    super.key,
    required this.receiptNoController,
    required this.onCustomerChanged,
    required this.onReceiptNoChanged,
    this.initialCustomer,
  });

  final String? initialCustomer;
  final Function(String, String) onCustomerChanged;
  final ValueChanged onReceiptNoChanged;
  final TextEditingController receiptNoController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ReceiptNumberTextField(
          controller: receiptNoController,
          onChanged: onReceiptNoChanged,
        ),
        CustomerIdDropdown(
          initialValue: initialCustomer,
          onChanged: onCustomerChanged,
        ),
      ],
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
        labelText: 'Discount Percent (Optional)',
        suffixText: '= $ghanaCedis $discountAmount',
        prefixIcon: const Icon(Icons.percent),
        prefixIconColor: kGrayColor,
      ),
      validator: (v) => null,
    );
  }
}

/// Delivery Amount And Payment Method TextField [TotalAmtAndPaymentMethod]
class TotalAmtAndPaymentMethod extends StatelessWidget {
  const TotalAmtAndPaymentMethod({
    super.key,
    this.initialPayMethod,
    required this.onChanged,
    required this.onPayMethodChanged,
    required this.totalAmtController,
  });

  final ValueChanged onChanged;
  final ValueChanged onPayMethodChanged;
  final String? initialPayMethod;
  final TextEditingController totalAmtController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TotalAmountTextField(
          controller: totalAmtController,
          onChanged: onChanged,
        ),
        PaymentMethodDropdown(
          initialValue: initialPayMethod,
          onChanged: onPayMethodChanged,
        ),
      ],
    );
  }
}

/// TaxPercent & Delivery Amount TextField [TaxPercentAndDiscountPercent]
class TaxPercentAndDiscountPercent extends StatelessWidget {
  const TaxPercentAndDiscountPercent({
    super.key,
    required this.taxController,
    required this.taxAmount,
    required this.onChanged,
    this.discountController,
    required this.discountAmount,
    this.onDiscountChanged,
  });

  final double taxAmount;
  final ValueChanged onChanged;
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
          onChanged: onChanged,
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

///********* TextFields *************///

/// Customer ID Dropdown [CustomerIdDropdown]
class CustomerIdDropdown extends StatelessWidget {
  const CustomerIdDropdown({
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
      allowManualEntry: true,
    );
  }
}

/// [TotalAmountTextField]
class TotalAmountTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const TotalAmountTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      onChanged: onChanged,
      label: 'Total amount',
      keyboardType: TextInputType.number,
    );
  }
}

///********* TextFields *************///

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
      getDisplayText: (method) => method,
      onChanged: onChanged,
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
        // helperText: 'Optional',
        labelText: 'Tax Percent (Optional)',
        suffixText: '= $ghanaCedis $taxAmount',
        prefixIcon: const Icon(Icons.percent),
        prefixIconColor: kGrayColor,
      ),
      validator: (v) => null,
    );
  }
}

/// [OrderNumberTextField]
class OrderNumberTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;
  final VoidCallback? onEdited;
  final bool? enable;

  const OrderNumberTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.enable,
    this.onEdited,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: <Widget>[
        CustomTextField(
          enable: enable,
          label: 'Order Number',
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

/// [ItemIdTextField]
class ItemIdTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;
  final VoidCallback? onEdited;
  final bool? enable;

  const ItemIdTextField({
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
          label: 'Product ID',
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

/// [ReceiptNumberTextField]
class ReceiptNumberTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const ReceiptNumberTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Receipt Number',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
    );
  }
}
