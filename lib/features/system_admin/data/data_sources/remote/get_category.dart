import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/features/system_admin/data/models/category_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/item_config/category_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetProductCategory {
  // Common method to instantiate the CategoryBloc
  static CategoryBloc _createCategoryBloc() {
    return CategoryBloc(firestore: FirebaseFirestore.instance);
  }

  // Common method to listen for the data loaded state
  static Future<SetupsLoaded<Category>> _getDataLoadedState(
    CategoryBloc bloc,
  ) async {
    return await bloc.stream.firstWhere(
          (state) => state is SetupsLoaded<Category>,
        )
        as SetupsLoaded<Category>;
  }

  // Method to load all product categories
  static Future<List<Category>> load() async {
    final categoryBloc = _createCategoryBloc();

    // Dispatch the event to fetch all category data
    categoryBloc.add(GetSetups<Category>());

    // Ensure to wait for the data to be loaded
    final state = await _getDataLoadedState(categoryBloc);

    return state.data;
  }

  /// Get item category by categoryId [byCategoryId]
  static Future<Category?> byCategoryId(String categoryId) async {
    final categoryBloc = _createCategoryBloc();

    try {
      // Dispatch the event to fetch category details by ID
      categoryBloc.add(GetSetupById<Category>(documentId: categoryId));

      // Wait for the data to be loaded from the stream
      final state = await _getDataLoadedState(categoryBloc);

      // Return the first category if found, else return null
      return state.data.isNotEmpty ? state.data.first : null;
    } catch (e) {
      prettyPrint('Error fetching category by ID', '$e');
      return null;
    }
  }
}
