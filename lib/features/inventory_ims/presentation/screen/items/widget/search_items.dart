import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/inventory_ims/data/data_sources/remote/get_items.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_model.dart';
import 'package:flutter/material.dart';

/// Search Items to add to Order Processing [SearchItems]
class SearchItems extends StatefulWidget {
  const SearchItems({
    super.key,
    this.onChanged,
    this.initialValue,
    this.isDropdown = false,
  });

  final bool isDropdown;
  final String? initialValue;
  final ValueChanged? onChanged;

  @override
  State<SearchItems> createState() => _SearchItemsState();
}

class _SearchItemsState extends State<SearchItems> {
  bool _isNotFound = false;

  void _toggleManualEntry([bool value = true]) {
    if (mounted) setState(() => _isNotFound = value);
  }

  @override
  Widget build(BuildContext context) {
    return widget.isDropdown
        ? (_isNotFound
              ? _buildManualEntryField(context)
              : _buildDropdown(context))
        : _buildAppBarSearch(context);
  }

  Widget _buildDropdown(BuildContext context) => AsyncSearchDropdown<Item>(
    labelText: widget.initialValue ?? 'Select Item...',
    asyncItems: (String filter, loadProps) async =>
        await GetItems.byAnyTerm(filter),
    filterFn: (item, filter) => _handleFilter(filter, item),
    itemAsString: (Item item) => item.toString().toTitleCase,
    onChanged: (item) => widget.onChanged?.call(item),
    validator: (item) => item == null ? 'Select item' : null,
    onNoDataFound: () {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleNoDataFound(context),
      );
    },
  );

  bool _handleFilter(String filter, Item item) {
    final term = filter.isEmpty ? (widget.initialValue ?? '') : filter;
    final isFound = item.filterByAny(term);
    if (!isFound && filter.isNotEmpty) _toggleManualEntry();
    return isFound;
  }

  Widget _buildManualEntryField(BuildContext context) {
    return CustomTextField(
      onChanged: (value) => widget.onChanged?.call(value),
      keyboardType: TextInputType.text,
      inputDecoration: InputDecoration(
        labelText: 'Item name',
        suffixIcon: Padding(
          padding: const EdgeInsets.all(2.0),
          child: context.iconButton(
            Icons.arrow_back,
            tooltip: 'Back to item search',
            onPressed: () => _toggleManualEntry(false),
            bgColor: kGrayColor,
          ),
        ),
      ),
    );
  }

  Future<void> _handleNoDataFound(BuildContext context) async {
    final shouldEnterManually = await context.confirmAction<bool>(
      const Text('Do you want to enter it manually?'),
      title: 'Item not found',
    );

    if (context.mounted && shouldEnterManually) {
      _toggleManualEntry();
    }
  }

  _buildAppBarSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: context.elevatedIconBtn(
        Icon(Icons.search),
        onPressed: () async {
          // final productBloc = ProductBloc(firestore: FirebaseFirestore.instance);

          // Ensure to wait for the data to be loaded
          // final allData = await GetProducts.load();

          if (context.mounted) {
            /*showSearch(
              context: context,
              delegate: CustomSearchDelegate<Product>(
                firestoreBloc: productBloc,
                allData: allData,
                field: 'name',
                optField: 'category',
                auxField: 'expiryDate',
                hintText:'Search by name, category, expiry-date',
                onChanged: (s) {
                  Product product = s as Product;

                  context.openAddOrders(product: product);
                },
              ),
            );*/
          }
        },
        label: const Text('Find Product'),
      ),
    );
  }
}
