import 'package:assign_erp/features/trouble_shooting/data/models/subscription_model.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/subscription/subscription_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/tenant_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetSubscriptions {
  static Future<TenantsLoaded<Subscription>> _dataLoadedState(
    SubscriptionBloc bloc,
  ) async {
    return await bloc.stream.firstWhere(
          (state) => state is TenantsLoaded<Subscription>,
        )
        as TenantsLoaded<Subscription>;
  }

  static Future<List<Subscription>> load() async {
    final subscriptionBloc = SubscriptionBloc(
      firestore: FirebaseFirestore.instance,
    );

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(subscriptionBloc);

    return state.data;
  }
}
