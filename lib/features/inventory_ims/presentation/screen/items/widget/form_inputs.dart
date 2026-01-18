import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_supplier/supplier_account/widget/search_suppliers.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/ref_master/widget/search_category.dart';
import 'package:flutter/material.dart';

/// Cost Price & Selling Price TextField [CostAndSellingPriceInput]
class CostAndSellingPriceInput extends StatelessWidget {
  const CostAndSellingPriceInput({
    super.key,
    required this.sellingPriceController,
    required this.costPriceController,
    this.onSellingPriceChanged,
    this.onCostPriceChanged,
  });

  final TextEditingController sellingPriceController;
  final TextEditingController costPriceController;
  final ValueChanged? onSellingPriceChanged;
  final ValueChanged? onCostPriceChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CostPriceTextField(
          controller: costPriceController,
          onChanged: onCostPriceChanged,
        ),
        SellingPriceTextField(
          controller: sellingPriceController,
          onChanged: onSellingPriceChanged,
        ),
      ],
    );
  }
}

/// Name & Category TextField/Dropdown [NameAndSupplierIDInput]
class NameAndSupplierIDInput extends StatelessWidget {
  const NameAndSupplierIDInput({
    super.key,
    required this.onSupplierIdChange,
    required this.nameController,
    this.initialSupplierId,
    this.onNameChanged,
  });

  final TextEditingController nameController;
  final ValueChanged? onNameChanged;
  final Function(String, String) onSupplierIdChange;
  final String? initialSupplierId;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        NameTextField(controller: nameController, onChanged: onNameChanged),
        SearchSuppliers(
          initialSupplier: initialSupplierId,
          onSupplierChanged: onSupplierIdChange,
        ),
      ],
    );
  }
}

/// Discount-Percent & Category TextField/Dropdown [DiscountPercentAndCategory]
class DiscountPercentAndCategory extends StatelessWidget {
  const DiscountPercentAndCategory({
    super.key,
    required this.onCategoryChange,
    required this.discountController,
    this.initialCategory,
    this.onDiscountChanged,
  });

  final TextEditingController discountController;
  final ValueChanged? onDiscountChanged;
  final Function(String, String) onCategoryChange;
  final String? initialCategory;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextField(
          label: 'Discount Percent',
          helperText: 'Optional',
          onChanged: onDiscountChanged,
          controller: discountController,
          keyboardType: TextInputType.number,
          validator: (v) => null,
        ),
        CategoryDropdown(
          initialValue: initialCategory,
          onChange: onCategoryChange,
        ),
      ],
    );
  }
}

/// Batch-Id & Category TextField/Dropdown [BatchIdAndSKUInput]
class BatchIdAndSKUInput extends StatelessWidget {
  const BatchIdAndSKUInput({
    super.key,
    required this.batchController,
    required this.skuController,
    this.onBatchChanged,
    this.onSkuChanged,
  });

  final TextEditingController batchController;
  final TextEditingController skuController;
  final ValueChanged? onBatchChanged;
  final ValueChanged? onSkuChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BatchIdTextField(
          controller: batchController,
          onChanged: onBatchChanged,
        ),
        SKUTextField(controller: skuController, onChanged: onSkuChanged),
      ],
    );
  }
}

/// InStock & Quantity TextField [InStockAndQuantityInput]
class InStockAndQuantityInput extends StatelessWidget {
  const InStockAndQuantityInput({
    super.key,
    required this.inStockController,
    required this.qtyController,
    this.onInStockChanged,
    this.onQtyChanged,
  });

  final TextEditingController inStockController;
  final TextEditingController qtyController;
  final ValueChanged? onInStockChanged;
  final ValueChanged? onQtyChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InStockTextField(
          controller: inStockController,
          onChanged: onInStockChanged,
        ),
        QuantityTextField(controller: qtyController, onChanged: onQtyChanged),
      ],
    );
  }
}

/// Expiry & Manufacture Date TextField [ExpiryAndManufactureDateInput]
class ExpiryAndManufactureDateInput extends StatelessWidget {
  const ExpiryAndManufactureDateInput({
    super.key,
    this.labelExpiry,
    this.labelManufacture,
    this.onQuantityChanged,
    required this.onExpiryChanged,
    required this.onManufactureChanged,
    this.initialExpiry,
    this.initialManuDate, // manufacture date
  });

  final String? initialExpiry;
  final String? initialManuDate;
  final String? labelExpiry;
  final String? labelManufacture;
  final ValueChanged? onQuantityChanged;
  final Function(DateTime) onExpiryChanged;
  final Function(DateTime) onManufactureChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DatePicker(
          initialDate: initialManuDate,
          label: labelManufacture,
          restorationId: 'Manufacture date',
          selectedDate: onManufactureChanged,
        ),
        DatePicker(
          initialDate: initialExpiry,
          label: labelExpiry,
          restorationId: 'Expiry date',
          selectedDate: onExpiryChanged,
        ),
      ],
    );
  }
}

/// Remarks & Manufacturer TextField [RemarksAndManufacturerTextField]
class RemarksAndManufacturerTextField extends StatelessWidget {
  final TextEditingController? remarksController;
  final ValueChanged? onRemarksChanged;
  final TextEditingController? manufacturerController;
  final ValueChanged? onManufacturerChanged;

  const RemarksAndManufacturerTextField({
    super.key,
    this.remarksController,
    this.onRemarksChanged,
    this.manufacturerController,
    this.onManufacturerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ManufacturerTextField(
          controller: manufacturerController,
          onChanged: onManufacturerChanged,
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

/// [NameTextField]
class NameTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const NameTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Name',
      onChanged: onChanged,
      controller: controller,
      keyboardType: TextInputType.text,
    );
  }
}

/// [CostPriceTextField]
class CostPriceTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const CostPriceTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Cost Price',
      helperText: 'Manufacturer Price',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
    );
  }
}

/// [SellingPriceTextField]
class SellingPriceTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const SellingPriceTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Selling Price',
      helperText: 'Unit Price',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
    );
  }
}

/// [InStockTextField]
class InStockTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const InStockTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'In Stock',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
    );
  }
}

/// [BatchIdTextField]
class BatchIdTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const BatchIdTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Batch ID - Optional',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
      validator: (s) => null,
    );
  }
}

/// [SKUTextField]
class SKUTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const SKUTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'SKU - Optional',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
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

/// [ManufacturerTextField]
class ManufacturerTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const ManufacturerTextField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Manufacturer Name or ID',
      helperText: 'Optional',
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
      validator: (v) => null,
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

/// Product Types [CategoryDropdown]
class CategoryDropdown extends StatelessWidget {
  final String? initialValue;
  final Function(String, String) onChange;

  // final ValueChanged onChange;

  const CategoryDropdown({
    super.key,
    required this.onChange,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return SearchCategory(
      initialValue: initialValue,
      onChanged: (id, category) => onChange(id, category),
    );
    /*return CustomDropdown(
      key: key,
      items: category,
      labelText: 'category',
      initialValue: initialValue,
      onValueChange: (String? v) => onChange(v),
    );*/
  }
}
