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
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/price_list_master/create/create_price_entry.dart';
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
  Map<String, double> _sellingPrices = {};

  VariantBloc get _bloc => context.read<VariantBloc>();

  String get _employeeName => context.employee!.fullName;

  List<Map<String, Attribute>> get _variants => widget.variants;

  bool get _allPricesSet => _sellingPrices.length == _variants.length;

  String get _missingCount {
    final missing = _variants.where((e) {
      final sku = _buildSku(e);
      return !_sellingPrices.containsKey(sku);
    }).length;

    return missing == 0 ? '' : ' ($missing missing prices)';
  }

  // ---------------------------
  // CORE: SKU GENERATION
  // ---------------------------
  String _buildSku(Map<String, Attribute> entry) {
    return Variant.buildSKU(widget.itemCode, entry.toCodeMap()).itemSKU;
  }

  // ---------------------------
  // AUDIT HISTORY
  // ---------------------------
  List<AuditLog> history() => [
    AuditLog(action: AuditAction.created, actionBy: _employeeName),
  ];

  // ---------------------------
  // SAVE ALL VARIANTS
  // ---------------------------
  void _saveAllVariants() {
    final variantsToSave = Variant.buildVariants(
      itemCode: widget.itemCode,
      variants: _variants.map((v) => v.toCodeMap()).toList(),
    );
    final newVariants = variantsToSave
        .map((e) => e.copyWith(history: history()))
        .toList();

    _bloc.add(AddSetup<List<Variant>>(data: newVariants));
    return;
  }

  // ---------------------------
  // ALERT
  // ---------------------------
  void _showAlert(String msg) =>
      context.showAlertOverlay(msg, onCallback: () => Navigator.pop(context));

  void _handleBlocState(BuildContext cxt, SetupState<Variant> state) {
    switch (state) {
      case SetupAdded<Variant>(message: var msg):
        _showAlert(msg ?? 'Variant successfully saved');

      case SetupError<Variant>():
        _showAlert('Something went wrong! Please try again');

      case _:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = _variants.firstOrNull;

    if (first == null) {
      return const Center(child: Text('No variants available'));
    }

    return BlocListener<VariantBloc, SetupState<Variant>>(
      listener: _handleBlocState,
      child: Column(
        children: [
          _buildTable(first),

          context.confirmableActionButton(
            isDisabled: !_allPricesSet,
            label: 'Save All Variants$_missingCount',
            onPressed: _allPricesSet ? _saveAllVariants : null,
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // TABLE
  // ---------------------------
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

        return DataRow(
          cells: [
            DataCell(
              Chip(label: Text(_sellingPrices[sku]?.toString() ?? 'Set Price')),
              onTap: () async {
                await context.openAddPriceEntry(
                  variantSKUs: allSkus,
                  onPriceCreated: ({required Map<String, double> prices}) {
                    if (prices.isNotEmpty) {
                      prettyPrint('label-price', allSkus);
                      setState(() => _sellingPrices = prices);
                    }
                  },
                );
              },
            ),
            DataCell(Text(widget.itemCode.toUpperAll)),

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
