import 'dart:async';

import 'package:assign_erp/core/constants/collection_type.dart';
import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/features/inventory_ims/domain/repository/inventory_repository.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

/// InventoryBloc
///
class InventoryBloc<T> extends Bloc<InventoryEvent, InventoryState<T>> {
  final InventoryRepository _inventoryRepository;

  /// toCache/toJson Function [toCache]
  final Map<String, dynamic> Function(T data) toCache;

  /// toJson/toMap Function [toFirestore]
  final Map<String, dynamic> Function(T data) toFirestore;

  /// fromJson/fromMap Function [fromFirestore]
  final T Function(Map<String, dynamic> data, String documentId) fromFirestore;

  // Set up the stream subscription
  late StreamSubscription<List<CacheData>> _getDataStreamObserver;

  InventoryBloc({
    required FirebaseFirestore firestore,
    required String collectionPath,
    required this.fromFirestore,
    required this.toFirestore,
    required this.toCache,
  }) : _inventoryRepository = InventoryRepository(
         firestore: firestore,
         collectionPath: collectionPath,
         collectionType: CollectionType.stores,
       ),
       super(LoadingInventory<T>()) {
    _initialize();

    _inventoryRepository.dataStream.listen(
      (cacheData) => add(_InventoriesLoaded<T>(_toList(cacheData))),
    );
  }

  Future<void> _initialize() async {
    // on<GetShortIDEvent<T>>(_onGetShortID);
    on<RefreshInventories<T>>(_onRefreshInventories);
    on<GetInventories<T>>(_onGetInventories);
    on<GetInventoryById<T>>(_onGetInventoryById);
    on<GetInventoriesByIds<T>>(_onGetInventoriesByIds);
    on<GetInventoriesWithSameId<T>>(_onGetInventoriesWithSameId);
    on<SearchInventory<T>>(_onSearchInventory);
    on<AddInventory<T>>(_onAddInventory);
    on<AddInventory<List<T>>>(_onAddMultiInventory);
    on<UpdateInventory>(_onUpdateInventory);
    on<DeleteInventory<String>>(_onDeleteInventory);
    on<DeleteInventory<List<String>>>(_onMultiDeleteInventory);
    on<_ShortIDLoaded<T>>(_onShortUIDLoaded);
    on<_InventoriesLoaded<T>>(_onInventoryLoaded);
    on<_InventoryLoaded<T>>(_onSingleInventoryLoaded);
    on<_InventoryLoadError>(_onInventoryLoadError);
  }

  Future<void> _onRefreshInventories(
    RefreshInventories<T> event,
    Emitter<InventoryState<T>> emit,
  ) async {
    emit(LoadingInventory<T>());
    try {
      // Trigger data refresh in the DataRepository
      await _inventoryRepository.refreshCacheData();

      // Fetch the updated data from the repository
      final snapshot = await _inventoryRepository.getAllCacheData().first;
      final data = _toList(snapshot);

      // Emit the loaded state with the refreshed data
      emit(InventoriesLoaded<T>(data));
    } catch (e) {
      // Emit an error state in case of failure
      emit(InventoryError<T>(e.toString()));
    }
  }

  /// Load All Data Function [_onGetInventories]
  Future<void> _onGetInventories(
    GetInventories<T> event,
    Emitter<InventoryState<T>> emit,
  ) async {
    emit(LoadingInventory<T>());

    try {
      _getDataStreamObserver = _inventoryRepository.getAllCacheData().listen(
        (snapshot) async {
          final data = _toList(snapshot);

          // Update internal state in the BLoC to reflect data loaded
          emit(InventoriesLoaded<T>(data));

          // Trigger an event to handle the loaded data
          // add(_InventoryLoadedEvent<T>(data));

          // Optionally, emit another state or handle other logic
          // emit(DataAddedState<T>()); // For example, notify that data is added
        },
        onError: (e) {
          add(_InventoryLoadError('Error loading data: $e'));
        },
      );

      // Await for the subscription to be done (optional)
      // await _getDataStreamObserver.asFuture();

      /*List<CacheData> firstData =  await _dataRepository.getAllData().first; // Ensure await

      final data = _listDoc(firstData);

      emit(DataLoadedState<T>(data));*/
    } catch (e) {
      emit(InventoryError<T>('Error loading data: $e'));
    } finally {
      // Ensure to cancel the subscription when it's no longer needed
      // This could be in the dispose() method of a widget or BLoC
      _getDataStreamObserver.cancel();
    }
  }

  Future<void> _onGetInventoriesByIds(
    GetInventoriesByIds<T> event,
    Emitter<InventoryState<T>> emit,
  ) async {
    emit(LoadingInventory<T>());
    try {
      final localDataList = await _inventoryRepository.getMultipleDataByIDs(
        event.documentIDs,
      );

      if (localDataList.isNotEmpty) {
        final data = _toList(localDataList);

        add(_InventoriesLoaded<T>(data));
        // emit(DataLoadedState<T>(data));
      }
    } catch (e) {
      emit(InventoryError<T>(e.toString()));
    }
  }

  Future<void> _onGetInventoryById(
    GetInventoryById<T> event,
    Emitter<InventoryState<T>> emit,
  ) async {
    emit(LoadingInventory<T>());
    try {
      final localData = await _inventoryRepository.getDataById(
        event.documentId,
        field: event.field,
      );

      if (localData != null) {
        final data = fromFirestore(localData.data, localData.id);
        add(_InventoryLoaded<T>(data));
      } else {
        emit(InventoryError<T>('Document not found'));
      }
    } catch (e) {
      emit(InventoryError<T>(e.toString()));
    }
  }

