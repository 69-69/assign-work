import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/constants/collection_type.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/tenant_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// [AllTenantsBloc] Get All Tenants Workspaces
class AllTenantsBloc extends TenantBloc<Workspace> {
  final FirebaseFirestore _firestore;

  AllTenantsBloc({required super.firestore})
    : _firestore = firestore,
      super(
        collectionType: CollectionType.global,
        collectionPath: workspaceAccDBCollectionPath,
        fromFirestore: (data, id) => Workspace.fromMap(data, id: id),
        toFirestore: (workspace) => workspace.toMap(),
        toCache: (workspace) => workspace.toCache(),
      );

  /// [deleteTenantData] Delete Tenant Associated Data
  Future<void> deleteTenantData(
    String workspaceId,
    String workspaceRole,
  ) async =>
      await _firestore.collection(workspaceRole).doc(workspaceId).delete();
}
