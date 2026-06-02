import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:assign_erp/core/widgets/layout/block_quote.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/ref_master_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ListCurrencyMaster extends StatefulWidget {
  const ListCurrencyMaster({super.key});

  @override
  State<ListCurrencyMaster> createState() => _ListCurrencyMasterState();
}
class _ListCurrencyMasterState extends State<ListCurrencyMaster> {
  final _cacheId = currencyMasterCacheId;
  final _cache = RefMasterCache();

  bool _hasChanges = false;

  late List<({String code, String symbol, String country})> _currencies;

  late Set<String> _initialUnchecked; // stores ONLY codes

  Set<({String code, String symbol, String country})> _selectedCurrencies = {};

  List<({String code, String symbol, String country})> _filteredCurrencies = [];

  final SearchController _searchController = SearchController();

  @override
  void initState() {
    super.initState();

    /// ✅ Full currency objects
    _currencies = currencyType
        .where((a) => !a.symbol.contains('-'))
        .toList();

    /// ✅ Load cached unchecked codes
    final cache = _cache.getById(_cacheId);
    _initialUnchecked = (cache?.references ?? const <String>[]).toSet();

    /// ✅ Build selected currencies from cache
    _selectedCurrencies = _currencies
        .where((c) => !_initialUnchecked.contains(c.code))
        .toSet();

    _filteredCurrencies = List.from(_currencies);

    _recomputeChanges();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// =========================
  /// CHANGE DETECTION
  /// =========================
  void _recomputeChanges() {
    final currentUnchecked = _currencies
        .where((c) => !_selectedCurrencies.contains(c))
        .map((c) => c.code)
        .toSet();

    _hasChanges = !setEquals(_initialUnchecked, currentUnchecked);
  }

  /// =========================
  /// SAVE
  /// =========================
  Future<void> _onSave() async {
    final unchecked = _currencies
        .where((c) => !_selectedCurrencies.contains(c))
        .map((c) => c.code)
        .toList();

    await _cache.setRef({
      'id': _cacheId,
      'references': unchecked,
    });

    setState(() {
      _initialUnchecked = unchecked.toSet();
      _hasChanges = false;
    });
  }

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(context),

          /// SEARCH
          SizedBox(
            height: 40,
            width: context.screenWidth,
            child: _buildSearch(),
          ),

          BlockQuote(
            child: Text(
              'Uncheck currencies to exclude them from Procurement, Inventory, POS, and Sales & Distribution.',
            ),
          ),

          /// GRID
          Expanded(child: _buildBody(_filteredCurrencies)),
        ],
      ),
    );
  }

  /// =========================
  /// TOOLBAR
  /// =========================
  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        Title(
          color: kTextColor,
          child: Text(
            'Currencies (Local & Foreign)',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (_hasChanges)
          ListToolbarButtons(
            primaryLabel: 'Save Changes',
            primaryIcon: Icons.done,
            onPrimary: _onSave,
          ),
      ],
    );
  }

  /// =========================
  /// GRID
  /// =========================
  Widget _buildBody(
      List<({String code, String symbol, String country})> items,
      ) {
    if (items.isEmpty) {
      return const Center(child: Text('Currency not found...'));
    }

    return GridView.builder(
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent:
        context.screenWidth / (context.isMobile ? 1 : 6),
        mainAxisExtent: 90,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, i) => _item(items[i], context),
    );
  }

  Widget _item(
      ({String code, String symbol, String country}) currency,
      BuildContext context,
      ) {
    final isChecked = _selectedCurrencies.contains(currency);

    return FormGroupCard(
      children: [
        CustomCheckboxTile(
          title: Text(
            '${currency.code.toUpperAll} ${currency.symbol}',
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            currency.country.toTitle,
            overflow: TextOverflow.ellipsis,
          ),
          value: isChecked,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedCurrencies.add(currency);
              } else {
                _selectedCurrencies.remove(currency);
              }

              _recomputeChanges();
            });
          },
        ),
      ],
    );
  }

  /// =========================
  /// SEARCH
  /// =========================
  Widget _buildSearch() {
    return CustomTextField(
      controller: _searchController,
      textInputType: TextInputType.text,
      inputDecoration: InputDecoration(
        labelText: 'Search...',
        prefixIcon: const Icon(Icons.search, color: kGrayColor),
        suffixIcon: _searchController.text.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            setState(() {
              _filteredCurrencies = List.from(_currencies);
            });
          },
        ),
      ),
      onChanged: _filter,
    );
  }

  void _filter(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredCurrencies = List.from(_currencies);
      } else {
        _filteredCurrencies = _currencies.where((c) {
          return c.code.toLowerCase().contains(query.toLowerCase()) ||
              c.country.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }


/*return SearchAnchor.bar(
      searchController: _searchController,
      barHintText: 'Search...',
      barElevation: WidgetStateProperty.all(0),
      barShape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: context.colorScheme.outlineVariant),
        ),
      ),
      onChanged: (query) {
        setState(() {
          if (query.trim().isEmpty) {
            filteredUomList = allUomList; // restore full list
            return;
          }
          filteredUomList = allUomList
              .where((item) => item.toLowerAll.contains(query.toLowerAll))
              .toList();
        });
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        final query = controller.text;

        final suggestions = query.trim().isEmpty
            ? allUomList
            : allUomList
                  .where((item) => item.toLowerAll.contains(query.toLowerAll))
                  .toList();

        return suggestions.map((item) {
          return ListTile(
            title: Text(item.toSentence),
            onTap: () {
              controller.closeView(item);

              setState(() {
                filteredUomList = allUomList
                    .where((e) => e.toLowerCase().contains(item.toLowerCase()))
                    .toList();
              });
            },
          );
        }).toList();
      },
    );*/
}

/*class _ListCurrencyMasterState2 extends State<ListCurrencyMaster> {
  final _cacheId = 'currency_master';
  final _cache = RefMasterCache();

  bool _hasChanges = false;

  late List<String> _currencies;
  late Set<String> _initialUnchecked; // ✅ baseline (persisted state)

  Set<String> _selectedCurrencies = {};
  List<String> _filteredCurrencies = [];

  final SearchController _searchController = SearchController();

  @override
  void initState() {
    super.initState();

    _currencies = currencyType
        .whereNot((a) => a.symbol.contains('-'))
        .map((c) => '${c.code} ${c.symbol} - ${c.country}')
        .toList();

    /// ✅ Load cache safely
    final cache = _cache.getById(_cacheId);
    _initialUnchecked = (cache?.references ?? const <String>[]).toSet();

    /// ✅ Build selected state from cache
    _selectedCurrencies = _currencies
        .where((c) => !_initialUnchecked.contains(c))
        .toSet();

    _filteredCurrencies = List.from(_currencies);

    /// ✅ Initial diff check
    _recomputeChanges();
  }

  /// ✅ Single source of truth for change detection
  void _recomputeChanges() {
    final currentUnchecked = _currencies
        .where((c) => !_selectedCurrencies.contains(c))
        .toSet();

    _hasChanges = !setEquals(_initialUnchecked, currentUnchecked);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(context),

          /// 🔍 SEARCH
          SizedBox(
            height: 40,
            width: context.screenWidth,
            child: _buildSearchAnchor(),
          ),

          BlockQuote(
            child: Text(
              'Uncheck currencies to exclude them from Procurement, Inventory, POS, and Sales & Distribution.',
            ),
          ),

          /// 📦 GRID
          Expanded(child: _buildBody(_filteredCurrencies)),
        ],
      ),
    );
  }

  Row _buildToolbar(BuildContext context) {
    return Row(
      children: [
        Title(
          color: kTextColor,
          child: Text(
            'Currencies (Local & Foreign)',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        /// ✅ Show only when actual changes exist
        if (_hasChanges)
          ListToolbarButtons(
            primaryLabel: 'Save Changes',
            primaryIcon: Icons.done,
            onPrimary: _onSave,
          ),
      ],
    );
  }

  /// ✅ Save + reset baseline correctly
  Future<void> _onSave() async {
    final unchecked = _currencies
        .where((c) => !_selectedCurrencies.contains(c))
        .toList();

    await _cache.setRef({
      'id': _cacheId,
      'references': unchecked,
    });

    setState(() {
      _initialUnchecked = unchecked.toSet();
      _hasChanges = false;
    });
  }

  Widget _buildBody(List<String> currencies) {
    if (currencies.isEmpty) {
      return const Center(child: Text('Currency not found...'));
    }

    return GridView.builder(
      itemCount: currencies.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent:
        context.screenWidth / (context.isMobile ? 1 : 6),
        mainAxisExtent: 90,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) =>
          _itemBuilder(currencies[i], context),
    );
  }

  FormGroupCard _itemBuilder(String tile, BuildContext context) {
    final isChecked = _selectedCurrencies.contains(tile);
    final title = tile.split('-');

    return FormGroupCard(
      children: [
        CustomCheckboxTile(
          title: Text(
            title.first.trim().toUpperAll,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            title.last.trim().toTitle,
            overflow: TextOverflow.ellipsis,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 6.0),
          value: isChecked,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedCurrencies.add(tile);
              } else {
                _selectedCurrencies.remove(tile);
              }

              _recomputeChanges();
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchAnchor() {
    return CustomTextField(
      controller: _searchController,
      keyboardType: TextInputType.text,
      inputDecoration: InputDecoration(
        labelText: 'Search...',
        prefixIcon:
        const Icon(Icons.search, color: kGrayColor),
        suffixIcon: _searchController.text.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
          tooltip: 'Clear Search',
          color: kGrayColor,
          onPressed: () {
            _searchController.clear();
            setState(() =>
            _filteredCurrencies = List.from(_currencies));
          },
          icon: const Icon(Icons.clear),
        ),
      ),
      onChanged: _filter,
    );
  }

  void _filter(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredCurrencies = List.from(_currencies);
      } else {
        _filteredCurrencies = _currencies
            .where((item) =>
            item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
}*/
