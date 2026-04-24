import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/attribute_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetAttributes {
  // Common method to instantiate the AttributeBloc
  static AttributeBloc _createAttributesBloc() {
    return AttributeBloc(firestore: FirebaseFirestore.instance);
  }

  // Common method to listen for the data loaded state
  static Future<SetupsLoaded<Attribute>> _getDataLoadedState(
      AttributeBloc bloc,
  ) async {
    return await bloc.stream.firstWhere(
          (state) => state is SetupsLoaded<Attribute>,
          orElse: () => SetupsLoaded<Attribute>([]),
        )
        as SetupsLoaded<Attribute>;
  }

  // Method to load all product categories
  static Future<List<Attribute>> load() async {
    final attributeBloc = _createAttributesBloc();

    // Dispatch the event to fetch all attribute data
    attributeBloc.add(GetSetups<Attribute>());

    // Ensure to wait for the data to be loaded
    final state = await _getDataLoadedState(attributeBloc);

    return state.data;
  }

  /// Get by either name, storeNumber [byAnyTerm]
  /// @Return: `List<Attribute>`
  static Future<List<Attribute>> byAnyTerm(term) async {
    final catBloc = _createAttributesBloc();
    // Load all data initially to pass to the search delegate
    catBloc.add(
      SearchSetup<Attribute>(
        primaryField: 'type',
        secondaryField: 'value',
        tertiaryField: 'storeNumber',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await catBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<Attribute>,
            )
            as SetupsLoaded<Attribute>;

    return allData.data;
  }

}
