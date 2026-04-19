import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/extensions/line_item_type.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_dialog.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:flutter/material.dart';

extension LineItemChoicePopUp on BuildContext {
  Future openMaterialOrServiceToggle([
    String procureType = 'line item',
  ]) async => await MaterialOrServiceChoice(
    procureType: procureType,
  ).openCustomDialog(this, isScrollControlled: true, constraints: null);
}

class MaterialOrServiceChoice extends StatefulWidget {
  final String procureType;

  const MaterialOrServiceChoice({super.key, required this.procureType});

  @override
  State<MaterialOrServiceChoice> createState() =>
      _MaterialOrServiceChoiceState();
}

class _MaterialOrServiceChoiceState extends State<MaterialOrServiceChoice> {
  String? selectedType;

  get _procureType => widget.procureType;

  @override
  Widget build(BuildContext context) {
    return _buildAlertDialog(context);
  }

  _buildAlertDialog(BuildContext context) {
    return CustomDialog(
      bgColor: context.scaffoldBgColor,
      title: DialogTitle(
        title: 'Product or Service?',
        subtitle:
            'Select whether this $_procureType is a Material (Product) or Service?',
      ),
      body: _buildBody(context),
      actions: [
        context.confirmableActionButton(
          label: "Continue",
          onPressed: selectedType.isNullOrEmpty
              ? null
              : () => Navigator.pop(context, selectedType),
          isDisabled: selectedType == null,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final types = LineItemTypeUtil.toStringList(false);

    return Container(
      width: context.screenWidth,
      padding: EdgeInsets.only(bottom: context.bottomInsetPadding),
      child: AdaptiveLayout(
        children: types.map((type) {
          final isSelected = selectedType == type;

          final material = LineItemTypeUtil.isMaterial(type);

          final baseColor = _baseColor(material);
          final color = isSelected ? baseColor : context.outlineColor;

          return ChoiceChip(
            selected: isSelected,
            tooltip: type.toSentence,
            padding: EdgeInsets.all(30),
            selectedColor: baseColor.toAlpha(0.15),
            checkmarkColor: baseColor,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  material ? Icons.shopping_bag : Icons.work,
                  color: color,
                  size: 20,
                  semanticLabel: 'line item type: $type',
                ),
                SizedBox(width: 4),
                RichText(
                  text: TextSpan(
                    text: type.toUpperAll,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: material ? '\n(Product)' : '\n(Work)',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            onSelected: (_) => setState(() => selectedType = type),
          );
        }).toList(),
      ),
    );
  }

  Color _baseColor(bool isMaterial) {
    return switch (isMaterial) {
      true => kPrimaryAccentColor,
      false => kDangerColor,
    };
  }
}
