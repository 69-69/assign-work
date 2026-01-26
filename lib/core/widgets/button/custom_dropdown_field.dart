import 'dart:async';

import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

/// Form text field [StaticDropdown]
/// A customizable dropdown widget that supports both standard
/// DropdownButtonFormField and the newer DropdownMenu UI.
///
/// Use this for selecting from a static list of options.
/// Provides optional helper text, validation, and icon support.
///
/// Set [isMenu] to true to use DropdownMenu instead of DropdownButtonFormField.
/// Set [inLabel] to false to hide the helper text in the TextField label.
class StaticDropdown<T> extends StatelessWidget {
  final bool isMenu;
  final bool inLabel;

  final String label;
  final Widget? icon;
  final List<T> items;

  final String? helperText;
  final MenuStyle? menuStyle;
  final T? initialValue;
  final InputDecoration? buttonDecoration;
  final ValueChanged<T?> onChanged;

  /// Converts a T value to its displayed text in the UI.
  final String Function(T item) getDisplayText;

  /// Optional validator for the selected value.
  final String? Function(T?)? validator;

  /// Input decoration for the DropdownMenu version.
  final InputDecorationTheme? menuDecoration;

  const StaticDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    required this.getDisplayText,
    this.initialValue,
    this.menuDecoration,
    this.buttonDecoration,
    this.helperText,
    this.validator,
    this.menuStyle,
    this.icon,
    this.isMenu = false,
    this.inLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return isMenu ? _buildDropdownMenu(context) : _buildDropdownButton(context);
  }

  /// Compute default value:
  T? get _defaultValue {
    if (initialValue != null && items.contains(initialValue)) {
      return initialValue;
    }
    return items.isNotEmpty ? items.first : null;
  }

  String get _labelWithHelper {
    if (helperText == null) return label;
    return inLabel ? '$label ($helperText)' : label;
  }

  /// DropdownButtonFormField
  DropdownButtonFormField<T> _buildDropdownButton(BuildContext context) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      isDense: true,
      icon: icon,
      // value: _defaultValue,
      initialValue: _defaultValue,
      onChanged: onChanged,
      menuMaxHeight: context.screenHeight * 0.6,
      decoration:
          buttonDecoration ??
          InputDecoration(
            isDense: true,
            labelText: _labelWithHelper,
            helperText: inLabel ? null : helperText,
            labelStyle: TextStyle(
              overflow: TextOverflow.ellipsis,
              color: context.onSurfaceColor,
            ),
          ),
      items: items.map((item) {
        final labelText = getDisplayText(item);

        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            labelText.toTitle,
            softWrap: true,
            overflow: TextOverflow.fade,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        );
      }).toList(),
      validator:
          validator ??
          (value) {
            if (value == null) return 'Select $label';
            return null;
          },
    );
  }

  /// DropdownMenu
  DropdownMenu<T> _buildDropdownMenu(BuildContext context) {
    final entries = items
        .map(
          (item) => DropdownMenuEntry<T>(
            value: item,
            label: getDisplayText(item).toTitle,
            style: const ButtonStyle(),
          ),
        )
        .toList();

    return DropdownMenu<T>(
      trailingIcon: icon,
      requestFocusOnTap: true,
      hintText: _labelWithHelper,
      initialSelection: _defaultValue,
      dropdownMenuEntries: entries,
      menuHeight: context.screenHeight * 0.6,
      textStyle: const TextStyle(fontWeight: FontWeight.normal),
      expandedInsets: const EdgeInsets.symmetric(horizontal: 0),
      searchCallback: (entries, query) {
        final lower = query.toLowerAll;

        return entries.indexWhere(
          (entry) => entry.label.toLowerAll.contains(lower),
        );
      },
      onSelected: onChanged,
      menuStyle: menuStyle,
      inputDecorationTheme: menuDecoration?.copyWith(
        isDense: true,
        labelStyle: TextStyle(
          overflow: TextOverflow.ellipsis,
          color: context.onSurfaceColor,
        ),
      ),
    );
  }
}

