import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_enum.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/customer_crm/presentation/screen/customers/widget/search_customer.dart';
import 'package:flutter/material.dart';

/// Order-Number And Product-Id TextField [OrderNumberAndItemIdInput]
class OrderNumberAndItemIdInput extends StatelessWidget {
  const OrderNumberAndItemIdInput({
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
      mainAxisSize: MainAxisSize.min,
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

/// Quantity & UnitPrice TextField [UnitPriceAndQuantityInput]
class UnitPriceAndQuantityInput extends StatelessWidget {
  const UnitPriceAndQuantityInput({
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
      mainAxisSize: MainAxisSize.min,
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

/// TaxPercent & Delivery Amount TextField [_TaxAndDeliveryInput]
class TaxAndDeliveryInput extends StatelessWidget {
  const TaxAndDeliveryInput({
    super.key,
    required this.deliveryController,
    required this.taxController,
    required this.taxAmount,
    required this.onChanged,
  });

  final double taxAmount;
  final ValueChanged onChanged;
  final TextEditingController taxController;
  final TextEditingController deliveryController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TaxPercentTextField(
          controller: taxController,
          taxAmount: taxAmount,
          onChanged: onChanged,
        ),

        DeliveryAmountTextField(
          controller: deliveryController,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// TaxPercent & Delivery Amount TextField [InvoiceNumberAndCustomerId]
class InvoiceNumberAndCustomerId extends StatelessWidget {
  const InvoiceNumberAndCustomerId({
    super.key,
    required this.invoiceIdController,
    required this.onCustomerChanged,
    required this.onInvoiceNoChanged,
    this.initialCustomer,
  });

  final String? initialCustomer;
  final Function(String, String) onCustomerChanged;
  final ValueChanged onInvoiceNoChanged;
  final TextEditingController invoiceIdController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InvoiceNumberTextField(
          controller: invoiceIdController,
          onChanged: onInvoiceNoChanged,
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

/// Delivery Amount And Payment Method TextField [DeliveryAmtPaymentMethodInput]
class DeliveryAmtPaymentMethodInput extends StatelessWidget {
  const DeliveryAmtPaymentMethodInput({
    super.key,
    this.initialPayMethod,
    required this.onChanged,
    required this.onPayMethodChanged,
    required this.deliveryController,
  });

  final ValueChanged onChanged;
  final ValueChanged onPayMethodChanged;
  final String? initialPayMethod;
  final TextEditingController deliveryController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DeliveryAmountTextField(
          controller: deliveryController,
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

/// Sales Status And Payment Status TextField [SalesAndPaymentStatusDropdown]
class SalesAndPaymentStatusDropdown extends StatelessWidget {
  const SalesAndPaymentStatusDropdown({
    super.key,
    this.initialSale,
    this.initialPayment,
    required this.onSaleChanged,
    required this.onPaymentChanged,
  });

  final ValueChanged onSaleChanged;
  final ValueChanged onPaymentChanged;
  final String? initialPayment;
  final String? initialSale;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PaymentStatusDropdown(
          initialValue: initialPayment,
          onChanged: onPaymentChanged,
        ),
        SalesStatusDropdown(
          initialValue: initialSale,
          onChanged: onSaleChanged,
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
      mainAxisSize: MainAxisSize.min,
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
      mainAxisSize: MainAxisSize.min,
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
    return SearchCustomer(initialValue: initialValue, onChanged: onChanged);
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

///********* TextFields *************///

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
    return StaticDropdown(
      key: key,
      items: paymentStatus,
      label: 'payment status',
      initialValue: initialValue,
      onValueChange: (String? v) => onChanged(v),
    );
  }
}

/// Orders Status [SalesStatusDropdown]
class SalesStatusDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const SalesStatusDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown(
      key: key,
      items: saleStatus,
      label: 'sale status',
      initialValue: initialValue,
      onValueChange: (String? v) => onChanged(v),
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
    return StaticDropdown(
      key: key,
      items: paymentMethod,
      label: 'payment method',
      initialValue: initialValue,
      onValueChange: (String? v) => onChanged(v),
    );
  }
}

/// [DiscountTextField]
class DiscountTextField extends StatelessWidget {
  final TextEditingController? controller;
  final double discountAmount;
  final ValueChanged? onChanged;

  const DiscountTextField({
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
        labelText: 'Discount Percent',
        suffixText: '= $ghanaCedis $discountAmount',
        prefixIcon: const Icon(Icons.percent),
        prefixIconColor: kGrayColor,
      ),
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
          label: 'Item ID',
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
    );
  }
}

/// [InvoiceNumberTextField]
class InvoiceNumberTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const InvoiceNumberTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Invoice Number',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
    );
  }
}
