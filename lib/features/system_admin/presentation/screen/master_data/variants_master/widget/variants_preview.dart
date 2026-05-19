import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/variant_attr_ext.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/variant_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/variant_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/pricing_discount_master/create/create_price_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension VariantPreviewExt on BuildContext {
  Future showVariantPreview({
    required String itemCode,
    required List<Map<String, Attribute>> variants,
  }) async => await openBottomSheet(
    // isExpand: false,
    showZoomIcon: false,
    barrierColor: kTransparentColor,
    // constraints: BoxConstraints(maxWidth: dynamicWidth(0.5)),
    child: BottomSheetScaffold(
      isShadow: true,
      title: 'Preview Variants',
      isDetailMode: true,
      initialSize: 0.6,
      body: VariantTable(variants: variants, itemCode: itemCode),
    ),
  );
}

class VariantTable extends StatefulWidget {
  final String itemCode;
  final List<Map<String, Attribute>> variants;

  const VariantTable({
    super.key,
    required this.variants,
    required this.itemCode,
  });

  @override
  State<VariantTable> createState() => _VariantTableState();
}

class _VariantTableState extends State<VariantTable> {
  bool _isSubmitting = false;
  String get _itemCode => widget.itemCode;
  final Map<String, double> _sellingPrices = {};
  String get _employeeName => context.employee!.fullName;
  List<Map<String, Attribute>> get _variants => widget.variants;
  bool get _allPricesSet => _sellingPrices.length == _variants.length;

  VariantBloc get _bloc => context.read<VariantBloc>();

  String get _missingCount {
    final missing = _variants.where((e) {
      final sku = _buildSku(e);
      return !_sellingPrices.containsKey(sku);
    }).length;

    return missing == 0 ? '' : ' ($missing missing prices)';
  }

  String _buildSku(Map<String, Attribute> entry) {
    return Variant.buildSKU(_itemCode, entry.toCodeMap()).itemSKU;
  }

  void _saveAllVariants() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final variantsToSave = Variant.buildVariants(
      itemCode: _itemCode,
      variants: _variants,
    );
    prettyPrint('label-variantsToSave', variantsToSave);

    final newVariants = variantsToSave
        .map((e) => e.copyWith(history: history()))
        .toList();

    _bloc.add(AddSetup<List<Variant>>(data: newVariants));
    return;
  }

  List<AuditLog> history() => [
    AuditLog(action: AuditAction.created, actionBy: _employeeName),
  ];

  void _showAlert(String msg) =>
      context.showAlertOverlay(msg, onCallback: () => _resetForm());

  void _handleBlocState(BuildContext cxt, SetupState<Variant> state) {
    switch (state) {
      case SetupAdded<Variant>(message: var msg):
        _showAlert(msg ?? 'Variant successfully saved');
      case SetupError<Variant>():
        _showAlert('Something went wrong! Please try again');
      case _: // no action
    }
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _sellingPrices.clear();
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = _variants.firstOrNull;

    if (first == null) {
      return const Center(child: Text('No variants available'));
    }
    final isDemo = _itemCode.toLowerAll.startsWith('demo-');

    return BlocListener<VariantBloc, SetupState<Variant>>(
      listener: _handleBlocState,
      child: Column(
        children: [
          _buildTable(first),

          if(!isDemo)
            context.confirmableActionButton(
              isDisabled: !_allPricesSet,
              label: 'Save All Variants$_missingCount',
              onPressed: _allPricesSet ? _saveAllVariants : null,
            ),
        ],
      ),
    );
  }

  Widget _buildTable(Map<String, Attribute> first) {
    final keyList = first.keys.toList()
      ..sortByComparable((e) => attributePriorities[e] ?? 999);

    final columnLabels = [
      'Price',
      'Item Code',
      ...keyList.map((k) => k.toTitle),
      'SKU',
    ];
    final allSkus = _variants.map(_buildSku).toSet().toList();

    return SortableHistoryTable<Map<String, Attribute>>(
      columnLabels: columnLabels,
      items: _variants,
      rowBuilder: (entry, index) {
        final sku = _buildSku(entry);
        final price = _sellingPrices[sku]?.toString();
        final isPriceNull = price == null;

        return DataRow(
          cells: [
            DataCell(
              ActionChip(
                label: Text(price ?? 'Set Price'),
                tooltip: isPriceNull
                    ? 'Set prices for all variants'
                    : 'Edit this price',
                avatar: isPriceNull ? null : const Icon(Icons.edit, size: 18),
                onPressed: () async {
                  await context.openAddPriceEntry(
                    isChangePrice: !isPriceNull,
                    variantSKUs: isPriceNull ? allSkus : [sku],
                    onPriceCreated: ({required Map<String, double> prices}) {
                      if (prices.isNotEmpty) {
                        setState(() => _sellingPrices.addAll(prices));
                      }
                    },
                  );
                },
              ),
            ),

            DataCell(Text(_itemCode.toUpperAll)),

            ...keyList.map(
              (k) => DataCell(Text(entry[k]?.value.toTitle ?? '')),
            ),

            DataCell(Text(sku.toUpperAll)),
          ],
        );
      },
    );
  }
}

/*
return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DataTable(
          columns: [
            ...keyList.map((k) => DataColumn(label: Text(k.toTitle))),
            const DataColumn(label: Text("SKU")),
          ],
          rows: _variants.map((variant) {
            final itemSKU = 'TS-001';
            final sku = Variant.buildSku(itemSKU, variant);


            return DataRow(
              cells: [
                ...keyList.map(
                  (k) => DataCell(Text(variant[k]?.toUpperAll ?? "")),
                ),
                DataCell(Text(sku.toUpperAll)),
              ],
            );
          }).toList(),
        ),
      ],
}
    );*/
