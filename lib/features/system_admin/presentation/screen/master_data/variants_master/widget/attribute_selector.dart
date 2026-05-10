import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
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
  final String? title;
  final bool? isExpanded;
  final String? subTitle;
  final Widget? actionBuilder;
  final Function(List<Map<String, Attribute>> variants)? generatedVariants;

  const AttributePanel({
    super.key,
    this.title,
    this.subTitle,
    this.isExpanded,
    this.actionBuilder,
    this.generatedVariants,
  });

  @override
  State<AttributePanel> createState() => _AttributePanelState();
}

class _AttributePanelState extends State<AttributePanel> {
  bool? get _isExpanded => widget.isExpanded;
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

  @override
  void initState() {
    super.initState();
    _getAttributes();
  }

  @override
  Widget build(BuildContext context) {
    return FormGroupCard(
      runSpacing: 8,
      isExpanded: _isExpanded ?? true,
      showCollapseButton: _isExpanded != true,
      title: widget.title ?? 'Attribute Set',
      contentMargin: EdgeInsets.symmetric(vertical: 10),
      subTitle:
          widget.subTitle ??
          '\nSelect attribute values (e.g., Red, Large) to generate product variants.',
      children: [
        if (_groupedAttrs.isNullOrEmpty) ...{
          Center(
            child: context.iconButton(
              Icons.refresh,
              bgColor: kGrayBlueColor,
              tooltip: 'Click to reload',
              onPressed: () async => await _getAttributes(),
            ),
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

    final variants = _generateCartesian(filtered);

    // setState(() => _variants = variants);
    widget.generatedVariants?.call(variants);
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

  /*Widget _buildBody2(BuildContext context) {
    return Column(
      children: selectedAttrs.entries.map((entry) {
        final attributeName = entry.key;
        final values = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${attributeName.toTitle}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            ...values.entries.map((v) {
              return CustomCheckboxTile(
                title: Text(v.key.value.toTitle,
                  overflow: TextOverflow.ellipsis,),
                value: v.value,
                onChanged: (bool? checked) {
                  onChanged?.call(
                    checked: checked,
                    key: v.key,
                    name: attributeName,
                  );
                },
              );
            }),
          ],
        );
      }).toList(),
    );
  }*/
}
