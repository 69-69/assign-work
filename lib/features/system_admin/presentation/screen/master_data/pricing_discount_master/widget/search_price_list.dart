import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_price_lists.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/price_list_master_model.dart';
import 'package:flutter/material.dart';

/// Search priceList [SearchPriceList]
class SearchPriceList extends StatefulWidget {
  final String? initialValue;
  final Function(String, String) onChanged;

  const SearchPriceList({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SearchPriceList> createState() => _SearchPriceListState();
}

class _SearchPriceListState extends State<SearchPriceList> {
  PriceListMaster? _priceList;
  String? _initialValue;

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPriceLists());
  }

  Future _loadPriceLists({String? filter}) async {
    final filterBy = filter ?? _initialValue ?? '';

    // If filter contains wildCard/asterisk '*', load all priceList
    // Else load priceList that match the filter
    final priceLists = await (filterBy.contains('*')
        ? GetPriceList.load()
        : GetPriceList.byAnyTerm(filterBy));

    if (filterBy.hasValue && priceLists.hasValue) {
      setState(() => _priceList = priceLists.first);
    }
    return priceLists;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncDropdown<PriceListMaster>(
      labelText: 'Price List',
      selectedItem: _priceList,
      helperText: 'Enter * for all list, or type to search',
      asyncItems: (String filter, loadProps) async =>
          await _loadPriceLists(filter: filter),
      filterFn: (priceList, filter) => _filterPriceList(priceList, filter),
      getDisplayText: (list) => list.name.toTitle,
      onChanged: (list) => widget.onChanged(list!.id, list.name),
      validator: (list) => list == null ? 'Price list is Required' : null,
    );
  }

  _filterPriceList(PriceListMaster priceList, String filter) {
    // If filter contains wildCard/asterisk '*', load all, else load filtered
    if (filter == '*') return true;

    var term = filter.isEmpty ? (_initialValue ?? '') : filter;
    return priceList.filterByAny(term);
  }
}


/// PriceList Multi Select Dropdown [PriceListMultiSelect]
class PriceListMultiSelect extends StatefulWidget {
  const PriceListMultiSelect({
    super.key,
    this.label,
    this.initialValues,
    this.onMultiChanged,
  });

  final String? label;
  final List<String>? initialValues;
  final Function(List<PriceListMaster>)? onMultiChanged;

  @override
  State<PriceListMultiSelect> createState() => _PriceListMultiSelectState();
}

class _PriceListMultiSelectState extends State<PriceListMultiSelect> {
  List<String>? _initialValues;
  List<PriceListMaster>? _priceLists;

  get _labelText => widget.label ?? 'Select Price list';

  @override
  void initState() {
    super.initState();
    _initialValues = widget.initialValues; // Load initial values
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPriceLists());
  }

  Future<List<PriceListMaster>> _loadPriceLists({String? filter}) async {
    // Only use filter or initialValues if filter is non-empty
    final filterBy =
    (filter?.isEmpty ?? true) && (_initialValues?.isEmpty ?? true)
        ? '' // Use empty string if both filter and initialValues are empty
        : (filter?.isEmpty ?? true)
        ? (_initialValues?.join(' ') ?? '')
        : filter;

    final priceLists = await GetPriceList.load();

    if (filterBy.toString().hasValue && priceLists.hasValue) {
      final filteredLists = priceLists
          .where((t) => t.filterByAny(filterBy!))
          .toList();

      setState(() => _priceLists = filteredLists);
      return filteredLists;
    }
    return priceLists;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncDropdown<PriceListMaster>(
      isMultiSelect: true,
      selectedMultiItems: _priceLists,
      labelText: '$_labelText...',
      helperText:
      'If Price List is not listed, add from Price List Tab',
      asyncItems: (String filter, loadProps) async =>
      await _loadPriceLists(filter: filter),
      filterFn: _filterList,
      getDisplayText: (PriceListMaster list) => list.name.toTitle,
      onMultiChanged: (List<PriceListMaster> lists) {
        // Ensure lists is updated even if empty
        setState(() => _priceLists = List<PriceListMaster>.from(lists));
        widget.onMultiChanged?.call(lists);
      },
      validatorMulti: (lists) => lists.isNullOrEmpty ? _labelText : null,
      onNoDataFound: () {
        WidgetsBinding.instance.addPostFrameCallback(
              (_) => _handleNoDataFound(context),
        );
      },
    );
  }

  bool _filterList(PriceListMaster list, String filter) {
    final term = (filter.isEmpty && (_initialValues?.isEmpty ?? true))
        ? '' // Use empty string if no filter and initial values are empty
        : filter.isEmpty
        ? (_initialValues?.join(' ') ??
        '') // Join the list into a single string
        : filter;
    return list.filterByAny(term);
  }

  Future<void> _handleNoDataFound(BuildContext cxt) async {
    await cxt.confirmDone(
      const Text(
        'Enter to search or add missing price list from Price List Tab',
      ),
      title: 'Price list not found',
    );
  }
}

