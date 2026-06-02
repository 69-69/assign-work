import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/widget/attribute_selector.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/widget/variants_preview.dart';
import 'package:flutter/material.dart';

extension ExploreVariants<T> on BuildContext {
  Future<void> openVariantPlayground({
    Map<String, List<Attribute>>? groupedAttrs,
  }) => openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetailMode: true,
      title: 'Variants Playground',
      subtitle: '(Demo Mode)',
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
            FormGroupCard(
                runSpacing: 8,
                isExpanded: true,
              title: 'Attribute Set',
              subTitle: '\nSelect attribute values (e.g., Red, Large) to generate product variants',
                contentMargin: EdgeInsets.symmetric(vertical: 10),
              children: [
                AttributePanel(
                generatedVariants: (v) {
                  setState(() => _variants = v);
                },
              ),]
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExploreVariants() {
    return FormGroupCard(
      title: 'Preview Variants',
      subTitle: '\nAutomatically generated variants based on your selections.',
      showCollapseButton: false,
      children: [
        _variants.isEmpty
            ? Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'Select attributes to preview generated variants',
                  style: TextStyle(color: kGrayBlueColor),
                ),
              )
            : VariantTable(variants: _variants, itemCode: _demoItemCode),
      ],
    );
  }
}
