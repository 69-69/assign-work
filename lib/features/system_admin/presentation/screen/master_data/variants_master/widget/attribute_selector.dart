import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_attributes.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:flutter/material.dart';

typedef AttributeChanged =
    void Function({
      required bool? checked,
      required Attribute key,
      required String name,
    });

class AttributePanel extends StatefulWidget {
  final Widget? actionBuilder;
  final Function(List<Map<String, Attribute>> variants)? generatedVariants;

  const AttributePanel({
    super.key,
    this.actionBuilder,
    this.generatedVariants,
  });

  @override
  State<AttributePanel> createState() => _AttributePanelState();
}

class _AttributePanelState extends State<AttributePanel> {
  Map<String, List<Attribute>>? _groupedAttrs;
  Map<String, Map<Attribute, bool>> _selectedAttributes = {};

  Future<void> _getAttributes() async {
    final attrs = await GetAttributes.load();
    final group = Attribute.groupByType(attrs);

    setState(() => _groupedAttrs = group);

    // Initialize selection from grouped data
    if (_groupedAttrs.isNullOrEmpty) return;
    _selectedAttributes = {};

    _groupedAttrs?.forEach((key, values) {
      _selectedAttributes[key] = {for (final v in values) v: values.first == v};
    });

    _generateFromSelection();
  }

  int _calculateVariantCount(Map<String, List<Attribute>> attributes) {
    if (attributes.isEmpty) return 0;

    return attributes.values.map((e) => e.length).fold(1, (a, b) => a * b);
  }

  @override
  void initState() {
    super.initState();
    _getAttributes();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_groupedAttrs.isNullOrEmpty) ...{
          Text('Click to reload...', style: TextStyle(color: kGrayBlueColor),),
          context.iconButton(
            Icons.refresh,
            bgColor: kGrayBlueColor,
            tooltip: 'Click to reload attributes',
            onPressed: () async => await _getAttributes(),
          ),
        },
        ?widget.actionBuilder,
        ...AttributeSelector(
          context: context,
          selectedAttrs: _selectedAttributes,
          onChanged: ({checked, required key, required name}) {
            _selectedAttributes[name]![key] = checked ?? false;
            _generateFromSelection();
          },
        ).buildChildren,
      ],
    );
  }

  // Generate variants ONLY from selected values
  void _generateFromSelection() {
    final Map<String, List<Attribute>> filtered = {};

    _selectedAttributes.forEach((attr, values) {
      final selectedValues = values.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toList();

      if (selectedValues.isNotEmpty) {
        filtered[attr] = selectedValues;
      }
    });

    // Calculate BEFORE generation
    final generatedCount = _calculateVariantCount(filtered);

    // Explosion protection
    if (generatedCount > maxVariants) {
      _showVariantLimitWarning(generatedCount);

      // Clear variants to prevent further action
      widget.generatedVariants?.call([]);
      return;
    }

    final variants = _generateCartesian(filtered);
    widget.generatedVariants?.call(variants);
  }

  void _showVariantLimitWarning(int count) {
    context.showAlertOverlay(
      'Too many variants ($count). '
      'Maximum allowed is $maxVariants.',
    );
  }

  // Cartesian generator
  List<Map<String, Attribute>> _generateCartesian(
    Map<String, List<Attribute>> attributes,
  ) {
    List<Map<String, Attribute>> result = [{}];

    attributes.forEach((key, values) {
      final temp = <Map<String, Attribute>>[];

      for (final existing in result) {
        for (final value in values) {
          final map = Map<String, Attribute>.from(existing);
          map[key] = value;
          temp.add(map);
        }
      }

      result = temp;
    });

    return result;
  }
}

class AttributeSelector {
  final BuildContext context;
  final AttributeChanged? onChanged;
  final Map<String, Map<Attribute, bool>> selectedAttrs;

  const AttributeSelector({
    required this.context,
    required this.onChanged,
    required this.selectedAttrs,
  });

  List<FormGroupCard> get buildChildren {
    final entries = selectedAttrs.entries.toList();

    return List.generate(entries.length, (index) {
      final entry = entries[index];

      final attributeName = entry.key;
      final values = entry.value.entries.toList();
      final maxCross = context.screenWidth / (context.isMobile ? 1 : 8);

      return FormGroupCard(
        isExpanded: index == 0,
        title: attributeName.toTitle,
        contentMargin: EdgeInsets.zero,
        contentPadding: EdgeInsets.only(left: 10, right: 10),
        cardElevation: 0.5,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: values.length,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxCross,
              mainAxisExtent: 50,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, i) => _itemBuilder(values[i], attributeName),
          ),
        ],
      );
    });
  }

  Widget _itemBuilder(MapEntry<Attribute, bool> val, String attributeName) {
    return Tooltip(
      message: val.key.value.toTitle,
      child: CustomCheckboxTile(
        title: Text(val.key.value.toTitle, overflow: TextOverflow.ellipsis),
        value: val.value,
        onChanged: (bool? checked) => onChanged?.call(
          key: val.key,
          checked: checked,
          name: attributeName,
        ),
      ),
    );
  }
}
