import 'package:assign_erp/features/setup/data/models/tax_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/taxes/tax_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetTaxes {
  static final taxBloc = TaxBloc(firestore: FirebaseFirestore.instance);

  static Future<SetupsLoaded<Tax>> _dataLoadedState(TaxBloc bloc) async {
    return await bloc.stream.firstWhere((state) => state is SetupsLoaded<Tax>)
        as SetupsLoaded<Tax>;
  }

  static Future<List<Tax>> load() async {
    final taxBloc = TaxBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    taxBloc.add(GetSetups<Tax>());

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(taxBloc);

    return state.data;
  }

  static Future<List<Tax>> byAnyTerm(term) async {
    final taxBloc = TaxBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    taxBloc.add(
      SearchSetup<Tax>(field: 'name', optField: 'percent', query: term),
    );

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(taxBloc);

    return state.data.isEmpty ? [] : state.data;
  }

  /*// Load the taxes from Firestore and return a list of Tax objects
  static Future<List<Tax>> load2() async {
    try {
      // Dispatch event to load all data
      taxBloc.add(GetSetups<Tax>());

      // Wait for the data to be loaded from the state
      final allData =
          await taxBloc.stream.firstWhere(
                (state) => state is SetupsLoaded<Tax>,
                orElse: () => SetupsLoaded<Tax>([]),
              )
              as SetupsLoaded<Tax>;

      return allData.data;
    } catch (e) {
      // Handle any errors during the stream subscription
      prettyPrint('Error loading taxes', '$e');
      return [];
    }
  }

  // Get taxes based on a search term (either name or percent)
  static Future<List<Tax>> byAnyTerm2(String term) async {
    try {
      // Dispatch search event with the given term
      taxBloc.add(
        SearchSetup<Tax>(field: 'name', optField: 'percent', query: term),
      );

      // Wait for the data to be loaded from the state
      final allData =
          await taxBloc.stream.firstWhere(
                (state) => state is SetupsLoaded<Tax>,
                orElse: () => SetupsLoaded<Tax>([]),
              )
              as SetupsLoaded<Tax>;

      return allData.data;
    } catch (e) {
      // Handle any errors during the stream subscription
      prettyPrint('Error searching taxes', '$e');
      return [];
    }
  }*/
}
