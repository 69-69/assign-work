import 'package:assign_erp/core/network/data_sources/remote/repository/data_repository.dart';

class SetupRepository extends DataRepository {
  SetupRepository({
    required super.firestore,
    required super.collectionPath,
    super.collectionType,
    super.collectionRef,
  });
}
