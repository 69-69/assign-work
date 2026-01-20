import 'package:assign_erp/features/trouble_shooting/data/models/subscription_model.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/subscription/subscription_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/tenant_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetSubscriptions {
  static final subBloc = SubscriptionBloc(
    firestore: FirebaseFirestore.instance,
  );
  static Future<TenantsLoaded<Subscription>> _dataLoadedState(
    SubscriptionBloc bloc,
  ) async {
    return await bloc.stream.firstWhere(
          (state) => state is TenantsLoaded<Subscription>,
        )
        as TenantsLoaded<Subscription>;
  }

  static Future<List<Subscription>> load() async {
    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(subBloc);

    return state.data;
  }

  static Future<List<Subscription>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    subBloc.add(
      SearchSubscriptions<Subscription>(
        primaryField: 'name',
        optionalField: 'licenses',
        secondaryField: 'fee',
        tertiaryField: 'expiresOn',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await subBloc.stream.firstWhere(
              (state) => state is SubscriptionsLoaded<Subscription>,
            )
            as SubscriptionsLoaded<Subscription>;

    return allData.data;
  }
}
