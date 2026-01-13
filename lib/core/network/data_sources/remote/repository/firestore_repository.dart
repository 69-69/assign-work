import 'package:assign_erp/core/network/data_sources/remote/repository/firestore_helper.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/collection_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A repository class for managing Firestore operations. [FirestoreRepository]
///
/// This class provides methods for querying, retrieving, adding, updating,
/// and deleting documents in a Firestore collection.
class FirestoreRepository extends FirestoreHelper {
  final String? _collectionName;
  final CollectionType _collectionType;
  final CollectionReference<Map<String, dynamic>>? _collectionRef;

  /// Default Constructor
  /// Creates an instance of [FirestoreRepository].
  ///
  /// [collectionPath] is the path to the Firestore collection you want to manage.
  /// [collectionRef] is an optional reference to a specific Firestore collection.
  /// [firestore] is the Firestore instance used for database operations.
  FirestoreRepository({
    String? collectionPath,
    FirebaseFirestore? firestore,
    CollectionType? collectionType,
    CollectionReference<Map<String, dynamic>>? collectionRef,
  }) : _collectionType = collectionType ?? CollectionType.workspace,
       _collectionRef = collectionRef,
       _collectionName = collectionPath,
       super(firestore: firestore ?? FirebaseFirestore.instance);

  /// Optional Named Constructor [withCollectionName]
  /// Creates an instance of [FirestoreRepository] with a specific collection name.
  FirestoreRepository.withCollectionName({String? collectionPath})
    : this(collectionPath: collectionPath);

  /// Retrieves a [CollectionReference] for the Firestore collection based on the current context.
  ///
  /// This getter returns a Firestore collection reference as follows:
  ///
  /// 1. If [_collectionRef] is already initialized (not null), it returns that existing reference.
  /// 2. If [_collectionRef] is null, it constructs a new collection reference:
  ///    - If [_useStoreRef] is true, it calls `getStoreCollectionRef` with [_collectionName] (or an empty string if `_collectionPath` is null).
  ///    - If [_useStoreRef] is false, it calls `getCollectionRef` with [_collectionName] (or an empty string if `_collectionPath` is null).
  ///
  /// The constructed collection reference will point to a path formatted as:
  /// 'workspaceRole/workspaceId/collectionName', where:
  /// - `workspaceRole` and `workspaceId` are derived from the workspace settings.
  /// - `collectionName` is specified by `_collectionPath`.
  ///
  /// Returns:
  /// - A [CollectionReference] pointing to the Firestore collection based on the given conditions.
  CollectionReference<Map<String, dynamic>> get _resolvedCollectionRef {
    if (_collectionRef != null) return _collectionRef;

    final collectionRef = getCollectionRef(
      _collectionName ?? '',
      collectionType: _collectionType,
    );

    prettyPrint(
      'Collection-Type: $_collectionType\nCollection-Path',
      collectionRef.path,
    );

    return collectionRef;
    /*return _useStoreRef
        ? getStoresCollectionRef(_collectionName ?? '')
        : getCollectionRef(_collectionName ?? '', useGlobalRef: _useGlobalRef);*/
  }

