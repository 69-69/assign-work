import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:assign_erp/core/widgets/layout/block_quote.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/ref_master_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AllUOM extends StatefulWidget {
  const AllUOM({super.key});

  @override
  State<AllUOM> createState() => _AllUOMState();
}

class _AllUOMState extends State<AllUOM> {
  final _cacheId = uomMasterCacheId;
  final _cache = RefMasterCache();

  bool _hasChanges = false;

  late List<String> _allUoms;
  late Set<String> _initialUnchecked; // ✅ baseline (persisted state)

  Set<String> _selectedUoms = {};
  List<String> _filteredUoms = [];

  final SearchController _searchController = SearchController();

  @override
  void initState() {
    super.initState();

    _allUoms = UOMUtil.toStringList(false);

    /// ✅ Load cache safely
    final cache = _cache.getById(_cacheId);
    _initialUnchecked = (cache?.references ?? const <String>[]).toSet();

    /// ✅ Build selected state from cache
    _selectedUoms = _allUoms
        .where((c) => !_initialUnchecked.contains(c))
        .toSet();

    _filteredUoms = List.from(_allUoms);

    /// ✅ Initial diff check
    _recomputeChanges();
  }

  /// ✅ Single source of truth for change detection
  void _recomputeChanges() {
    final currentUnchecked = _allUoms
        .where((c) => !_selectedUoms.contains(c))
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
              'Uncheck units to exclude them from Procurement, Inventory, POS, and Sales & Distribution.',
            ),
          ),

          /// 📦 GRID
          Expanded(child: _buildBody(_filteredUoms)),
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
            'UOM',
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
    final unchecked = _allUoms
        .where((c) => !_selectedUoms.contains(c))
        .toList();

    await _cache.setRef({'id': _cacheId, 'references': unchecked});

    if (!mounted) return;

    context.showAlertOverlay(
      'Changes successfully saved',
      onCallback: () {
        setState(() {
          _initialUnchecked = unchecked.toSet();
          _hasChanges = false;
        });
      },
    );
  }

  Widget _buildBody(List<String> uoms) {
    if (uoms.isEmpty) {
      return const Center(child: Text('UOM not found...'));
    }

    return GridView.builder(
      itemCount: uoms.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: context.screenWidth / (context.isMobile ? 1 : 6),
        mainAxisExtent: 90,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) => _itemBuilder(uoms[i], context),
    );
  }

  FormGroupCard _itemBuilder(String tile, BuildContext context) {
    final isChecked = _selectedUoms.contains(tile);
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 6.0),
          value: isChecked,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedUoms.add(tile);
              } else {
                _selectedUoms.remove(tile);
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
      textInputType: TextInputType.text,
      inputDecoration: InputDecoration(
        labelText: 'Search...',
        prefixIcon: const Icon(Icons.search, color: kGrayColor),
        suffixIcon: _searchController.text.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
                tooltip: 'Clear Search',
                color: kGrayColor,
                onPressed: () {
                  _searchController.clear();
                  setState(() => _filteredUoms = List.from(_allUoms));
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
        _filteredUoms = List.from(_allUoms);
      } else {
        _filteredUoms = _allUoms
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
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
