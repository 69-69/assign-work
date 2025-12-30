import 'dart:async';

import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/constants/collection_type.dart';
import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/network/data_sources/remote/repository/firestore_helper.dart';
import 'package:assign_erp/core/network/data_sources/remote/repository/firestore_repository.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/features/auth/data/data_sources/local/auth_cache_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class AgentRepository extends FirestoreRepository {
  late Box<CacheData> _cacheBox;

  final CollectionType? collectionType;

  final String collectionPath;
  final FirebaseFirestore firestore;
  StreamSubscription? _dataSubscription;

  final StreamController<List<CacheData>> _dataController =
      StreamController<List<CacheData>>.broadcast();
  bool _isDataControllerClosed = false;

  Stream<List<CacheData>> get dataStream => _dataController.stream;

  AgentRepository({
    this.collectionType,
    required this.firestore,
    required this.collectionPath,
    super.collectionRef,
  }) : super(
         collectionType: collectionType,
         firestore: firestore,
         collectionPath: collectionPath,
       ) {
    _init();
  }

  Future<void> _init() async {
    _cacheBox = await _openCacheBox();
    refreshCacheData();
  }

  /** PRIVATE METHODS */

  /// Track last emitted data
  List<CacheData>? _lastEmittedData;

  /// Open/Create Cache Hive-Box [_openCacheBox]
  Future<Box<CacheData>> _openCacheBox() async {
    if (!Hive.isBoxOpen(collectionPath)) {
      return await Hive.openBox<CacheData>(collectionPath);
    }
    return Hive.box<CacheData>(collectionPath);
  }

  /// Scope ID to restrict cache-data access to specific scope/context
  String get _scopeId {
    final authCacheService = AuthCacheService();
    return (authCacheService.getWorkspace())?.id ?? '';
  }

  /// Emit Data / Add Event to Stream [_emitDataToStream]
  /// @Param reEmit: If TRUE refetch/emit data
  void _emitDataToStream({bool reEmit = false}) {
    if (!_isDataControllerClosed) {
      final data = _getFromCache();

      // Emit only if 'data has changed or reEmit is true' to avoid duplicate entries in the UI
      if (reEmit || data.isEmpty || !listEquals(data, _lastEmittedData)) {
        _dataController.add(data); // Use the new list reference
        // Update the last emitted data to prevent re-emit
        _lastEmittedData = data;
      }
    }
  }

  /// Add to Cache/localStorage [_addToCache]
  /// [key] - The ID of the document to be added to the cache.
  Future<void> _addToCache(String key, CacheData cacheData) async {
    await _cacheBox.put(key, cacheData);
  }

  /// Read/Get all cache data [_getFromCache]
  List<CacheData> _getFromCache() {
    return _cacheBox.values.toList();
  }

  /// Read/Get cache data by id [_getCacheById]
  CacheData? _getCacheById(String id) => _cacheBox.get(id);

  /// Convert QuerySnapshot to `List<CacheData>` [_toList]
  List<CacheData> _toList(QuerySnapshot<Map<String, dynamic>> querySnapshot) {
    if (querySnapshot.docs.isEmpty) return [];

    return querySnapshot.docs.map((doc) {
      final data = _fromMap(doc.data(), doc.id);
      _addToCache(doc.id, data);
      return data;
    }).toList();

    /*querySnapshot.size > 0
        ? querySnapshot.docs.map((doc) => _fromMap(doc.data(), doc.id)).toList()
        : [];*/
  }

  CacheData _fromMap(Map<String, dynamic> data, String id) =>
      CacheData.fromMap(data, id: id, scopeId: _scopeId);

  /** PUBLIC METHODS */

  /// [getAgentClientWorkspaces] Get Client workspaces associated with Agent
  Future<List<CacheData>> getAgentClientWorkspaces() async {
    final clientSnapshot = await findAll();
    if (clientSnapshot.size == 0) return [];

    // Step 1: Extract client data maps
    final clientDataList = clientSnapshot.docs
        .map((doc) => doc.data())
        .toList();

    // Step 2: Extract workspace IDs
    final workspaceIds = clientDataList
        .map((c) => c['clientWorkspaceId'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    // Step 3: Get cached + missing workspace data
    final cached = <CacheData>[];
    final missingIds = <String>[];

    for (final id in workspaceIds) {
      final cachedData = _getCacheById(id);
      bool isValid =
          cachedData != null && cachedData.data['clientWorkspace'] != null;
      if (isValid) {
        cached.add(cachedData);
        // prettyPrint('✅ Cached workspace doc', cachedData.data);
      } else {
        missingIds.add(id);
        prettyPrint('❌ Missing workspace doc', id);
      }
    }

    // Step 4: Batch fetch from Firestore if needed
    const batchSize = 30;
    final List<List<String>> chunks = [];

    for (int i = 0; i < missingIds.length; i += batchSize) {
      final end = (i + batchSize < missingIds.length)
          ? i + batchSize
          : missingIds.length;
      chunks.add(missingIds.sublist(i, end));
    }

    final futures = chunks.map((chunk) async {
      final snapshot = await _getCollectionRef(
        ids: chunk,
      ); // Fetch workspace docs
      return snapshot.docs
          .map(
            (doc) =>
                CacheData.fromMap(doc.data(), id: doc.id, scopeId: _scopeId),
          )
          .toList();
    });

    final fetchedChunks = await Future.wait(futures);
    final fetched = fetchedChunks.expand((e) => e).toList();
    cached.addAll(fetched);

    // Step 5: Create map for merging
    final workspaceMap = {for (var ws in cached) ws.id: ws.data};

    // Step 6: Merge and wrap into CacheData
    final List<CacheData> enrichedCacheData = clientDataList.map((client) {
      final workspaceId = client['clientWorkspaceId'];
      final workspaceData = workspaceMap[workspaceId];

      final enrichedMap = {
        'clientWorkspaceId': workspaceId,
        'commission': client['commission'] ?? [],
        'assignedAt': client['assignedAt'],
        'clientWorkspace': workspaceData,
      };
      final enriched = CacheData(
        id: workspaceId,
        data: enrichedMap,
        scopeId: _scopeId,
      );
      _addToCache(
        workspaceId,
        enriched,
      ); // ✅ Now cache full enriched client+workspace

      // prettyPrint('📌 Merged map', enrichedMap);
      return enriched;
    }).toList();

    /*prettyPrint(
      '✅ Repo loadedData',enrichedCacheData.map((e) => e.data).join('\n'),
    );*/

    return enrichedCacheData;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getCollectionRef({
    List<String> ids = const [],
  }) async {
    final fireHelper = FirestoreHelper();

    final collectionRef = fireHelper.getCollectionRef(
      collectionType: CollectionType.global,
      workspaceAccDBColPath,
    );

    final repo = await collectionRef
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    return repo;
  }

  /// Load Remote Data to Cache / LocalStorage [refreshCacheData]
  Future<void> refreshCacheData({Completer<void>? completer}) async {
    await _dataSubscription?.cancel();

    _dataSubscription = getDataStream().listen(
      (snapshot) {
        _toList(snapshot);
        _emitDataToStream(reEmit: true);

        completer?.complete(); //Notify once update is done
        // Emit updated data to stream
        // _emitDataToStream();
      },
      onError: (e) {
        prettyPrint('Data-Repository Error', '$e');
        completer?.completeError(e); // Optional: report error
      },
    );
  }

  /// Dispose or cancel Subscription [cancelDataSubscription]
  void cancelDataSubscription() {
    _dataSubscription?.cancel();
    _closeStreamController();
  }

  /// Close the stream controller [_closeStreamController]
  void _closeStreamController() {
    if (!_isDataControllerClosed) {
      _dataController.close();
      _isDataControllerClosed = true;
    }
  }
}
