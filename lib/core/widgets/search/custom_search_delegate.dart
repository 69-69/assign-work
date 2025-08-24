import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/barcode_scanner.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/item/item_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// main search delegate class
class CustomSearchDelegate<T> extends SearchDelegate<T?> {
  final List<T> allData;
  final Object? field;
  final Object? auxField;
  final Object? optField;
  final Function(dynamic)? onChanged;
  final ItemBloc firestoreBloc;

  CustomSearchDelegate({
    required this.firestoreBloc,
    required this.allData,
    this.onChanged,
    this.field,
    this.optField,
    this.auxField,
    required String hintText,
  }) : super(
         searchFieldLabel: hintText,
         keyboardType: TextInputType.text,
         textInputAction: TextInputAction.search,
       );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.qr_code_scanner, color: kDangerColor),
        onPressed: () async => await _searchByScan(context),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  /// Search for product by scanning [_searchByScan]
  Future<void> _searchByScan(BuildContext context) async {
    final deviceOS = context.deviceOSType;
    if (deviceOS.android || deviceOS.ios) {
      await context.scanBarcode(
        barcode: (s) async {
          if (s.isNotEmpty) {
            query = s.trim();
          }
        },
      );
    } else {
      await context.showItemScanWarningDialog();
    }
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      firestoreBloc.add(
        SearchInventory<T>(
          field: field,
          optField: optField,
          auxField: auxField,
          query: query,
        ),
      );
    }

    return BlocBuilder<ItemBloc, InventoryState>(
      bloc: firestoreBloc,
      builder: (context, state) {
        return switch (state) {
          LoadingInventory<T>() => context.loader,
          InventoriesLoaded<T>(data: var results) =>
            results.isEmpty ? context.buildNoResult() : _buildListView(results),
          InventoryError<T>(error: final error) => context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? []
        : allData
              .where(
                (item) => (item.toString().toLowercaseAll).contains(
                  query.toLowercaseAll,
                ),
              )
              .toList();

    if (suggestions.isEmpty) {
      return context.buildNoResult();
    }

    return _buildListView(suggestions, isSuggest: true, itemCount: (i) {});
  }

  ListView _buildListView(
    List results, {
    bool isSuggest = false,
    Function(int s)? itemCount,
  }) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        if (itemCount != null) {
          itemCount(results.length);
        }

        final result = results[index];

        /// This Overrides the toString() in the Class-Models/Entities
        final toStr = result.toString();
        return ListTile(
          dense: true,
          leading: Icon(
            isSuggest ? Icons.history : Icons.search,
            color: kGrayColor,
          ),
          title: Text(toStr.toTitleCase),
          onTap: () {
            // Set result
            _onSelected = result;
            if (isSuggest) {
              /// toString() is overridden in the Model-Class
              query = toStr;
              // This triggers buildResults widget
              showResults(context);
            } else {
              close(context, result);
            }
          },
        );
      },
    );
  }

  set _onSelected(result) {
    /// Delay _onSelected() to prevent 'close()' from closing it
    if (onChanged != null) {
      Future.delayed(const Duration(milliseconds: 1), () => onChanged!(result));
    }
  }

  /*

    ------OR-----

    if (state is LoadingState<T>) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is DataLoadedState<T>) {
          final results = state.data;
          if (results.isEmpty) {
            return _buildCenter();
          }
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index];
              // Customize how you display the search result item
              return ListTile(
                title: Text(item.toString()),
                onTap: () {
                  close(context, item);
                },
              );
            },
          );
        } else if (state is ErrorState<T>) {
          return Center(child: Text('Error: ${state.error}'));
        }
        return Container();*/
}
