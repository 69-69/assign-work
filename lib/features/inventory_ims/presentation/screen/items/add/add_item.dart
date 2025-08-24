import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/barcode_scanner.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/item/item_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/items/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AddItemForm on BuildContext {
  Future<void> openAddItem() => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(title: 'Add New Item', body: _AddItemForm()),
  );
}

class _AddItemForm extends StatefulWidget {
  const _AddItemForm();

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final ScrollController _scrollController = ScrollController();
  bool isMultipleOrders = false;
  final List<Item> _items = [];

  String? _selectedCategory;
  String? _selectedSupplierId;
  DateTime? _selectedExpiryDate;
  DateTime? _selectedManufactureDate;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _batchIdController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _inStockController = TextEditingController();
  final _quantityController = TextEditingController();
  final _discountPercentController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _batchIdController.dispose();
    _discountPercentController.dispose();
    _sellingPriceController.dispose();
    _inStockController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _manufacturerController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Item get _itemData => Item(
    name: _nameController.text,
    sku: _skuController.text,
    batchId: _batchIdController.text,
    supplierId: _selectedSupplierId ?? '',
    barcode: _barcodeController.text,
    category: _selectedCategory ?? '',
    costPrice: double.parse(_costPriceController.text),
    sellingPrice: double.parse(_sellingPriceController.text),
    inStock: int.parse(_inStockController.text),
    quantity: int.parse(_quantityController.text),
    discountPercent: double.tryParse(_discountPercentController.text) ?? 0.0,
    expiryDate: _selectedExpiryDate,
    manufactureDate: _selectedManufactureDate,
    manufacturer: _manufacturerController.text,
    remarks: _remarksController.text,
    storeNumber: context.employee!.storeNumber,
    createdBy: context.employee!.fullName,
  );

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      /// Added Multiple Products Simultaneously
      _items.add(_itemData);

      // Add new product to stock
      /// Pass 'documentId' as auto, for Firestore to auto-assign unique document-Id
      context.read<ItemBloc>().add(AddInventory<List<Item>>(data: _items));

      _formKey.currentState!.reset();
      _clearFields();
      isMultipleOrders = false;

      context.showAlertOverlay('Products successfully added');

      Navigator.of(context).pop();
    }
  }

  /// Function for Adding Multiple Products Simultaneously
  void _addProductToList() {
    if (_formKey.currentState!.validate()) {
      setState(() => isMultipleOrders = true);
      _items.add(_itemData);

      context.showAlertOverlay(
        '${_nameController.text.toTitleCase} added to batch',
      );
      _clearFields();
    }
  }

  void _clearFields() {
    _nameController.clear();
    _barcodeController.clear();
    _sellingPriceController.clear();
    _costPriceController.clear();
    _inStockController.clear();
    _quantityController.clear();
    _selectedExpiryDate = null;
    _selectedManufactureDate = null;
  }

  void _removeProductFromBatch(Item product) {
    setState(() => _items.remove(product));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Wrap(
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          if (isMultipleOrders && _items.isNotEmpty) _buildBatchPreviewChips(),
          _buildBody(),
        ],
      ),
    );
  }

  // Horizontal scrollable row of chips representing the List of batches
  Widget _buildBatchPreviewChips() {
    return CustomScrollBar(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _items.map((o) {
          return o.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Chip(
                    padding: EdgeInsets.zero,
                    label: Text(
                      '${o.name} - $ghanaCedis${o.sellingPrice}'.toTitleCase,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    deleteButtonTooltipMessage: 'Remove ${o.name}',
                    backgroundColor: kGrayColor.toAlpha(0.3),
                    deleteIcon: const Icon(
                      size: 16,
                      Icons.clear,
                      color: kGrayColor,
                    ),
                    onDeleted: () => _removeProductFromBatch(o),
                  ),
                );
        }).toList(),
      ),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Product Info', style: context.textTheme.titleLarge),
        const SizedBox(height: 20.0),
        BatchIdAndSKUInput(
          batchController: _batchIdController,
          skuController: _skuController,
          onBatchChanged: (i) {
            if (_formKey.currentState?.validate() ?? false) {
              setState(() {});
            }
          },
          onSkuChanged: (i) {
            if (_formKey.currentState?.validate() ?? false) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 20.0),
        NameAndSupplierIDInput(
          nameController: _nameController,
          onNameChanged: (i) {
            if (_formKey.currentState!.validate()) {
              setState(() {});
            }
          },
          onSupplierIdChange: (id, name) =>
              setState(() => _selectedSupplierId = id),
        ),
        const SizedBox(height: 20.0),
        CostAndSellingPriceInput(
          costPriceController: _costPriceController,
          sellingPriceController: _sellingPriceController,
          onCostPriceChanged: (i) {
            if (_formKey.currentState!.validate()) {
              setState(() {});
            }
          },
          onSellingPriceChanged: (i) {
            if (_formKey.currentState!.validate()) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 20.0),
        DiscountPercentAndCategory(
          discountController: _discountPercentController,
          onCategoryChange: (id, category) =>
              setState(() => _selectedCategory = category),
          onDiscountChanged: (i) {
            if (_formKey.currentState!.validate()) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 20.0),
        InStockAndQuantityInput(
          inStockController: _inStockController,
          qtyController: _quantityController,
          onInStockChanged: (i) {
            if (_formKey.currentState!.validate()) {
              setState(() {});
            }
          },
          onQtyChanged: (s) {
            if (_formKey.currentState!.validate()) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 20.0),
        ExpiryAndManufactureDateInput(
          labelExpiry: "Expiry date",
          labelManufacture: "Manufacture date",
          onExpiryChanged: (date) => setState(() => _selectedExpiryDate = date),
          onManufactureChanged: (date) =>
              setState(() => _selectedManufactureDate = date),
        ),
        const SizedBox(height: 20.0),
        BarcodeScannerWithTextField(
          controller: _barcodeController,
          onChanged: (t) => setState(() {}),
        ),
        const SizedBox(height: 20.0),
        RemarksAndManufacturerTextField(
          remarksController: _remarksController,
          manufacturerController: _manufacturerController,
          onManufacturerChanged: (s) {
            if (_formKey.currentState!.validate()) {
              setState(() {});
            }
          },
          onRemarksChanged: (s) {
            if (_formKey.currentState!.validate()) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 20.0),
        context.elevatedIconBtn(
          Icons.add,
          onPressed: _addProductToList,
          label: 'Add to List',
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          label: isMultipleOrders ? 'Create All Products' : 'Create Product',
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}
