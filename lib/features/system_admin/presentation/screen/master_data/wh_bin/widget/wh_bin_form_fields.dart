import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/form/dynamic_checkbox_list.dart';
import 'package:assign_erp/core/widgets/form/category_picker.dart';
import 'package:assign_erp/core/widgets/form/uom_dropdown.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/wh_location/widget/search_wh_locations.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/inventory_form_fields.dart';
import 'package:flutter/material.dart';

class WHBinFormFields {
  static Widget buildBinNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => InventoryFormFields.buildNumber(
    context,
    count: count,
    what: 'Bin Code',
    onPressed: onPressed,
  );

  static Widget stackTextField(
    BuildContext context, {
    Key? key,
    String? label,
    String? helperText,
    bool enable = false,
    bool showProgress = false,
    void Function()? onPressed,
    InputDecoration? decoration,
    void Function(String)? onChanged,
    TextEditingController? controller,
  }) => Stack(
    alignment: Alignment.topRight,
    children: <Widget>[
      CustomTextField(
        key: key,
        label: label,
        enabled: enable,
        autofocus: enable,
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.text,
        inputDecoration:
            decoration ??
            InputDecoration(helperText: helperText, labelText: label),
      ),

      Padding(
        padding: EdgeInsets.all(3),
        child: FittedBox(
          child: context.toolbarButton(
            label: showProgress ? 'Saving' : (enable ? 'Done' : 'Edit'),
            icon: showProgress
                ? _progressIcon
                : (enable ? Icons.done : Icons.edit),
            bgColor: kPrimaryColor.toAlpha(enable ? 0.8 : 0.3),
            onPressed: onPressed,
          ),
        ),
      ),
    ],
  );

  static Widget get _progressIcon => SizedBox(
    width: 10,
    height: 10,
    child: AsyncProgressBarDialog(size: 10, isDialog: false, strokeWidth: 2),
  );

  static List<FieldGroupConfig> whBinFields() => [
    FieldGroupConfig(
      key: 'description',
      label: 'Description',
      type: TextInputType.text,
      widgetType: FieldWidgetType.textField,
      helperText:
          'Physical slot inside a location (e.g., Shelf A01, Slot B03).',
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'sequence',
      label: 'Display Order',
      type: TextInputType.number,
      widgetType: FieldWidgetType.textField,
      helperText:
          'The sequence in which this bin appears in lists or pick routes (optional)',
      validator: (_) => null,
    ),
    FieldGroupConfig(
      key: 'isActive',
      label: 'Configuration Options',
      isNested: true,
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DynamicCheckboxList(
          initialData: [
            {'isActive': initialData},
          ],
          checkboxesConfig: [
            CheckboxGroupConfig(
              key: 'isActive',
              label: 'Active',
              // selected: initial?['isActive'] ?? true,
              tooltip: 'Enable or disable this bin',
              description:
                  'Turn this on if the bin is currently in use for storing items.',
            ),
          ],
          onCheckChanged: (List<CheckboxGroupConfig> selected) {
            final mapList = CheckboxGroupConfig.mapCheckboxes(selected);
            onChanged(mapList);
          },
        );
      },
    ),
    FieldGroupConfig(
      key: 'minQuantity',
      label: 'Minimum Quantity',
      helperText:
          'Min. quantity that trigger replenishment alert if below this.',
      type: TextInputType.number,
    ),
    FieldGroupConfig(
      key: 'units-title',
      label: 'Storage Units',
      helperText:
          '\nConfigure bins or shelves, including capacity and handling rules.',
      widgetType: FieldWidgetType.titleOnly,
    ),
    FieldGroupConfig(
      key: 'maxQuantity',
      label: 'Maximum Items',
      helperText: 'Maximum number of items this bin or shelf can store.',
      type: TextInputType.number,
      widgetType: FieldWidgetType.textField,
    ),
    FieldGroupConfig(
      key: 'maxVolume',
      label: 'Maximum Weight',
      helperText: 'Maximum total weight this bin or shelf can safely hold.',
      type: TextInputType.number,
    ),
    FieldGroupConfig(
      key: 'uomRestriction',
      label: 'UoM Restriction',
      helperText: 'Units of measure allowed in this sub-location.',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return UOMMultiDropdown(
          label: 'UoM Restriction',
          initialValues: List.from(initialData ?? []),
          onMultiChanged: onChanged,
        );
      },
    ),
    /// @TODO - remove and replace with remote categories
    FieldGroupConfig(
      key: 'itemRestriction',
      label: 'Item Restriction',
      helperText: 'Items allowed in this sub-location.',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return CategoryPicker(
          isService: false,
          label: 'Item Restriction',
          initialValues: List.from(initialData ?? []),
          onMultiChanged: onChanged,
        );
      },
    ),
  ];

  static List<FieldGroupConfig> whBinLocationCodesFields({
    List<Map<String, dynamic>>? subLocations,
  }) {
    if (subLocations == null || subLocations.isEmpty) return [];

    return subLocations.expand((e) {
      final type = e['type'];
      final codeRanges = e['codeRanges'];

      return [
        _codeRangeField(
          key: '${type}_from',
          label: 'From (Start)',
          helperText: 'Starting sub-location code (e.g., A1).',
          codeRanges: codeRanges,
        ),
        _codeRangeField(
          key: '${type}_to',
          label: 'To (End)',
          helperText: 'Ending sub-location code (e.g., A20).',
          codeRanges: codeRanges,
        ),
      ];
    }).toList();
  }

  static FieldGroupConfig _codeRangeField({
    required String key,
    required String label,
    required String helperText,
    required List<String> codeRanges,
  }) {
    return FieldGroupConfig(
      key: key,
      label: label,
      helperText: helperText,
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return SearchSubLocationCodes(
          label: label,
          initialValue: initialData,
          subLocCodes: codeRanges,
          onChanged: (code) => onChanged(code),
        );
      },
    );
  }

  static SortableHistoryTable<String> listBinLocations({
    String? title,
    String desc = '',
    int? editingIndex,
    bool savingPerEdit = false,
    List<String> codes = const [],
    required BuildContext context,
    required Map<int, TextEditingController> controllers,
    required void Function(bool, int, TextEditingController) onEdit,
  }) {
    return SortableHistoryTable<String>(
      items: codes,
      columnLabels: ['#', 'Description', title ?? 'Codes'],
      rowBuilder: (entry, index) {
        final i = index + 1;
        final isEditing = editingIndex == index;
        final controller = _getController(index, entry, controllers);

        return DataRow(
          cells: [
            DataCell(Text('$i')),
            DataCell(Text('$desc $i')),
            DataCell(
              WHBinFormFields.stackTextField(
                context,
                key: ValueKey('code-$index'),
                controller: controller,
                enable: isEditing,
                showProgress: isEditing && savingPerEdit,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  labelText: 'Code',
                ),
                onPressed: () => onEdit(isEditing, index, controller),
              ),
            ),
          ],
        );
      },
    );
  }

  static TextEditingController _getController(
    int index,
    String value,
    Map<int, TextEditingController> cons,
  ) {
    return cons.putIfAbsent(index, () => TextEditingController(text: value));
  }

  /// Updates the [list] with objects of type [T] from a list of maps.
  /// Clears the list first to prevent duplication, then adds new objects.
  /// [fromMap] converts each map entry into an object with the index as the ID.
  static updateListFromData<T>(
    List<T> list, {
    required List<Map<String, dynamic>> map,
    required T Function(Map<String, dynamic>, String) fromMap,
  }) =>
      InventoryFormFields.updateListFromData(list, map: map, fromMap: fromMap);
}
