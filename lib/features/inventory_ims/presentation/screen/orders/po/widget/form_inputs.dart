import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_supplier/supplier_account/widget/search_suppliers.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Customer ID TextField [SupplierIDInput]
class SupplierIDInput extends StatelessWidget {
  const SupplierIDInput({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  final String? initialValue;
  final Function(String, String) onChanged;

  @override
  Widget build(BuildContext context) {
    return SearchSuppliers(
      initialSupplier: initialValue,
      onSupplierChanged: onChanged,
    );
  }
}

/// Purchase Order Status & Currency Dropdown [POStatusCurrencyDropdown]
class POStatusCurrencyDropdown extends StatelessWidget {
  final String? initialCurrency;
  final void Function(dynamic s) onCurrencyChange;
  final String? initialStatus;
  final void Function(dynamic s) onStatusChange;

  const POStatusCurrencyDropdown({
    super.key,
    this.initialStatus,
    this.initialCurrency,
    required this.onStatusChange,
    required this.onCurrencyChange,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        POStatusDropdown(
          initialValue: initialStatus,
          onChanged: onStatusChange,
        ),
        StaticDropdown<Map<String, String>>(
          key: key,
          items: currencyType,
          label: 'Select currency',
          initialValue: currencyType.firstWhereOrNull(
            (e) => e['code'] == initialCurrency,
          ),
          getDisplayText: (currency) =>
              '${currency['code']} (${currency['symbol']})',
          onChanged: (v) => onCurrencyChange(v?['code']),
        ),
      ],
    );
  }
}

/// Purchase Order Payment Terms & Method Dropdown [PayTermsAndMethodDropdown]
class PayTermsAndMethodDropdown extends StatelessWidget {
  final String? initialPayTerms;
  final void Function(dynamic s) onPayTermsChanged;
  final String? initialPayMethod;
  final void Function(dynamic s) onPayMethodChanged;

  const PayTermsAndMethodDropdown({
    super.key,
    this.initialPayTerms,
    this.initialPayMethod,
    required this.onPayTermsChanged,
    required this.onPayMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StaticDropdown<Map<String, String>>(
          key: key,
          items: paymentTerms,
          label: 'payment terms',
          initialValue: paymentTerms.firstWhereOrNull(
            (e) => e['id'] == initialPayTerms,
          ),
          getDisplayText: (term) => term['term'] ?? '',
          onChanged: (v) => onPayTermsChanged(v?['id']),
          buttonDecoration: const InputDecoration(
            helperText:
                'Specifies the agreed-upon terms from RFQ negotiations.',
          ),
        ),
        StaticDropdown<String>(
          key: key,
          items: paymentMethod,
          label: 'payment method',
          initialValue: initialPayMethod,
          getDisplayText: (method) => method,
          onChanged: onPayMethodChanged,
          buttonDecoration: const InputDecoration(
            helperText: 'Indicates how the supplier will be paid.',
          ),
        ),
      ],
    );
  }
}

/// Delivery Date & Total Amount TextField [DeliveryDateAndTotalAmtInput]
class DeliveryDateAndTotalAmtInput extends StatelessWidget {
  const DeliveryDateAndTotalAmtInput({
    super.key,
    this.labelDelivery,
    required this.totalAmtController,
    required this.onDeliveryChanged,
    required this.onTotalAmtChanged,
    this.initialDelivery,
    this.onEdited,
    this.enable,
  });

  final VoidCallback? onEdited;
  final bool? enable;
  final String? initialDelivery;
  final String? labelDelivery;
  final TextEditingController totalAmtController;
  final ValueChanged? onTotalAmtChanged;
  final Function(DateTime) onDeliveryChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DatePicker(
          initialDate: initialDelivery,
          label: labelDelivery,
          restorationId: 'Delivery date',
          selectedDate: onDeliveryChanged,
          validator: (v) => v.isNullOrEmpty ? "Delivery date required" : null,
        ),
        TotalAmountTextField(
          enable: enable,
          onEdited: onEdited,
          controller: totalAmtController,
          onChanged: onTotalAmtChanged,
        ),
      ],
    );
  }
}

/// SubTotal & UnitPrice TextField [_SubTotalAndUnitPriceInput]
class UnitPriceAndQuantity extends StatelessWidget {
  const UnitPriceAndQuantity({
    super.key,
    required this.unitPriceController,
    required this.quantityController,
    this.onUnitPriceChanged,
    this.onQtyChanged,
  });

  final TextEditingController unitPriceController;
  final TextEditingController quantityController;
  final ValueChanged? onUnitPriceChanged;
  final ValueChanged? onQtyChanged;

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
          onChanged: onQtyChanged,
        ),
      ],
    );
  }
}

/// TaxPercent & DiscountPercent TextField [TaxPercentAndDiscountPercentInput]
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

/// Product Desc or name [ProductDescTextField]
class ProductDescTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const ProductDescTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Item name or description...',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
      maxLines: 2,
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

/// Orders Status [POStatusDropdown]
class POStatusDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChanged;

  const POStatusDropdown({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<String>(
      key: key,
      label: 'order status',
      initialValue: initialValue,
      items: purchaseOrderStatus,
      getDisplayText: (status) => status,
      onChanged: onChanged,
    );
  }
}
