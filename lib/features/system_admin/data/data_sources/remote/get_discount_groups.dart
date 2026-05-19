import 'package:assign_erp/features/system_admin/data/models/master_data/discount_group_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/discount_group_master_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetDiscountGroups {
  static final _discountGroupBloc = DiscountGroupMasterBloc(
    firestore: FirebaseFirestore.instance,
  );

  static Future<List<DiscountGroup>> load() async {
    // Load all data initially to pass to the search delegate
    _discountGroupBloc.add(GetSetups<DiscountGroup>());

    // Ensure to wait for the data to be loaded
    final allData =
        await _discountGroupBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<DiscountGroup>,
            )
            as SetupsLoaded<DiscountGroup>;

    return allData.data;
  }

  /// Get by either storeNumber, name, type [byAnyTerm]
  /// @Return: `List<DiscountGroup>`
  static Future<List<DiscountGroup>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    _discountGroupBloc.add(
      SearchSetup<DiscountGroup>(
        primaryField: 'name',
        secondaryField: 'transactionType',
        optionalField: 'storeNumber',
        tertiaryField: 'validUntil',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await _discountGroupBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<DiscountGroup>,
            )
            as SetupsLoaded<DiscountGroup>;

    return allData.data;
  }
}
