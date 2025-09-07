import 'dart:async';

import 'package:assign_erp/core/constants/collection_type.dart';
import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/features/pos_system/domain/repository/pos_repository.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pos_event.dart';
part 'pos_state.dart';

/// POSBloc
///
class POSBloc<T> extends Bloc<POSEvent, POSState<T>> {
  final POSRepository _posRepository;

  /// toCache/toJson Function [toCache]
  final Map<String, dynamic> Function(T data) toCache;

  /// toJson/toMap Function [toFirestore]
  final Map<String, dynamic> Function(T data) toFirestore;

  /// fromJson/fromMap Function [fromFirestore]
  final T Function(Map<String, dynamic> data, String documentId) fromFirestore;

  // Set up the stream subscription
  late StreamSubscription<List<CacheData>> _getDataStreamObserver;

  POSBloc({
    required FirebaseFirestore firestore,
    required String collectionPath,
    required this.fromFirestore,
    required this.toFirestore,
    required this.toCache,
  }) : _posRepository = POSRepository(
         collectionType: CollectionType.stores,
         firestore: firestore,
         collectionPath: collectionPath,
       ),
       super(LoadingPOS<T>()) {
    _initialize();

    _posRepository.dataStream.listen(
      (cacheData) => add(_POSLoaded<T>(_toList(cacheData))),
    );

    // on<_POSLoaded<T>>((event, emit) => emit(POSsLoaded<T>(event.data)));
  }

  Future<void> _initialize() async {
    // on<GetShortIDEvent<T>>(_onGetShortID);
    on<RefreshPOSs<T>>(_onRefreshPOSs);
    on<GetPOSs<T>>(_onGetPOS);
    on<GetPOSById<T>>(_onGetPOSById);
    on<GetPOSsByIds<T>>(_onGetPOSsByIds);
    on<GetPOSsWithSameId<T>>(_onGetPOSsWithSameId);
    on<SearchPOS<T>>(_onSearchPOS);
    on<AddPOS<T>>(_onAddPOS);
    on<AddPOS<List<T>>>(_onAddMultiplePOS);
    on<UpdatePOS>(_onUpdatePOS);
    on<DeletePOS<String>>(_onDeletePOS);
    on<DeletePOS<List<String>>>(_onMultiDeletePOS);
    on<_ShortIDLoaded<T>>(_onShortUIDLoaded);
    on<_POSLoaded<T>>(_onPOSLoaded);
    on<_SinglePOSLoaded<T>>(_onSinglePOSLoaded);
    on<_POSLoadError>(_onPOSLoadError);
  }

  Future<void> _onRefreshPOSs(
    RefreshPOSs<T> event,
    Emitter<POSState> emit,
  ) async {
    emit(LoadingPOS<T>());
    try {
      // Trigger data refresh in the DataRepository
      await _posRepository.refreshCacheData();

      // Fetch the updated data from the repository
      final snapshot = await _posRepository.getAllCacheData().first;
      final data = _toList(snapshot);

      // Emit the loaded state with the refreshed data
      emit(POSsLoaded<T>(data));
    } catch (e) {
      // Emit an error state in case of failure
      emit(POSError<T>(e.toString()));
    }
  }

  /// Load All Data Function [_onGetPOS]
  Future<void> _onGetPOS(GetPOSs<T> event, Emitter<POSState<T>> emit) async {
    emit(LoadingPOS<T>());

    try {
      _getDataStreamObserver = _posRepository.getAllCacheData().listen(
        (snapshot) async {
          final data = _toList(snapshot);

          // Update internal state in the BLoC to reflect data loaded
          emit(POSsLoaded<T>(data));

          // Trigger an event to handle the loaded data
          // add(_POSLoadedEvent<T>(data));

          // Optionally, emit another state or handle other logic
          // emit(DataAddedState<T>()); // For example, notify that data is added
        },
        onError: (e) {
          add(_POSLoadError('Error loading data: $e'));
        },
      );

      // Await for the subscription to be done (optional)
      await _getDataStreamObserver.asFuture();

      /*List<CacheData> firstData =  await _posRepository.getAllData().first; // Ensure await

      final data = _listDoc(firstData);

      emit(DataLoadedState<T>(data));*/
    } catch (e) {
      emit(POSError<T>('Error loading data: $e'));
    } finally {
      // Ensure to cancel the subscription when it's no longer needed
      // This could be in the dispose() method of a widget or BLoC
      _getDataStreamObserver.cancel();
    }
  }

  Future<void> _onGetPOSsByIds(
    GetPOSsByIds<T> event,
    Emitter<POSState<T>> emit,
  ) async {
    emit(LoadingPOS<T>());
    try {
      final localDataList = await _posRepository.getMultipleDataByIDs(
        event.documentIDs,
      );

      if (localDataList.isNotEmpty) {
        final data = _toList(localDataList);

        add(_POSLoaded<T>(data));
        // emit(DataLoadedState<T>(data));
      }
    } catch (e) {
      emit(POSError<T>(e.toString()));
    }
  }

