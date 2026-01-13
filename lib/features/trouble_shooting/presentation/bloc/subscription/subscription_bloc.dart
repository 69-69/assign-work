import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/util/extensions/collection_type.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/subscription_model.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/tenant_bloc.dart';

class SubscriptionBloc extends TenantBloc<Subscription> {
  SubscriptionBloc({required super.firestore})
    : super(
        collectionType: CollectionType.global,
        collectionPath: subscriptionDBColPath,
        fromFirestore: (data, id) => Subscription.fromMap(data, id: id),
        toFirestore: (sub) => sub.toMap(),
        toCache: (sub) => sub.toCache(),
      );
}
