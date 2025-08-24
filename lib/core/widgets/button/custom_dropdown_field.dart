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
/// Set [isMenu] to true to use the newer DropdownMenu with search.
class StaticDropdown extends StatelessWidget {
  final bool isMenu;
  final Widget? icon;
  final List<String> items;
  final String? initialValue;
  final String label;
  final String? helperText;
  final InputDecoration? inputDecoration;
  final String? Function(String?)? validator;
  final void Function(String?) onValueChange;

  /// [inLabel] If TRUE `helperText` is applied to the label, else to the input field.
  final bool inLabel;

  const StaticDropdown({
    super.key,
    required this.items,
    required this.label,
    required this.onValueChange,
    this.inputDecoration,
    this.initialValue,
    this.helperText,
    this.validator,
    this.icon,
    this.isMenu = false,
    this.inLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return isMenu ? _buildDropdownMenu() : _buildDropdownButton(context);
  }

  DropdownButtonFormField<String> _buildDropdownButton(BuildContext context) {
    String? helpText;
    if (helperText != null) {
      helpText = inLabel ? '($helperText)' : helperText;
    }

    final defaultVal =
        (!initialValue.isNullOrEmpty && items.contains(initialValue))
        ? initialValue
        : items.first;

    return DropdownButtonFormField<String>(
      isExpanded: true,
      isDense: true,
      // padding: EdgeInsets.zero,
      icon: icon,
      decoration:
          inputDecoration ??
          InputDecoration(
            isDense: true,
            labelText: '${label.toTitleCase} ${helpText ?? ''}',
            helperText: helpText,
            labelStyle: const TextStyle(overflow: TextOverflow.ellipsis),
          ),
      items: items.map<DropdownMenuItem<String>>((e) {
        return DropdownMenuItem(
          value: e,
          child: Text(
            e.toTitleCase,
            softWrap: true,
            overflow: TextOverflow.fade,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        );
      }).toList(),
      onChanged: (value) => onValueChange.call(value),
      value: defaultVal,
      validator:
          validator ??
          (String? val) {
            String v = val ?? ''.toLowercaseAll;
            String label = items.first.toLowercaseAll;

            if (v.isEmpty || v.contains(label)) {
              return 'Please enter $label';
            }
            return null;
          },
    );
  }

  DropdownMenu<String> _buildDropdownMenu() {
    final defaultVal =
        (!initialValue.isNullOrEmpty && items.contains(initialValue))
        ? initialValue
        : items.first;
    final helpText = helperText != null ? '($helperText)' : '';

    return DropdownMenu<String>(
      trailingIcon: icon,
      hintText: '$label $helpText',
      initialSelection: defaultVal,

      textStyle: const TextStyle(fontWeight: FontWeight.normal),
      dropdownMenuEntries: items
          .map((item) => DropdownMenuEntry(value: item, label: item))
          .toList(),
      //enableFilter: true,
      requestFocusOnTap: true,
      enableSearch: true,
      searchCallback: (List<DropdownMenuEntry<String>> entries, String query) {
        if (query.isEmpty || query.contains(items.first)) {
          return null;
        }
        final int index = entries.indexWhere(
          (DropdownMenuEntry<String> entry) => entry.label == query,
        );

        return index != -1 ? index : null;
      },
      onSelected: (value) => onValueChange(value),
      width: null,
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        labelStyle: TextStyle(overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Form text field [AsyncSearchDropdown]
/// A searchable dropdown widget that supports asynchronous loading of items.
///
/// Use this when you need to fetch dropdown items from a remote source
/// or handle large lists with filtering support.
///
/// Provides search, custom filter logic, validation, and no-data callbacks.
class AsyncSearchDropdown<T> extends StatelessWidget {
  final String labelText;
  final String? helperText;
  final IconData? trailingIcon;
  final void Function(T?)? onChanged;
  final Function(T)? itemAsString;
  final String? Function(T?)? validator;
  final Function(T, String) filterFn;
  final void Function()? onNoDataFound;
  final Future<List<T>> Function(String, LoadProps?)? asyncItems;

  const AsyncSearchDropdown({
    super.key,
    required this.labelText,
    required this.filterFn,
    this.helperText,
    this.itemAsString,
    this.asyncItems,
    this.onChanged,
    this.validator,
    this.trailingIcon,
    this.onNoDataFound,
  });

  @override
  Widget build(BuildContext context) {
    return _buildDropdownSearch();
  }

  _buildDropdownSearch() {
    final helpText = helperText != null ? '($helperText)' : '';

    return DropdownSearch<T>(
      autoValidateMode: AutovalidateMode.onUserInteraction,
      popupProps: const PopupProps.menu(showSearchBox: true),
      filterFn: (obj, filter) => filterFn(obj, filter),
      // for filtering by user string
      compareFn: (obj1, obj2) => obj1 == obj2,
      // for selection comparison
      items: (String filter, LoadProps? loadProps) async {
        final results = await asyncItems!(filter, loadProps);
        if (results.isEmpty) {
          onNoDataFound?.call();
        }
        return results;
      },

      // FutureOr<List<T>> Function(String, LoadProps?)? items
      // Future<List<T>> Function(String)? items,
      itemAsString: (T obj) => itemAsString!(obj),
      onChanged: (T? obj) => onChanged!(obj),
      suffixProps: DropdownSuffixProps(
        dropdownButtonProps: DropdownButtonProps(
          iconOpened: Icon(trailingIcon ?? Icons.arrow_drop_up, size: 24.0),
          iconClosed: Icon(trailingIcon ?? Icons.arrow_drop_down, size: 24.0),
        ),
      ),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(labelText: '$labelText $helpText'),
      ),
      validator: validator ?? (T? obj) => obj == null ? labelText : null,
    );
  }
}
