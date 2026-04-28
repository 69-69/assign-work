import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/util/extensions/collection_type.dart';
import 'package:assign_erp/features/app_training/data/models/user_guide_model.dart';
import 'package:assign_erp/features/app_training/presentation/bloc/app_training_bloc.dart';

class HowToBloc extends AppTrainingBloc<AppTraining> {
  HowToBloc({required super.firestore})
    : super(
        collectionType: CollectionType.global,
        collectionPath: appTrainingDBColPath,
        fromFirestore: (data, id) => AppTraining.fromMap(data, id: id),
        toFirestore: (guide) => guide.toMap(),
        toCache: (guide) => guide.toCache(),
      );
}
