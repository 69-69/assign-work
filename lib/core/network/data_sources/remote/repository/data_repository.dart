import 'dart:async';

import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/network/data_sources/remote/repository/firestore_repository.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/collection_type.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/auth/data/data_sources/local/auth_cache_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class DataRepository extends FirestoreRepository {
  late Box<CacheData> _cacheBox;

  final CollectionType? collectionType;

  final String collectionPath;
  final FirebaseFirestore firestore;
  StreamSubscription? _dataSubscription;

  final StreamController<List<CacheData>> _dataController =
      StreamController<List<CacheData>>.broadcast();
  bool _isDataControllerClosed = false;

  Stream<List<CacheData>> get dataStream => _dataController.stream;

  DataRepository({
    this.collectionType,
    required this.firestore,
    required this.collectionPath,
    super.collectionRef,
  }) : super(
         firestore: firestore,
         collectionType: collectionType,
         collectionPath: collectionPath,
       ) {
    _init();
  }

  Future<void> _init() async {
    _cacheBox = await _openCacheBox();
    refreshCacheData();
  }

  final AuthCacheService _authCacheService = AuthCacheService();

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
  String get _scopeId => (_authCacheService.getWorkspace())?.id ?? '';

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

  /// Retrieves all cached data from [_getFromCache].
  List<CacheData> _getFromCache() {
    final List<CacheData> data = _cacheBox.values.toList();

    // If the collection type is 'stores', filter the data by store number.
    if (collectionType == CollectionType.stores) {
      String storeNumber = (_authCacheService.getEmployee())?.storeNumber ?? '';

      // Return only the cache entries that match the store number.
      return data.where((i) => i.data['storeNumber'] == storeNumber).toList();
    }

    // Return all cached data if the collection type is not 'stores'.
    return data;
  }

  /// Read/Get cache data by id [_getCacheById]
  CacheData? _getCacheById(String id) => _cacheBox.get(id);

  /// Read/Get cache data by index position [_getCacheByIndex]
  CacheData? _getCacheByIndex(int i) => _cacheBox.getAt(i);

  /// Add New BackUp Data to Remote-Server (Firestore) [_saveRemoteData]
  Future<String> _saveRemoteData(CacheData item) async {
    final id = (await addData(item.data)).id;
    return id;
  }

  /// Update BackUp Data to Remote-Server (Firestore) [_updateRemoteData]
  Future<void> _updateRemoteData(CacheData item) async {
    await updateById(item.id, data: item.data);
  }

  /// Override remote data
  Future<void> _overrideRemoteData(CacheData item) async {
    await overrideById(item.id, data: item.data);
  }

  /// Helper function to search in local HiveBox
  List<CacheData> _searchLocalCache(Object field, String query) {
    List<CacheData> dataList = [];

    for (int i = 0; i < _cacheBox.length; i++) {
      final cachedData = _getCacheByIndex(i);
      if (cachedData != null && cachedData.data.containsKey(field)) {
        dynamic fieldValue = cachedData.data[field];
        if (fieldValue.toString().toLowerAll.contains(query.toLowerAll)) {
          dataList.add(cachedData);
        }
      }
    }

    return dataList;
  }

  /// Helper function to search in Firestore based on provided table `field, optField, and auxField`
  Future<List<CacheData>> _searchRemote(
    String searchTerm, {
    required Object primaryField,
    Object? optionalField,
    Object? secondaryField,
    Object? tertiaryField,
  }) async {
    List<CacheData> dataList = [];

    try {
      // First search with the primary search field
      var querySnapshot = await searchAll(primaryField, term: searchTerm);

      if (querySnapshot.size > 0) {
        dataList = _toList(querySnapshot);
      }

      // Search with the `optionalField` if no results
      if (dataList.isEmpty && optionalField != null) {
        querySnapshot = await searchAll(optionalField, term: searchTerm);

        dataList = _toList(querySnapshot);

        // Search with the `secondaryField` if no results
        if (dataList.isEmpty && secondaryField != null) {
          querySnapshot = await searchAll(secondaryField, term: searchTerm);
          dataList = _toList(querySnapshot);
        }

        // Search with the `tertiaryField` if no results
        if (dataList.isEmpty && tertiaryField != null) {
          querySnapshot = await searchAll(tertiaryField, term: searchTerm);
          dataList = _toList(querySnapshot);
        }
      }

      // Fallback to `search by ID` if still no results
      if (dataList.isEmpty) {
        var docSnapshot = await findById(searchTerm);
        if (docSnapshot.exists && docSnapshot.data() != null) {
          dataList.add(_fromMap(docSnapshot.data()!, docSnapshot.id));
        }
      }
      return dataList;
    } catch (e) {
      return [];
    }
  }

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

  /// Add/Create New Data Function [createData]
  Future<void> createData(Map<String, dynamic> data) async {
    final cacheData = CacheData.fromCache(data, id: '', scopeId: _scopeId);

    // Add to remote DB
    final docId = await _saveRemoteData(cacheData);
    // Add to Cache/localStorage
    await _addToCache(docId, cacheData);
    // Update the stream with the latest data
    _emitDataToStream();
  }

  /// Update/Modify Data Function [updateData]
  Future<void> updateData(
    String id, {
    bool? isPartial,
    required Map<String, dynamic> data,
  }) async {
    var updates = data;

    // Only merge if this is its partial update & NOT a full model update
    if (isPartial == true) {
      final exist = _getCacheById(id);
      if (exist == null) return;

      // Merge field update into existing cached data
      updates = {...exist.data, ...data};
    }

    final cacheData = CacheData.fromCache(updates, id: id, scopeId: _scopeId);

    await _addToCache(cacheData.id, cacheData);
    await _updateRemoteData(cacheData);
    _emitDataToStream(); // Update the stream with the latest data
  }

  /// Override Data Function [overrideData]
  Future<void> overrideData(
    String id, {
    required Map<String, dynamic> data,
  }) async {
    if (id.isEmpty) return;

    final cacheData = CacheData.fromCache(data, id: id, scopeId: _scopeId);

    await _addToCache(cacheData.id, cacheData);
    await _overrideRemoteData(cacheData);

    _emitDataToStream(); // Update the stream with the latest data
  }

  /// Delete/Remove Single Data Function [deleteData]
  Future<void> deleteData(String id) async => await deleteManyData([id]);

  /// Delete Multiple Data Function [deleteManyData]
  Future<void> deleteManyData(Iterable<String> ids) async {
    if (ids.isEmpty) return;

    // 1️⃣ Delete from cache & Flush cache to disk
    await _cacheBox.deleteAll(ids);
    await _cacheBox.flush();

    // 2️⃣ Delete from remote (parallel)
    await Future.wait(ids.map(deleteById));

    // 3️⃣ Emit/Update the stream with the latest data
    _emitDataToStream(reEmit: true);
    // prettyPrint('steve-cache-keys', _cacheBox.get(id)?.data.toString());
  }

  /// Get All Data from Cache [getAllCacheData]
  Stream<List<CacheData>> getAllCacheData() {
    _emitDataToStream();
    return dataStream;
  }

  /// Get All Data from Firestore [getAllRemoteData]
  Future<List<CacheData>> getAllRemoteData() async {
    List<CacheData> dataList = [];
    final querySnapshot = await findAll();

    if (querySnapshot.size > 0) {
      dataList = _toList(querySnapshot);
    }
    return dataList;
  }

  /// Get Multiple Data by IDs [getManyDataByIDs]
  Future<List<CacheData>> getManyDataByIDs(List<String> ids) async {
    List<CacheData> dataList = [];

    for (String id in ids) {
      CacheData? cacheData = _getCacheById(id);

      if (cacheData != null) {
        dataList.add(cacheData);
      } else {
        final docSnapshot = await findById(id);

        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = _fromMap(docSnapshot.data()!, docSnapshot.id);
          await _addToCache(id, data);

          dataList.add(data);
        }
      }
    }
    _emitDataToStream();
    return dataList;
  }

  /// Get All Data with Same ID [getAllDataWithSameId]
  Future<List<CacheData>> getAllDataWithSameId(
    String id, {
    Object? field,
  }) async {
    List<CacheData> dataList = [];

    if (field != null && field.toString().isNotEmpty) {
      for (int i = 0; i < _cacheBox.length; i++) {
        final cachedData = _getCacheByIndex(i);

        if (cachedData != null && cachedData.id == id) {
          dataList.add(cachedData);
        } else {
          final querySnapshot = await findAllByAny(field, term: id);

          if (querySnapshot.size > 0) {
            dataList = _toList(querySnapshot);
            _emitDataToStream();
          }
        }
      }
    }
    return dataList;
  }

  /*/// ⚠️ Note:
  /// - Firestore limits `whereIn` to a maximum of 30 IDs per query + Cost.
  ///   So, if you need to fetch more than 30 documents, you must batch the calls like this [getMultiDataByIds]:
  Future<List<CacheData>> getMultiDataByIds(List<String> ids) async {
    List<CacheData> cached = [];
    List<String> missingIds = [];

    // 1. Get from Cache
    for (String id in ids) {
      final data = _getCacheById(id);
      if (data != null) {
        cached.add(data);
      } else {
        missingIds.add(id);
      }
    }

    // 2. If missing, fetch from Firestore in chunks
    if (missingIds.isNotEmpty) {
      const int batchSize = 30;
      final List<List<String>> chunks = [];

      for (int i = 0; i < missingIds.length; i += batchSize) {
        final end = (i + batchSize < missingIds.length)
            ? i + batchSize
            : missingIds.length;
        chunks.add(missingIds.sublist(i, end));
      }

      // Fetch all in parallel
      final futures = chunks.map((chunk) async {
        final snapshot = await findManyByIds(ids: chunk);
        return snapshot.docs.map((doc) {
          final data = _fromMap(doc.data(), doc.id);

          _addToCache(doc.id, data); // Add to cache
          return data;
        }).toList();
      });

      final fetchedChunks = await Future.wait(futures);
      final fetched = fetchedChunks.expand((e) => e).toList();
      cached.addAll(fetched);
    }

    // 3. Emit updated data if changed
    _emitDataToStream();

    return cached;
  }*/

  /// Get Single Data by ID [getDataById]
  Future<CacheData?> getDataById(String id, {Object? field}) async {
    CacheData? data = _getCacheById(id);

    if (data != null) {
      return data;
    } else {
      if (field != null && field.toString().isNotEmpty) {
        final querySnapshot = await findOneByAny(field, term: id);
        final data = _toList(querySnapshot).firstOrNull;

        if (data != null) return data;
      } else {
        final docSnapshot = await findById(id);
        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = _fromMap(docSnapshot.data()!, docSnapshot.id);
          await _addToCache(id, data);
          return data;
        }
        return null;
      }
    }
    return null;
  }

  /// Search Specific Data By field-Name(s) [searchData]
  Future<List<CacheData>> searchData(
    String query, {
    required Object primaryField,
    Object? optionalField,
    Object? secondaryField,
    Object? tertiaryField,
  }) async {
    try {
      List<CacheData> dataList = [];

      dataList = _searchLocalCache(primaryField, query);

      if (dataList.isEmpty) {
        dataList = await _searchRemote(
          query,
          primaryField: primaryField,
          optionalField: optionalField,
          secondaryField: secondaryField,
          tertiaryField: tertiaryField,
        );
      }

      return dataList;
    } catch (e) {
      throw Exception('Error searching dataList: $e');
    }
  }

  /// Manually BackUp Data by Admin/User using Button Click to Remote-Server (Firestore) [manualBackupDataToFirestore]
  Future<void> manualBackupDataToFirestore() async {
    try {
      final allData = _getFromCache();
      // final firestore = _subscriberRepository.firestore; // Get the Firestore instance
      final batch = firestore.batch();
      final snapshot = await findAll();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      for (final data in allData) {
        await updateById(data.id, data: data.data);
      }
    } catch (e) {
      // Handle the error appropriately
    }
  }

  /// Load Remote Data to Cache / LocalStorage [refreshCacheData]
  Future<void> refreshCacheData() async {
    await _dataSubscription?.cancel();

    _dataSubscription = getDataStream().listen((snapshot) {
      _toList(snapshot);
      // Emit updated data to stream
      _emitDataToStream(reEmit: true);
    }, onError: (e) => prettyPrint('Data-Repository Error', '$e'));
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
