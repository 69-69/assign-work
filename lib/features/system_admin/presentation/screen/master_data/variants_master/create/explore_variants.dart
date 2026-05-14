import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/block_quote.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/widget/attribute_selector.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/widget/variants_preview.dart';
import 'package:flutter/material.dart';

extension ExploreVariants<T> on BuildContext {
  Future<void> openExploreVariant({
    Map<String, List<Attribute>>? groupedAttrs,
  }) => openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetailMode: true,
      title: 'Variants Playground',
      body: _VariantsPlayground(groupedAttrs: groupedAttrs),
    ),
  );
}

class _VariantsPlayground extends StatefulWidget {
  final Map<String, List<Attribute>>? groupedAttrs;

  const _VariantsPlayground({this.groupedAttrs});

  @override
  State<_VariantsPlayground> createState() => _VariantsPlaygroundState();
}

class _VariantsPlaygroundState extends State<_VariantsPlayground> {
  final _demoItemCode = "DEMO-001";
  List<Map<String, Attribute>> _variants = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdaptiveLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExploreVariants(),
            AttributePanel(
              isExpanded: true,
              generatedVariants: (v) {
                setState(() => _variants = v);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExploreVariants() {
    if (_variants.isEmpty) {
      return BlockQuote(
        child: Text('Select attributes to preview generated variants here.'),
      );
    }

    return FormGroupCard(
      title: 'Preview Variants',
      subTitle: '\nAutomatically generated variants based on your selections.',
      showCollapseButton: false,
      children: [VariantTable(variants: _variants, itemCode: _demoItemCode)],
    );
  }
}