  Future<void> _onGetPOSById(
    GetPOSById<T> event,
    Emitter<POSState<T>> emit,
  ) async {
    emit(LoadingPOS<T>());
    try {
      final localData = await _posRepository.getDataById(
        event.documentId,
        field: event.field,
      );

      if (localData != null) {
        final data = fromFirestore(localData.data, localData.id);
        add(_SinglePOSLoaded<T>(data));
      } else {
        emit(POSError<T>('Document not found'));
      }
    } catch (e) {
      emit(POSError<T>(e.toString()));
    }
  }

  Future<void> _onGetPOSsWithSameId(
    GetPOSsWithSameId<T> event,
    Emitter<POSState<T>> emit,
  ) async {
    emit(LoadingPOS<T>());
    try {
      final localData = await _posRepository.getAllDataWithSameId(
        event.documentId,
        field: event.field,
      );

      if (localData.isNotEmpty) {
        final data = _toList(localData);
        emit(POSsLoaded<T>(data));
      } else {
        emit(POSError<T>('Data not found'));
      }
    } catch (e) {
      emit(POSError<T>(e.toString()));
    }
  }

  Future<void> _onSearchPOS(
    SearchPOS<T> event,
    Emitter<POSState<T>> emit,
  ) async {
    emit(LoadingPOS<T>());
    try {
      List<CacheData> data = await _posRepository.searchData(
        field: event.field ?? '',
        query: event.query,
        optField: event.optField,
        auxField: event.auxField,
      );

      var localData = _toList(data);
      emit(POSsLoaded<T>(localData));
      // emit(DataLoadedState<T>(data.cast<T>()));
    } catch (e) {
      emit(POSError<T>('Error searching data: $e'));
    }
  }

  Future<void> _onAddPOS(AddPOS<T> event, Emitter<POSState<T>> emit) async {
    try {
      // Add data to Firestore and update local storage
      await _posRepository.createData(toCache(event.data));

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(POSAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(POSError<T>(e.toString()));
    }
  }

  Future<void> _onAddMultiplePOS(
    AddPOS<List<T>> event,
    Emitter<POSState<T>> emit,
  ) async {
    try {
      for (var item in event.data) {
        // Add data to Firestore
        await _posRepository.createData(toCache(item));
      }

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(POSAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(POSError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onUpdatePOS(UpdatePOS event, Emitter<POSState<T>> emit) async {
    try {
      final isPartialUpdate = event.mapData?.isNotEmpty ?? false;
      final data = isPartialUpdate
          ? {'data': event.mapData}
          : toCache(event.data as T);

      await _posRepository.updateData(
        event.documentId,
        data: data,
        isPartial: isPartialUpdate, // true if not a full model update
      );

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data updated
      emit(POSUpdated<T>(message: 'data updated successfully'));
    } catch (e) {
      emit(POSError<T>(e.toString()));
    }
  }

  Future<void> _onDeletePOS(
    DeletePOS<String> event,
    Emitter<POSState<T>> emit,
  ) async {
    try {
      // Delete data from Firestore and update local storage
      await _posRepository.deleteData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(GetPOSs<T>());

      // Update State: Notify that data deleted
      emit(POSDeleted<T>(message: 'data deleted successfully'));
    } catch (e) {
      emit(POSError<T>(e.toString()));
    }
  }

  Future<void> _onMultiDeletePOS(
    DeletePOS<List<String>> event,
    Emitter<POSState<T>> emit,
  ) async {
    try {
      for (var id in event.documentId) {
        // Delete data from Firestore and update local storage
        await _posRepository.deleteData(id);
      }

      // Trigger LoadDataEvent to reload the data
      add(GetPOSs<T>());

      // Update State: Notify that data deleted
      emit(POSDeleted<T>(message: 'data deleted successfully'));
    } catch (e) {
      emit(POSError<T>(e.toString()));
    }
  }

  void _onShortUIDLoaded(_ShortIDLoaded<T> event, Emitter<POSState<T>> emit) {
    emit(POSLoaded<T>(event.shortID));
  }

  void _onPOSLoaded(_POSLoaded<T> event, Emitter<POSState<T>> emit) {
    emit(POSsLoaded<T>(event.data));
  }

  void _onSinglePOSLoaded(
    _SinglePOSLoaded<T> event,
    Emitter<POSState<T>> emit,
  ) {
    emit(POSLoaded<T>(event.data));
  }

  void _onPOSLoadError(_POSLoadError event, Emitter<POSState<T>> emit) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(error: event.error, fileName: 'pos_bloc');
    emit(POSError<T>(event.error));
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
    _posRepository.cancelDataSubscription();
    return super.close();
  }
}
