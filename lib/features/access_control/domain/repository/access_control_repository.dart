import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/network/data_sources/models/result_data.dart';
import 'package:assign_erp/core/network/data_sources/remote/repository/firestore_helper.dart';
import 'package:assign_erp/core/util/extensions/collection_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccessControlRepository {
  final FirebaseFirestore _firestore;

  AccessControlRepository(this._firestore);

  /// Fetches workspace licenses (subscriptions) for a given workspace.
  Future<LoadResult<String, String>> fetchLicensesForSubscription(
    String subscriptionId,
  ) async {
    final noData = LoadResult<String, String>(meta: 'unknown', data: {});

    final doc = await _genericCollection(
      subscriptionDBColPath,
      collectionType: CollectionType.global,
    ).doc(subscriptionId).get();

    final data = doc.data();
    final licensesData = data?['licenses'];

    if (data == null ||
        licensesData == null ||
        licensesData is! List ||
        licensesData.isEmpty) {
      return noData;
    }

    final rawLicenses = data['licenses'] as List<dynamic>;
    final subscriptionName = data['name'] as String? ?? 'unknown';

    final licenses = rawLicenses
        // .whereType<Map<String, String>>() // Optional extra safe typecast
        .where((e) => e['license'] != null)
        .map((e) => e['license'] as String)
        .whereType<String>()
        .toSet();

    return LoadResult<String, String>(meta: subscriptionName, data: licenses);
    // return List<String>.from(data['licenses']).toSet();
  }

  /// Fetches permissions for a given role within a workspace context.
  Future<LoadResult<String, String>> fetchPermissionsForRole(
    String roleId, {
    String? workspaceId,
    String? workspaceRole,
  }) async {
    final noData = LoadResult<String, String>(meta: 'unknown', data: {});

    if (workspaceId == null || workspaceRole == null) {
      return noData;
    }

    final doc = await _genericCollection(
      rolesDBColPath,
      workspaceId: workspaceId,
      workspaceRole: workspaceRole,
    ).doc(roleId).get();

    final data = doc.data();
    final permissionsData = data?['permissions'];

    if (data == null ||
        permissionsData == null ||
        permissionsData is! List ||
        permissionsData.isEmpty) {
      return noData;
    }

    final rawPermissions = data['permissions'] as List<dynamic>;
    final roleName = data['name'] as String? ?? 'unknown';

    final permissions = rawPermissions
        // .whereType<Map<String, dynamic>>() // Optional extra safe typecast
        .where((e) => e['permission'] != null)
        .map((e) => e['permission'] as String)
        .whereType<String>()
        .toSet();

    return LoadResult<String, String>(meta: roleName, data: permissions);
  }

  /// Provides a Firestore CollectionReference to the roles collection.
  CollectionReference<Map<String, dynamic>> _genericCollection(
    String collectionPath, {
    String? workspaceId,
    String? workspaceRole,
    CollectionType collectionType = CollectionType.workspace,
  }) {
    return FirestoreHelper(
      firestore: _firestore,
      workspaceRole: workspaceRole,
      workspaceId: workspaceId,
    ).getCollectionRef(collectionPath, collectionType: collectionType);
  }
}

/*class RolePermissionRepository {
  final FirebaseFirestore _firestore;

  RolePermissionRepository(this._firestore);

  /// Fetches workspace licenses (subscriptions) for a given workspaceId.
  Future<Set<String>> fetchSubscriptionLicenses(String workspaceId) async {
    final doc = await _firestore
        .collection(licenseDBCollectionPath)
        .doc(workspaceId)
        .get();

    final data = doc.data();
    if (data == null || data['subscriptions'] == null) return {};

    return List<String>.from(data['subscriptions']).toSet();
  }

  /// Fetches permissions for a given role within a workspace context.
  Future<Set<String>> fetchPermissionsForRole(
    String roleId, {
    required String workspaceId,
    required String workspaceRole,
  }) async {
    if (workspaceId.isEmpty || workspaceRole.isEmpty) return {};

    final doc = await _genericCollection(workspaceId, workspaceRole)
        .doc(roleId)
        .get();

    final data = doc.data();
    if (data == null || data['permissions'] == null) return {};

    final rawPermissions = data['permissions'] as List<dynamic>;
    return rawPermissions
        .map((e) => e['permission'] as String)
        .whereType<String>()
        .toSet();
  }

  /// Provides a Firestore CollectionReference to the roles collection.
  CollectionReference<Map<String, dynamic>> _genericCollection(
    String workspaceId,
    String workspaceRole,
  ) {
    return FirestoreHelper(
      firestore: _firestore,
      workspaceRole: workspaceRole,
      workspaceId: workspaceId,
    ).getCollectionRef(
      collectionType: CollectionType.workspace,
      rolesDBCollectionPath,
    );
  }
}
*/