/// Form text field [AsyncSearchDropdown]
/// MultiSelect / SingleSelect DropdownButtonFormField
/// A searchable dropdown widget that supports asynchronous loading of items.
///
/// Use this when you need to fetch dropdown items from a remote source
/// or handle large lists with filtering support.
///
/// Provides search, custom filter logic, validation, and no-data callbacks.
class AsyncSearchDropdown<T> extends StatelessWidget {
  final bool enabled;
  final bool isAutoApply;
  final bool isMultiSelect;
  final String labelText;
  final T? selectedItem;
  final List<T>? selectedMultiItems;
  final String? helperText;
  final IconData? trailingIcon;
  final Function(T?)? onChanged;
  final Function(List<T>)? onMultiChanged;
  final Function(T)? itemAsString;
  final String? Function(T?)? validator;
  final String? Function(List<T>?)? validatorMulti;
  final Function(T, String) filterFn;
  final void Function()? onNoDataFound;
  final Future<List<T>> Function(String, LoadProps?)? asyncItems;

  const AsyncSearchDropdown({
    super.key,
    this.enabled = true,
    this.isAutoApply = true,
    this.isMultiSelect = false,
    required this.labelText,
    required this.filterFn,
    this.helperText,
    this.itemAsString,
    this.asyncItems,
    this.onChanged,
    this.onMultiChanged,
    this.validator,
    this.validatorMulti,
    this.trailingIcon,
    this.onNoDataFound,
    this.selectedItem,
    this.selectedMultiItems,
  });

  @override
  Widget build(BuildContext context) {
    return isMultiSelect ? _buildMultiSelectDropdown() : _buildSingleDropdown();
  }

  // Single-select dropdown
  _buildSingleDropdown() {
    return DropdownSearch<T>(
      enabled: enabled,
      selectedItem: selectedItem,
      autoValidateMode: AutovalidateMode.onUserInteraction,
      popupProps: const PopupProps.menu(showSearchBox: true),
      filterFn: (obj, filter) => filterFn(obj, filter),
      // for filtering by user string
      compareFn: (obj1, obj2) => obj1 == obj2,
      // for selection comparison
      items: _onFind,
      // FutureOr<List<T>> Function(String, LoadProps?)? items
      // Future<List<T>> Function(String)? items,
      itemAsString: (T obj) => itemAsString!(obj),
      onChanged: (T? obj) => onChanged!(obj),
      suffixProps: _dropdownSuffixProps,
      decoratorProps: _dropDownDecoratorProps(helperText ?? ''),
      validator: validator ?? (T? obj) => obj == null ? labelText : null,
    );
  }

  // Multi-select dropdown
  _buildMultiSelectDropdown() {
    return DropdownSearch<T>.multiSelection(
      enabled: enabled,
      selectedItems: selectedMultiItems ?? [],
      autoValidateMode: AutovalidateMode.onUserInteraction,
      popupProps: _popupPropsMulti(),
      filterFn: (obj, filter) => filterFn(obj, filter),
      // for filtering by user string
      compareFn: (obj1, obj2) => obj1 == obj2,
      // for selection comparison
      items: _onFind,
      // FutureOr<List<T>> Function(String, LoadProps?)? items
      // Future<List<T>> Function(String)? items,
      itemAsString: (T obj) => itemAsString!(obj),
      onChanged: (List<T> obj) => onMultiChanged!(obj),
      suffixProps: _dropdownSuffixProps,
      decoratorProps: _dropDownDecoratorProps(helperText ?? ''),
      validator:
          validatorMulti ?? (List<T>? obj) => obj == null ? labelText : null,
    );
  }

  PopupPropsMultiSelection<T> _popupPropsMulti() {
    return PopupPropsMultiSelection.menu(
      showSearchBox: true,
      showSelectedItems: true,
      onItemAdded: (items, item) => onMultiChanged!(items),
      onItemRemoved: (items, item) => onMultiChanged!(items),
      validationBuilder: _manualApply,
    );
  }

  Widget _manualApply(context, List<T> obj) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: isAutoApply
          ? null
          : Wrap(
              spacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                OutlinedButton(
                  onPressed: () {
                    onMultiChanged!(obj);
                    Navigator.pop(context);
                  },
                  child: Text("Apply"),
                ),
              ],
            ),
    );
  }

  FutureOr<List<T>> _onFind(String filter, LoadProps? loadProps) async {
    final results = await asyncItems!(filter, loadProps);
    if (results.isEmpty) {
      onNoDataFound?.call();
    }
    return results;
  }

  DropDownDecoratorProps _dropDownDecoratorProps(String helpText) {
    return DropDownDecoratorProps(
      decoration: InputDecoration(labelText: labelText, helperText: helpText),
    );
  }

  DropdownSuffixProps get _dropdownSuffixProps {
    return DropdownSuffixProps(
      dropdownButtonProps: DropdownButtonProps(
        tooltip: labelText,
        iconOpened: Icon(trailingIcon ?? Icons.arrow_drop_up),
        iconClosed: Icon(trailingIcon ?? Icons.arrow_drop_down),
      ),
    );
  }
}

