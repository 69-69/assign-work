import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_enum.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/setup/presentation/screen/item_config/widget/search_suppliers.dart';
import 'package:flutter/material.dart';

/// Items Suppliers Dropdown [SuppliersDropdown]
class SuppliersDropdown extends StatelessWidget {
  const SuppliersDropdown({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  final String? initialValue;
  final Function(String, String) onChanged;

  @override
  Widget build(BuildContext context) {
    return SearchSuppliers(initialValue: initialValue, onChanged: onChanged);
  }
}

/// Suppliers & RFQStatus Dropdown TextField [SuppliersAndRFQStatusDropdown]
class SuppliersAndRFQStatusDropdown extends StatelessWidget {
  const SuppliersAndRFQStatusDropdown({
    super.key,
    this.initialStatus,
    required this.onStatusChanged,
    this.initialSupplier,
    required this.onSupplierChanged,
  });

  final String? initialStatus;
  final void Function(dynamic) onStatusChanged;
  final String? initialSupplier;
  final void Function(String, String) onSupplierChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SuppliersDropdown(
          initialValue: initialSupplier,
          onChanged: onSupplierChanged,
        ),
        RFQStatusDropdown(
          initialValue: initialStatus,
          onChange: onStatusChanged,
        ),
      ],
    );
  }
}

/// Validity & Payment Terms Dropdown TextField [ValidityAndPayTermsDropdown]
class ValidityAndPayTermsDropdown extends StatelessWidget {
  const ValidityAndPayTermsDropdown({
    super.key,
    this.onNetPriceChanged,
    required this.onPayTermsChanged,
    this.initialPayTerms,
    this.netPriceController,
    this.initialValidity,
    this.labelValidity,
    required this.onValidityChanged,
  });

  final String? initialPayTerms;
  final ValueChanged? onNetPriceChanged;
  final void Function(dynamic) onPayTermsChanged;
  final TextEditingController? netPriceController;
  final String? initialValidity;
  final String? labelValidity;
  final Function(DateTime) onValidityChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DatePicker(
          inLabel: false,
          initialDate: initialValidity,
          label: labelValidity ?? 'Validity date',
          restorationId: 'Validity date',
          selectedDate: onValidityChanged,
          helperText: 'How long the quote remains valid',
        ),
        /*NetPriceTextField(
          controller: netPriceController,
          onChanged: onNetPriceChanged,
        ),*/
        PayTermsDropdown(
          initialValue: initialPayTerms,
          onChange: onPayTermsChanged,
        ),
      ],
    );
  }
}

/// Deadline & Delivery Date TextField [DeadlineAndDeliveryDateInput]
class DeadlineAndDeliveryDateInput extends StatelessWidget {
  const DeadlineAndDeliveryDateInput({
    super.key,
    this.labelDelivery,
    this.labelDeadline,
    required this.onDeliveryChanged,
    required this.onDeadlineChanged,
    this.initialDeliveryDate,
    this.initialDeadlineDate,
  });

  final String? initialDeliveryDate;
  final String? initialDeadlineDate;
  final String? labelDelivery;
  final String? labelDeadline;
  final Function(DateTime) onDeliveryChanged;
  final Function(DateTime) onDeadlineChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DatePicker(
          inLabel: false,
          initialDate: initialDeliveryDate,
          label: labelDelivery,
          restorationId: 'Delivery date',
          selectedDate: onDeliveryChanged,
          helperText: 'Expected date for item delivery',
        ),
        DatePicker(
          inLabel: false,
          initialDate: initialDeadlineDate,
          label: labelDeadline,
          restorationId: 'Deadline date',
          selectedDate: onDeadlineChanged,
          helperText: 'Last date for supplier to submit quote.',
        ),
      ],
    );
  }
}

/// Currency Selection Dropdown [CurrencyDropdown]
class CurrencyDropdown extends StatelessWidget {
  final String? initialCurrency;
  final void Function(dynamic s) onCurrencyChanged;

