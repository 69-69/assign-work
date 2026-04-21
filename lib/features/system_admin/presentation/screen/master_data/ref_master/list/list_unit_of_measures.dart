import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:assign_erp/core/widgets/layout/block_quote.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';

class AllUOM extends StatefulWidget {
  const AllUOM({super.key});

  @override
  State<AllUOM> createState() => _AllUOMState();
}

class _AllUOMState extends State<AllUOM> {
  late List<String> allUomList;
  Set<String> selectedUoms = {};
  List<String> filteredUomList = [];

  final SearchController _searchController = SearchController();

  // final unchecked = allUomList.where((e) => !selectedUoms.contains(e)).toList();
  // final checked = selectedUoms.toList();

  @override
  void initState() {
    super.initState();
    allUomList = UOMUtil.toStringList(false);
    filteredUomList = allUomList;

    selectedUoms = allUomList.toSet(); // all checked by default
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      noAppBar: true,
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToolbar(context),

            /// 🔍 SEARCH BAR
            SizedBox(
              height: 40,
              width: context.screenWidth,
              child: _buildSearchAnchor(),
            ),

            BlockQuote(
              childPadding: const EdgeInsets.all(10),
              child: Text(
                'Uncheck units to exclude them from Procurement, Inventory, POS, and Sales & Distribution.',
                textAlign: TextAlign.start,
              ),
            ),

            /// 📦 GRID
            Expanded(child: _buildBody(filteredUomList)),
          ],
        ),
      ),
      bottomNavigationBar: const SizedBox.shrink(),
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
              if (selectedUoms.length != allUomList.length)
                ListToolbarButtons(
                  primaryLabel: 'Save Changes',
                  primaryIcon: Icons.done,
                  onPrimary: () {
                    prettyPrint(
                      'unchecked',
                      allUomList
                          .where((c) => !selectedUoms.contains(c))
                          .toList(),
                    );
                  },
                ),
            ],
          );
  }

  Widget _buildBody(List<String> uomList) {
    if (uomList.isEmpty) {
      return const Center(child: Text('UOM not found...'));
    }

    return GridView.builder(
      itemCount: uomList.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: context.screenWidth / (context.isMobile ? 1 : 6),
        mainAxisExtent: 90,
        // mainAxisSpacing: 20,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) => _itemBuilder(uomList[i], context),
    );
  }

  FormGroupCard _itemBuilder(String tile, BuildContext context) {
    final isChecked = selectedUoms.contains(tile);

    return FormGroupCard(
      children: [
        CustomCheckboxTile(
          title: Text(
            tile.toUpperAll,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: const Text(
            'Unit of measure',
            overflow: TextOverflow.ellipsis,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6.0),
          value: isChecked,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                selectedUoms.add(tile);
              } else {
                selectedUoms.remove(tile);
              }
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
        prefixIcon: const Icon(Icons.search, color: kGrayColor),
        suffixIcon: _searchController.text.isEmpty
            ? SizedBox.shrink()
            : IconButton(
                tooltip: 'Clear Search',
                color: kGrayColor,
                onPressed: () {
                  _searchController.clear();
                  setState(() => filteredUomList = allUomList);
                },
                icon: const Icon(Icons.clear),
                style: IconButton.styleFrom(
                  shape: const RoundedRectangleBorder(),
                ),
              ),
      ),
      onChanged: (query) => _filter(query),
    );

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

  void _filter(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        filteredUomList = allUomList;
      } else {
        filteredUomList = allUomList
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
}
