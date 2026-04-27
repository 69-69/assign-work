import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/variant_attr_ext.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/block_quote.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/variant_model.dart';
import 'package:flutter/material.dart';

extension VariantPreviewExt on BuildContext {
  Future showVariantPreview({
    required String itemCode,
    required List<Map<String, Attribute>> variants,
  }) async => await openBottomSheet(
    isExpand: false,
    showZoomIcon: false,
    constraints: BoxConstraints(maxWidth: dynamicWidth(0.5)),
    child: BottomSheetScaffold(
      title: 'Preview Variants',
      isDetailMode: true,
      initialSize: 0.6,
      body: VariantTable(variants: variants, itemCode: itemCode),
    ),
  );
}

class VariantsPreview extends StatelessWidget {
  final String itemCode;
  final List<Map<String, Attribute>> variants;

  const VariantsPreview({
    super.key,
    required this.variants,
    required this.itemCode,
  });

  @override
  Widget build(BuildContext context) {
    return FormGroupCard(
      title: 'Preview Variants',
      subTitle:
          '\nAutomatically generated combinations based on your selections.',
      showCollapseButton: false,
      children: [_buildBody()],
    );
  }

  StatelessWidget _buildBody() {
    if (variants.isEmpty) {
      return BlockQuote(
        child: Text('Select attributes to preview generated variants here.'),
      );
    }

    return VariantTable(variants: variants, itemCode: itemCode);
  }
}

class VariantTable extends StatelessWidget {
  final String itemCode;
  final List<Map<String, Attribute>> variants;

  const VariantTable({
    super.key,
    required this.variants,
    required this.itemCode,
  });


  void _onSubmit() {
      final variantsToSave = Variant.buildVariants(
        itemCode: "TS-001",
        variants: variants.map((v) => v.toCodeMap()).toList(),
      );
      prettyPrint('variants-To-Save', variantsToSave);

      // _bloc.add(AddSetup<List<Variant>>(data: variantsToSave));
      return;
    }

  @override
  Widget build(BuildContext context) {
    final keyList = variants.first.keys.toList()
      ..sortByComparable((e) => attributePriorities[e] ?? 999);

    final columnLabels = [...keyList.map((k) => k.toTitle), 'SKU'];

    return SortableHistoryTable<Map<String, Attribute>>(
      columnLabels: columnLabels,
      items: variants,
      rowBuilder: (entry, index) {
        final sku = Variant.buildVariantSKU(itemCode, entry.toCodeMap());

        final cells = <DataCell>[
          ...keyList.map((k) => DataCell(Text(entry[k]?.value.toTitle ?? ""))),
          DataCell(Text(sku.toUpperAll)),
        ];

        return DataRow(cells: cells);
      },
    );
  }

  /*return Column(
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
    );*/
}
