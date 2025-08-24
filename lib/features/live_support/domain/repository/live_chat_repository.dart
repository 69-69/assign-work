import 'dart:async';

import 'package:assign_erp/core/constants/collection_type_enum.dart';
import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/network/data_sources/remote/repository/firestore_repository.dart';
import 'package:assign_erp/features/auth/data/data_sources/local/auth_cache_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class LiveChatRepository extends FirestoreRepository {
  late Box<CacheData> _cacheBox;

  final CollectionType? collectionType;

  final String collectionPath;
  final FirebaseFirestore firestore;
  StreamSubscription? _dataSubscription;

  final StreamController<List<CacheData>> _dataController =
      StreamController<List<CacheData>>.broadcast();
  bool _isDataControllerClosed = false;

  Stream<List<CacheData>> get dataStream => _dataController.stream;

  LiveChatRepository({
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

  Future<void> _init() async => _cacheBox = await _openCacheBox();

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
    return (authCacheService.getEmployee())?.id ?? '';
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
    return _cacheBox.values.where((v) => v.scopeId == _scopeId).toList();
  }

  /// Add New BackUp Data to Remote-Server (Firestore) [_backupNewDataToFirestore]
  Future<String> _backupNewDataToFirestore(
    CacheData item, {
    required String workspaceId,
    String? userName,
    String? chatId,
  }) async {
    final data = await sendChatMessage(
      item.data,
      chatId: chatId,
      userName: userName,
      workspaceId: workspaceId,
    );
    // prettyPrint('New Data Added: ${data.id}', item.data);

    return data.id;
  }

  /// Convert QuerySnapshot to `List<CacheData>` [_toList]
  List<CacheData> _toList(QuerySnapshot<Map<String, dynamic>> querySnapshot) {
    return querySnapshot.size > 0
        ? querySnapshot.docs.map((doc) => _fromMap(doc.data(), doc.id)).toList()
        : [];
  }

  CacheData _fromMap(Map<String, dynamic> data, String id) =>
      CacheData.fromMap(data, id: id, scopeId: _scopeId);

  /// Update/Push to Cache / LocalStorage [_updateCacheWithData]
  void _updateCacheWithData(List<CacheData> data) {
    for (var model in data) {
      _addToCache(model.id, model); // Add or update each item in the cache
    }
    _emitDataToStream(); // Update the stream with the latest data
  }

  /// LIVE CHAT METHODS
  Future<void> refreshChatCache(String workspaceId, String chatId) async {
    await _dataSubscription?.cancel();

    _dataSubscription =
        getChatMessages(workspaceId: workspaceId, chatId: chatId).listen((
          snapshot,
        ) {
          final List<CacheData> data = _toList(snapshot);
          _updateCacheWithData(data);
        }, onError: (e) => debugPrint('Chat Error: $e'));
  }

  Future<void> sendChat(
    Map<String, dynamic> data, {
    required String workspaceId,
    String? userName,
    String? chatId,
  }) async {
    final cacheData = CacheData.fromCache(data, id: '', scopeId: _scopeId);

    // Add to remote DB
    final docId = await _backupNewDataToFirestore(
      cacheData,
      workspaceId: workspaceId,
      userName: userName,
      chatId: chatId,
    );
    // Add to Cache/localStorage
    await _addToCache(docId, cacheData);
    // Update the stream with the latest data
    _emitDataToStream();
  }

  Stream<List<CacheData>> getChatByWorkspace({
    required String workspaceId,
    required String chatId,
  }) {
    refreshChatCache(workspaceId, chatId);
    return dataStream;
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