  /// Returns a stream of [QuerySnapshot]s that emit updates when the collection changes.
  ///
  /// This method provides real-time updates from the Firestore collection. The returned
  /// [Stream] will continuously emit snapshots whenever there are changes in the collection.
  ///
  /// Example usage:
  /// ```dart
  /// firestoreRepo.getDataStream().listen((snapshot) {
  ///   for (var doc in snapshot.docs) {
  ///     print(doc.data());
  ///   }
  /// });
  /// ```
  Stream<QuerySnapshot<Map<String, dynamic>>> getDataStream() {
    return _resolvedCollectionRef.snapshots().map((snapshot) => snapshot);
    // return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Retrieves all documents from the Firestore collection.
  ///
  /// This method performs a single query to fetch all documents in the collection at the
  /// time of the call and returns a [QuerySnapshot] containing the documents.
  ///
  /// Example usage:
  /// ```dart
  /// QuerySnapshot snapshot = await firestoreRepo.findAll();
  /// for (var doc in snapshot.docs) {
  ///   print(doc.id);
  ///   print(doc.data());
  /// }
  /// ```
  Future<QuerySnapshot<Map<String, dynamic>>> findAll() async {
    return await _resolvedCollectionRef.get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> searchAll(
    Object field, {
    required String term,
  }) async {
    return await _resolvedCollectionRef
        .where(field, isGreaterThanOrEqualTo: term)
        .where(field, isLessThanOrEqualTo: '$term\uf8ff')
        .get();
  }

  /// Finds a document where a specific field matches a given term.
  ///
  /// This method performs a query to find documents where the specified [field] is equal
  /// to the given [term]. The result is limited to a single document.
  ///
  /// [field] is the name of the field to query.
  /// [term] is the value to match against the field.
  ///
  /// Example usage:
  /// ```dart
  /// QuerySnapshot snapshot = await firestoreRepo.findOneByAny('email', term: 'example@example.com');
  /// if (snapshot.docs.isNotEmpty) {
  ///   print(snapshot.docs.first.data());
  /// }
  /// ```
  Future<QuerySnapshot<Map<String, dynamic>>> findOneByAny(
    Object field, {
    required String term,
  }) async {
    return await _resolvedCollectionRef
        .where(field, isEqualTo: term)
        .limit(1)
        .get();
  }

  /// Finds all documents in the collection where a specified field matches a given term.
  ///
  /// This method queries the Firestore collection to retrieve all documents where the
  /// value of the specified field matches the provided search term. The results are
  /// ordered by the specified field.
  ///
  /// [field] - The name of the field to query on.
  /// [term] - The value that the field should match.
  ///
  /// Returns a [QuerySnapshot] containing all documents that match the query.
  ///
  /// Example usage:
  /// ```dart
  /// QuerySnapshot<Map<String, dynamic>> result = await findAllByAny('status', term: 'active');
  /// ```
  Future<QuerySnapshot<Map<String, dynamic>>> findAllByAny(
    Object field, {
    required String term,
  }) async {
    return await _resolvedCollectionRef
        .where(field, isEqualTo: term)
        .orderBy(field)
        .get();
  }

  /// Fetches multiple documents from Firestore using their document IDs.
  ///
  /// This method is useful when you have a list of known document IDs
  /// and want to retrieve all corresponding documents in a single query.
  ///
  /// Parameters:
  /// - [ids] A list of Firestore document IDs to retrieve.
  ///
  /// Returns:
  /// - A [QuerySnapshot] containing all matched documents.
  Future<QuerySnapshot<Map<String, dynamic>>> findManyByIds({
    required List<String> ids,
  }) async {
    return await _resolvedCollectionRef
        .where(FieldPath.documentId, whereIn: ids)
        .get();
  }

  /// Finds documents in the collection where a specified field and an auxiliary field
  /// match given terms.
  ///
  /// This method queries the Firestore collection to retrieve all documents where the
  /// value of the specified field matches the primary term and the value of the auxiliary
  /// field matches the auxiliary term.
  ///
  /// [field] - The name of the primary field to query on.
  /// [auxField] - The name of the auxiliary field to query on.
  /// [term] - The value that the primary field should match.
  /// [auxTerm] - The value that the auxiliary field should match.
  ///
  /// Returns a [QuerySnapshot] containing all documents that match the query.
  ///
  /// Example usage:
  /// ```dart
  /// QuerySnapshot<Map<String, dynamic>> result = await findByAny('role', 'status', term: 'admin', auxTerm: 'active');
  /// ```
  Future<QuerySnapshot<Map<String, dynamic>>> findByAny(
    Object field,
    Object auxField, {
    required String term,
    required String auxTerm,
  }) async {
    return await _resolvedCollectionRef
        .where(field, isEqualTo: term)
        .where(auxField, isEqualTo: auxTerm)
        .get();
  }

  /// Retrieves a document by its ID.
  ///
  /// This method fetches a single document from the collection using its [docId].
  ///
  /// [docId] is the ID of the document to retrieve.
  ///
  /// Example usage:
  /// ```dart
  /// DocumentSnapshot doc = await firestoreRepo.findManyById('docId');
  /// print(doc.data());
  /// ```
  Future<DocumentSnapshot<Map<String, dynamic>>> findById(String docId) async {
    return await _resolvedCollectionRef.doc(docId).get();
  }

  /// Adds a new document with the given [data] to the Firestore collection.
  ///
  /// This method creates a new document in the collection with the specified [data]. It
  /// returns a [DocumentReference] pointing to the newly created document.
  ///
  /// [data] is a map containing the document's fields and values.
  ///
  /// Example usage:
  /// ```dart
  /// DocumentReference docRef = await firestoreRepo.addData({'name': 'Jane Doe', 'age': 25});
  /// ```
  Future<DocumentReference<Map<String, dynamic>>> addData(
    Map<String, dynamic> data,
  ) async {
    DocumentReference<Map<String, dynamic>> docRef;

    // If 'id' field exists and it's invalid (null or empty), manually generate an ID.
    if (data.containsKey('id') && (data['id'] == null || data['id'].isEmpty)) {
      // Create a reference with Firestore auto-generated ID
      docRef = _resolvedCollectionRef.doc();
      data['id'] = docRef.id; // Assign the generated ID to the data map
      await docRef.set(data);
    } else {
      docRef = await _resolvedCollectionRef.add(data);
    }

    return docRef; // Return the reference (whether it was auto-generated or specified)
  }

  /// Updates an existing document or creates a new one if it does not exist.
  ///
  /// This method updates an existing document identified by [docId] with the provided [data].
  /// If the document with the given ID does not exist, a new document will be created with
  /// the provided data.
  ///
  /// [docId] is the ID of the document to update.
  /// [data] is a map containing the fields and values to update or set.
  ///
  /// Example usage:
  /// ```dart
  /// await firestoreRepo.updateById('docId', data: {'name': 'John Doe', 'age': 32});
  /// ```
  Future<void> updateById(
    String docId, {
    required Map<String, dynamic> data,
  }) async {
    final docRef = _resolvedCollectionRef.doc(docId);

    // If doc exist, update it, else create new doc with data
    return docRef.id.isNotEmpty
        ? await docRef.update(data)
        : await docRef.set(data);
  }

  /// NOTE: Overrides an existing document or creates a new one if it does not exist.
  ///
  /// This method overrides an existing document identified by [docId] with the provided [data] - [overrideById]
  Future<void> overrideById(
    String docId, {
    required Map<String, dynamic> data,
  }) async {
    // If doc exist, override it, else create new doc data with this docId
    return await _resolvedCollectionRef
        .doc(docId)
        .set(data, SetOptions(merge: false));
  }

  /// Deletes a document from the collection by its ID.
  ///
  /// This method removes a document from the collection identified by [docId].
  ///
  /// [docId] is the ID of the document to delete.
  ///
  /// Example usage:
  /// ```dart
  /// await firestoreRepo.deleteById('docId');
  /// ```
  Future<void> deleteById(String docId) async {
    await _resolvedCollectionRef.doc(docId).delete();
  }

  /// CHAT RELATED METHODS

  /// Returns the chat document reference for a specific user within a workspace.
  /// `/collectionPath/workspaceId/chats/`
  CollectionReference<Map<String, dynamic>> _chatRef({String? workspaceId}) {
    return (workspaceId == null
        ? _resolvedCollectionRef
        : getChatCollectionRef(_collectionName!, workspaceId: workspaceId));
  }

  /// Update a message by its ID in a specific user's chat.
  Future<DocumentReference<Map<String, dynamic>>> sendChatMessage(
    Map<String, dynamic> data, {
    String? workspaceId,
    String? userName,
    String? chatId,
  }) async {
    final chatDoc = _chatRef(workspaceId: workspaceId).doc(chatId);

    // Update chat metadata
    final chatUpdateData = <String, dynamic>{
      'lastMessage': data['message'],
      'updatedAt': data['createdAt'],
      'isResolved': false,
      if (userName != null) 'userName': userName,
    };

    await chatDoc.set(chatUpdateData, SetOptions(merge: true));

    // Prepare message data by removing non-message fields
    // final messageData = Map<String, dynamic>.from(data)..remove('summary');

    return await chatDoc.collection('messages').add(data);
  }

  /// Get a stream of chat overviews ordered by latest activity.
  /// `/collectionPath/workspaceId/chats/`
  Stream<QuerySnapshot<Map<String, dynamic>>> getChatOverviews({
    required String workspaceId,
  }) {
    return _chatRef(
      workspaceId: workspaceId,
    ).orderBy('updatedAt', descending: true).snapshots();
  }

  /// Get real-time messages for a specific chat (i.e., user).
  /// `/collectionPath/workspaceId/chats/chatId/messages/`
  Stream<QuerySnapshot<Map<String, dynamic>>> getChatMessages({
    required String workspaceId,
    required String chatId,
  }) {
    return _chatRef(workspaceId: workspaceId)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /*Future<void> removeDeviceIdFromWorkspace({
    required String deviceId,
    required String email,
  }) async {
    final userDoc = await findOneByAny('email', term: email);

    if (userDoc.docs.isEmpty) return;

    final user = userDoc.docs.first;
    // update an item in the array
    await user.reference.update({
      'authorizedDeviceIds': FieldValue.arrayUnion([deviceId]),
    });
    // Remove an item from the array
    await user.reference.update({
    'authorizedDeviceIds': FieldValue.arrayRemove(['deviceId'])
  });
  }*/
}
