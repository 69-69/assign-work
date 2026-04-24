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

class AttributeTypes extends StatefulWidget {
  const AttributeTypes({super.key});

  @override
  State<AttributeTypes> createState() => _AttributeTypesState();
}


class _AttributeTypesState extends State<AttributeTypes> {
  final _cacheId = attributeMasterCacheId;
  final _cache = RefMasterCache();

  bool _hasChanges = false;

  late List<String> _attributeNames;
  late Set<String> _initialUnchecked; // ✅ baseline (persisted state)

  Set<String> _selectedAttrNames = {};
  List<String> _filteredAttrNames = [];

  final SearchController _searchController = SearchController();

  @override
  void initState() {
    super.initState();

    _attributeNames = variantAttributes.where((a) => !a.contains('Select'))
        .toList();

    /// ✅ Load cache safely
    final cache = _cache.getById(_cacheId);
    _initialUnchecked = (cache?.references ?? const <String>[]).toSet();

    /// ✅ Build selected state from cache
    _selectedAttrNames = _attributeNames
        .where((c) => !_initialUnchecked.contains(c))
        .toSet();

    _filteredAttrNames = List.from(_attributeNames);

    /// ✅ Initial diff check
    _recomputeChanges();
  }

  /// ✅ Single source of truth for change detection
  void _recomputeChanges() {
    final currentUnchecked = _attributeNames
        .where((c) => !_selectedAttrNames.contains(c))
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
              'Uncheck attributes to exclude them from Procurement, Inventory, POS, and Sales & Distribution.',
            ),
          ),

          /// 📦 GRID
          Expanded(child: _buildBody(_filteredAttrNames)),
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
            'Attribute Types',
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
    final unchecked = _attributeNames
        .where((c) => !_selectedAttrNames.contains(c))
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

  Widget _buildBody(List<String> names) {
    if (names.isEmpty) {
      return const Center(child: Text('Attribute type not found...'));
    }

    return GridView.builder(
      itemCount: names.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent:
        context.screenWidth / (context.isMobile ? 1 : 6),
        mainAxisExtent: 90,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) =>
          _itemBuilder(names[i], context),
    );
  }

  FormGroupCard _itemBuilder(String name, BuildContext context) {
    final isChecked = _selectedAttrNames.contains(name);

    return FormGroupCard(
      children: [
        CustomCheckboxTile(
          title: Text(
            name.toUpperAll,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Attribute',
            overflow: TextOverflow.ellipsis,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 6.0),
          value: isChecked,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedAttrNames.add(name);
              } else {
                _selectedAttrNames.remove(name);
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
            _filteredAttrNames = List.from(_attributeNames));
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
        _filteredAttrNames = List.from(_attributeNames);
      } else {
        _filteredAttrNames = _attributeNames
            .where((item) =>
            item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

}
