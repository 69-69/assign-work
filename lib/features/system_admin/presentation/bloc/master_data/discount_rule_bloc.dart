import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/discount_group_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class DiscountRuleBloc extends SetupBloc<DiscountRule> {
  DiscountRuleBloc({required super.firestore})
    : super(
        collectionPath: discountRuleDBColPath,
        fromFirestore: (data, id) => DiscountRule.fromMap(data, id: id),
        toFirestore: (rule) => rule.toMap(),
        toCache: (rule) => rule.toCache(),
      );
}