  Future<void> _onGetInventoriesWithSameId(
    GetInventoriesWithSameId<T> event,
    Emitter<InventoryState<T>> emit,
  ) async {
    emit(LoadingInventory<T>());
    try {
      final localData = await _inventoryRepository.getAllDataWithSameId(
        event.documentId,
        field: event.field,
      );

      if (localData.isNotEmpty) {
        final data = _toList(localData);
        emit(InventoriesLoaded<T>(data));
      } else {
        emit(InventoryError<T>('Data not found'));
      }
    } catch (e) {
      emit(InventoryError<T>(e.toString()));
    }
  }

  Future<void> _onSearchInventory(
    SearchInventory<T> event,
    Emitter<InventoryState<T>> emit,
  ) async {
    emit(LoadingInventory<T>());
    try {
      List<CacheData> data = await _inventoryRepository.searchData(
        field: event.field ?? '',
        query: event.query,
        optField: event.optField,
        auxField: event.auxField,
      );

      var localData = _toList(data);
      emit(InventoriesLoaded<T>(localData));
      // emit(DataLoadedState<T>(data.cast<T>()));
    } catch (e) {
      emit(InventoryError<T>('Error searching data: $e'));
    }
  }

  Future<void> _onAddInventory(
    AddInventory<T> event,
    Emitter<InventoryState<T>> emit,
  ) async {
    try {
      // Add data to Firestore and update local storage
      await _inventoryRepository.createData(toCache(event.data));

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(InventoryAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(InventoryError<T>(e.toString()));
    }
  }

  Future<void> _onAddMultiInventory(
    AddInventory<List<T>> event,
    Emitter<InventoryState<T>> emit,
  ) async {
    try {
      for (var item in event.data) {
        // Add data to Firestore
        await _inventoryRepository.createData(toCache(item));
      }

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(InventoryAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(InventoryError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onUpdateInventory(
    UpdateInventory event,
    Emitter<InventoryState<T>> emit,
  ) async {
    try {
      final isPartialUpdate = event.mapData?.isNotEmpty ?? false;
      final data = isPartialUpdate
          ? {'data': event.mapData}
          : toCache(event.data as T);

      await _inventoryRepository.updateData(
        event.documentId,
        data: data,
        isPartial: isPartialUpdate, // true if not a full model update
      );

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data updated
      emit(InventoryUpdated<T>(message: 'data updated successfully'));
    } catch (e) {
      emit(InventoryError<T>(e.toString()));
    }
  }

  Future<void> _onDeleteInventory(
    DeleteInventory<String> event,
    Emitter<InventoryState<T>> emit,
  ) async {
    try {
      // Delete data from Firestore and update local storage
      await _inventoryRepository.deleteData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(GetInventories<T>());

      // Update State: Notify that data deleted
      emit(InventoryDeleted<T>(message: 'data deleted successfully'));
    } catch (e) {
      emit(InventoryError<T>(e.toString()));
    }
  }

  Future<void> _onMultiDeleteInventory(
    DeleteInventory<List<String>> event,
    Emitter<InventoryState<T>> emit,
  ) async {
    try {
      for (var id in event.documentId) {
        // Delete data from Firestore and update local storage
        await _inventoryRepository.deleteData(id);
      }

      // Trigger LoadDataEvent to reload the data
      add(GetInventories<T>());

      // Update State: Notify that data deleted
      emit(InventoryDeleted<T>(message: 'data deleted successfully'));
    } catch (e) {
      emit(InventoryError<T>(e.toString()));
    }
  }

  void _onShortUIDLoaded(
    _ShortIDLoaded<T> event,
    Emitter<InventoryState<T>> emit,
  ) {
    emit(InventoryLoaded<T>(event.shortID));
  }

  void _onInventoryLoaded(
    _InventoriesLoaded<T> event,
    Emitter<InventoryState<T>> emit,
  ) {
    emit(InventoriesLoaded<T>(event.data));
  }

  void _onSingleInventoryLoaded(
    _InventoryLoaded<T> event,
    Emitter<InventoryState<T>> emit,
  ) {
    emit(InventoryLoaded<T>(event.data));
  }

  void _onInventoryLoadError(
    _InventoryLoadError event,
    Emitter<InventoryState<T>> emit,
  ) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(error: event.error, fileName: 'inventory_bloc');
    emit(InventoryError<T>(event.error));
  }

  List<T> _toList(List<CacheData> cacheData) {
    return cacheData
        .map((cache) => fromFirestore(cache.data, cache.id))
        .toList();
  }

  /*Future<String> _generateUniqueID(CollectionReference ref) async {
    String shortId;

    while (true) {
      shortId = shortid.generate();
      final trimNewId = _replaceSpecialCharsWithRandomNumbers(shortId);
      DocumentSnapshot doc = await ref.doc(trimNewId).get();

      if (!doc.exists) {
        break;
      }
    }

    return shortId.toUpperCase();
  }

  String _replaceSpecialCharsWithRandomNumbers(String str) {
    final Random random = Random();
    RegExp regExp = RegExp(r'[^a-zA-Z0-9]');
    String result = str.replaceAllMapped(regExp, (Match match) {
      return random.nextInt(10).toString();
    });

    return result;
  }*/

  @override
  Future<void> close() {
    _inventoryRepository.cancelDataSubscription();
    return super.close();
  }
}