/*
class StaticDropdown2<T> extends StatelessWidget {
  final bool isMenu;
  final bool inLabel;
  final String label;
  final Widget? icon;
  final List<T> items;
  final String? helperText;
  final MenuStyle? menuStyle;
  final String? initialValue;
  final InputDecoration? buttonDecoration;
  final void Function(String?) onChanged;

  /// [getValue] Get & Set the value of the selected item in the dropdown.
  final String Function(T item) getValue;
  final String? Function(String?)? validator;
  final InputDecorationTheme? menuDecoration;

  /// [getDisplayText] Get & set the display text of the selected item in the dropdown.
  final String Function(T item) getDisplayText;

  const StaticDropdown2({
    super.key,
    required this.getDisplayText,
    required this.onChanged,
    required this.getValue,
    this.buttonDecoration,
    this.menuDecoration,
    required this.label,
    required this.items,
    this.initialValue,
    this.helperText,
    this.validator,
    this.menuStyle,
    this.icon,
    this.isMenu = false,
    this.inLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return isMenu ? _buildDropdownMenu(context) : _buildDropdownButton(context);
  }

  /*String? get _defaultValue2 {
    final itemValues = items.map(getValue).toList();
    if (initialValue.isNotNullNorEmpty &&
        itemValues.contains(initialValue?.toLowercaseAll)) {
      return initialValue?.toLowercaseAll;
    }
    return itemValues.isNotEmpty ? itemValues.first : null;
  }*/

  String? get _defaultValue {
    final valueSet = items.map(getValue).toSet();

    if (initialValue.isNotNullNorEmpty && valueSet.contains(initialValue)) {
      return initialValue;
    }

    return valueSet.isNotEmpty ? valueSet.first : null;
  }

  String? get _labelWithHelper {
    if (helperText == null) return label;
    return inLabel ? '$label ($helperText)' : label;
  }

  /// DropdownButtonFormField [_buildDropdownButton]
  DropdownButtonFormField<String> _buildDropdownButton(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      isDense: true,
      icon: icon,
      value: _defaultValue,
      onChanged: onChanged,
      decoration:
          buttonDecoration ??
          InputDecoration(
            isDense: true,
            labelText: _labelWithHelper?.toSentence,
            helperText: inLabel ? null : helperText,
            labelStyle: TextStyle(
              overflow: TextOverflow.ellipsis,
              color: context.onSurfaceColor,
            ),
          ),
      items: items.map((item) {
        final value = getValue(item);
        final display = getDisplayText(item);

        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            display.toTitle,
            overflow: TextOverflow.fade,
            softWrap: true,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        );
      }).toList(),
      validator:
          validator ??
          (val) {
            final normalized = val?.toLowerAll.trim();
            if (normalized.isNullOrEmpty ||
                normalized!.contains('select') ||
                normalized.contains('type')) {
              return 'Select $label';
            }
            return null;
          },
    );
  }

  /// DropdownMenu [_buildDropdownMenu]
  DropdownMenu<String> _buildDropdownMenu(BuildContext context) {
    final entries = items
        .map(
          (item) => DropdownMenuEntry(
            value: getValue(item),
            label: getDisplayText(item).toTitle,
            style: ButtonStyle(),
          ),
        )
        .toList();

    return DropdownMenu<String>(
      trailingIcon: icon,
      requestFocusOnTap: true,
      hintText: _labelWithHelper?.toSentence,
      initialSelection: _defaultValue,
      dropdownMenuEntries: entries,
      textStyle: const TextStyle(fontWeight: FontWeight.normal),
      expandedInsets: const EdgeInsets.symmetric(horizontal: 0.0),
      searchCallback: (entries, query) {
        final index = entries.indexWhere(
          (entry) =>
              _valueContains(entry.value, query) ||
              _valueContains(entry.label, query),
        );
        return index >= 0 ? index : null;
      },
      onSelected: onChanged,
      menuStyle: menuStyle,
      inputDecorationTheme: menuDecoration?.copyWith(
        isDense: true,
        labelStyle: TextStyle(
          overflow: TextOverflow.ellipsis,
          color: context.onSurfaceColor,
        ),
      ),
    );
  }

  bool _valueContains(String value, String query) =>
      value.toLowerAll.contains(query.toLowerAll);
}*/
