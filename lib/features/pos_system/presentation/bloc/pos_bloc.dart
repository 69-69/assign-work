import 'dart:async';

import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/util/extensions/collection_type.dart';
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
  StreamSubscription<List<CacheData>>? _getDataStreamObserver;

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
    on<RefreshPOSs<T>>(_onRefresh);
    on<GetPOSs<T>>(_onGetPOS);
    on<GetPOSById<T>>(_onGetById);
    on<GetPOSsByIds<T>>(_onGetByIds);
    on<GetPOSsWithSameId<T>>(_onGetWithSameId);
    on<SearchPOS<T>>(_onSearch);
    on<AddPOS<T>>(_onAdd);
    on<AddPOS<List<T>>>(_onAddMany);
    on<UpdatePOS>(_onUpdate);
    on<DeletePOS<String>>(_onDelete);
    on<DeletePOS<List<String>>>(_onDeleteMany);
    on<_ShortIDLoaded<T>>(_onShortUIDLoaded);
    on<_POSLoaded<T>>(_onLoaded);
    on<_SinglePOSLoaded<T>>(_onSingleLoaded);
    on<_POSLoadError>(_onLoadError);
  }

  Future<void> _onRefresh(
    RefreshPOSs<T> event,
    Emitter<POSState<T>> emit,
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
      add(_POSLoadError('Error refreshing POSs: $e'));
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
          add(_POSLoadError('Error loading POSs: $e'));
          add(_POSLoadError('Error loading data: $e'));
        },
      );

      // Await for the subscription to be done (optional)
      await _getDataStreamObserver?.asFuture();

      /*List<CacheData> firstData =  await _posRepository.getAllData().first; // Ensure await

      final data = _listDoc(firstData);

      emit(DataLoadedState<T>(data));*/
    } catch (e) {
      add(_POSLoadError('Error loading POSs: $e'));
      emit(POSError<T>('Error loading data: $e'));
    } finally {
      // Ensure to cancel the subscription when it's no longer needed
      // This could be in the dispose() method of a widget or BLoC
      _getDataStreamObserver?.cancel();
    }
  }

  Future<void> _onGetByIds(
    GetPOSsByIds<T> event,
    Emitter<POSState<T>> emit,
  ) async {
    emit(LoadingPOS<T>());
    try {
      final localDataList = await _posRepository.getManyDataByIDs(
        event.documentIDs,
      );

      if (localDataList.isNotEmpty) {
        final data = _toList(localDataList);

        add(_POSLoaded<T>(data));
        // emit(DataLoadedState<T>(data));
      }
    } catch (e) {
      add(_POSLoadError('Error loading POSs by IDs: $e'));
      emit(POSError<T>(e.toString()));
    }
  }

  Future<void> _onGetById(
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
      add(_POSLoadError('Error loading POS by ID: $e'));
      emit(POSError<T>(e.toString()));
    }
  }

  Future<void> _onGetWithSameId(
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
      add(_POSLoadError('Error loading POSs with same ID: $e'));
      emit(POSError<T>(e.toString()));
    }
  }

  Future<void> _onSearch(
    SearchPOS<T> event,
    Emitter<POSState<T>> emit,
  ) async {
    emit(LoadingPOS<T>());
    try {
      List<CacheData> data = await _posRepository.searchData(
        event.query,
        primaryField: event.primaryField ?? '',
        optionalField: event.optionalField,
        secondaryField: event.secondaryField,
        tertiaryField: event.tertiaryField,
      );

      var localData = _toList(data);
      emit(POSsLoaded<T>(localData));
      // emit(DataLoadedState<T>(data.cast<T>()));
    } catch (e) {
      add(_POSLoadError('Error searching POSs: $e'));
      emit(POSError<T>('Error searching data: $e'));
    }
  }

  Future<void> _onAdd(AddPOS<T> event, Emitter<POSState<T>> emit) async {
    try {
      // Add data to Firestore and update local storage
      await _posRepository.createData(toCache(event.data));

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(POSAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      add(_POSLoadError('Error saving POS: $e'));
      emit(POSError<T>(e.toString()));
    }
  }

  Future<void> _onAddMany(
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
      add(_POSLoadError('Error saving POSs: $e'));
      emit(POSError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onUpdate(UpdatePOS event, Emitter<POSState<T>> emit) async {
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
      emit(POSUpdated<T>(message: 'Changes successfully saved'));
    } catch (e) {
      add(_POSLoadError('Error updating POS: $e'));
      emit(POSError<T>(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeletePOS<String> event,
    Emitter<POSState<T>> emit,
  ) async {
    try {
      // Delete data from Firestore and update local storage
      await _posRepository.deleteData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(GetPOSs<T>());

      // Update State: Notify that data deleted
      emit(POSDeleted<T>(message: 'Data deleted successfully'));
    } catch (e) {
      add(_POSLoadError('Error deleting POS: $e'));
      emit(POSError<T>(e.toString()));
    }
  }

  Future<void> _onDeleteMany(
    DeletePOS<List<String>> event,
    Emitter<POSState<T>> emit,
  ) async {
    try {
      if (event.documentId.isEmpty) {
        emit(POSError<T>('No POS were selected to delete.'));
        return;
      }

      // Delete data from Firestore and update local storage
      await _posRepository.deleteManyData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(GetPOSs<T>());

      // Update State: Notify that data deleted
      emit(POSDeleted<T>(message: 'Data deleted successfully'));
    } catch (e) {
      add(_POSLoadError('Error deleting POSs: $e'));
      emit(POSError<T>(e.toString()));
    }
  }

  void _onShortUIDLoaded(_ShortIDLoaded<T> event, Emitter<POSState<T>> emit) {
    emit(POSLoaded<T>(event.shortID));
  }

  void _onLoaded(_POSLoaded<T> event, Emitter<POSState<T>> emit) {
    emit(POSsLoaded<T>(event.data));
  }

  void _onSingleLoaded(
    _SinglePOSLoaded<T> event,
    Emitter<POSState<T>> emit,
  ) {
    emit(POSLoaded<T>(event.data));
  }

  void _onLoadError(_POSLoadError event, Emitter<POSState<T>> emit) {
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
    _getDataStreamObserver?.cancel();
    return super.close();
  }
}