  const CurrencyDropdown({
    super.key,
    this.initialCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown(
      key: key,
      items: currencyType,
      label: 'Select currency',
      initialValue: initialCurrency,
      onValueChange: (String? v) => onCurrencyChanged(v),
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
        DiscountPercentTextField(
          controller: discountController,
          discountAmount: discountAmount,
          onChanged: onDiscountChanged,
        ),
      ],
    );
  }
}

///********* TextFields *************///

/// [NetPriceTextField]
class NetPriceTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const NetPriceTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Net price',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      validator: (v) => null,
    );
  }
}

/// [DeliveryAddressTextField]
class DeliveryAddressAndNotes extends StatelessWidget {
  final TextEditingController? notesController;
  final ValueChanged? onNotesChanged;
  final TextEditingController? addressController;
  final ValueChanged? onAddressChanged;

  const DeliveryAddressAndNotes({
    super.key,
    this.addressController,
    this.onAddressChanged,
    this.notesController,
    this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DeliveryAddressTextField(
          controller: addressController,
          onChanged: onAddressChanged,
        ),
        NotesTextField(controller: notesController, onChanged: onNotesChanged),
      ],
    );
  }
}

/// [DeliveryAddressTextField]
class DeliveryAddressTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const DeliveryAddressTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Delivery address (if any)...',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.multiline,
      maxLines: 4,
      validator: (s) => null,
    );
  }
}

/// [NotesTextField]
class NotesTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const NotesTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Additional Notes (if any)...',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.multiline,
      maxLines: 4,
      validator: (s) => null,
    );
  }
}

/// [TitleAndDepartments]
class TitleAndDepartments extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;
  final String? initialDepartment;
  final void Function(dynamic s) onDepartmentChange;

  const TitleAndDepartments({
    super.key,
    this.controller,
    this.onChanged,
    this.initialDepartment,
    required this.onDepartmentChange,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextField(
          controller: controller,
          onChanged: onChanged,
          inputDecoration: InputDecoration(
            labelText: 'Title or subject...',
            helperText: 'e.g., RFQ for Office Supplies',
          ),
          keyboardType: TextInputType.none,
          validator: (s) => null,
        ),
        StaticDropdown(
          key: key,
          items: departmentsList,
          label: 'internal departments',
          inLabel: false,
          helperText: 'e.g., HR, IT, Accounting',
          initialValue: initialDepartment,
          onValueChange: (String? v) => onDepartmentChange(v),
        ),
      ],
    );
  }
}

/// Item Desc or name [itemNameTextField]
class ItemNameTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const ItemNameTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Item name...',
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

/// Request for Price Quote Status [RFQStatusDropdown]
class RFQStatusDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChange;

  const RFQStatusDropdown({
    super.key,
    required this.onChange,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown(
      key: key,
      items: requestForQuoteStatus,
      label: 'quote status',
      initialValue: initialValue,
      onValueChange: (String? v) => onChange(v),
    );
  }
}

/// Payment terms [PayTermsDropdown]
class PayTermsDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(dynamic s) onChange;

  const PayTermsDropdown({
    super.key,
    required this.onChange,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StaticDropdown(
      key: key,
      items: paymentTerms,
      label: 'payment terms',
      initialValue: initialValue,
      onValueChange: (String? v) => onChange(v),
    );
  }
}

/*
/// Quantity & RFQStatus Dropdown TextField [QuantityAndRFQStatusDropdown]
class QuantityAndRFQStatusDropdown extends StatelessWidget {
  const QuantityAndRFQStatusDropdown({
    super.key,
    this.onQuantityChanged,
    required this.onStatusChanged,
    this.initialStatus,
    this.quantityController,
  });

  final String? initialStatus;
  final ValueChanged? onQuantityChanged;
  final void Function(dynamic) onStatusChanged;
  final TextEditingController? quantityController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        QuantityTextField(
          controller: quantityController,
          onChanged: onQuantityChanged,
        ),
        RFQStatusDropdown(initialValue: initialStatus, onChange: onStatusChanged),
      ],
    );
  }
}*/
