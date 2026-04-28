import 'dart:async';

import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/util/extensions/collection_type.dart';
import 'package:assign_erp/features/procurement/domain/repository/procurement_repository.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'procurement_event.dart';

part 'procurement_state.dart';

/// ProcurementBloc
///
class ProcurementBloc<T> extends Bloc<ProcurementEvent, ProcurementState<T>> {
  final ProcurementRepository _procurementRepository;

  /// toCache/toJson Function [toCache]
  final Map<String, dynamic> Function(T data) toCache;

  /// toJson/toMap Function [toFirestore]
  final Map<String, dynamic> Function(T data) toFirestore;

  /// fromJson/fromMap Function [fromFirestore]
  final T Function(Map<String, dynamic> data, String documentId) fromFirestore;
  final CollectionType? collectionType;

  // Set up the stream subscription
  StreamSubscription<List<CacheData>>? _getDataStreamObserver;

  ProcurementBloc({
    required FirebaseFirestore firestore,
    required String collectionPath,
    required this.fromFirestore,
    required this.toFirestore,
    required this.toCache,
    this.collectionType,
  }) : _procurementRepository = ProcurementRepository(
         firestore: firestore,
         collectionPath: collectionPath,
         collectionType: collectionType ?? CollectionType.stores,
       ),
       super(LoadingProcurement<T>()) {
    _initialize();

    _procurementRepository.dataStream.listen(
      (cacheData) => add(_ProcurementsLoaded<T>(_toList(cacheData))),
    );
  }

  Future<void> _initialize() async {
    // on<GetShortIDEvent<T>>(_onGetShortID);
    on<RefreshProcurements<T>>(_onRefresh);
    on<GetProcurements<T>>(_onGet);
    on<GetProcurementById<T>>(_onGetById);
    on<GetProcurementsByIds<T>>(_onGetByIds);
    on<GetProcurementsWithSameId<T>>(_onGetWithSameId);
    on<SearchProcurement<T>>(_onSearch);
    on<AddProcurement<T>>(_onAdd);
    on<AddProcurement<List<T>>>(_onAddMany);
    on<UpdateProcurement>(_onUpdate);
    on<AuditProcurement>(_onAuditLog);
    on<DeleteProcurement<String>>(_onDelete);
    on<DeleteProcurement<List<String>>>(_onDeleteMany);
    on<_ShortIDLoaded<T>>(_onShortUIDLoaded);
    on<_ProcurementsLoaded<T>>(_onLoaded);
    on<_ProcurementLoaded<T>>(_onSingleLoaded);
    on<_ProcurementLoadError>(_onLoadError);
  }

  Future<void> _onRefresh(
    RefreshProcurements<T> event,
    Emitter<ProcurementState<T>> emit,
  ) async {
    emit(LoadingProcurement<T>());
    try {
      // Trigger data refresh in the DataRepository
      await _procurementRepository.refreshCacheData();

      // Fetch the updated data from the repository
      final snapshot = await _procurementRepository.getAllCacheData().first;
      final data = _toList(snapshot);

      // Emit the loaded state with the refreshed data
      emit(ProcurementsLoaded<T>(data));
    } catch (e) {
      add(_ProcurementLoadError('Error refreshing Procurement: $e'));
      // Emit an error state in case of failure
      emit(ProcurementError<T>(e.toString()));
    }
  }

  /// Load All Data Function [_onGet]
  Future<void> _onGet(
    GetProcurements<T> event,
    Emitter<ProcurementState<T>> emit,
  ) async {
    emit(LoadingProcurement<T>());

    try {
      _getDataStreamObserver = _procurementRepository.getAllCacheData().listen(
        (snapshot) async {
          final data = _toList(snapshot);

          // Update internal state in the BLoC to reflect data loaded
          emit(ProcurementsLoaded<T>(data));

          // Trigger an event to handle the loaded data
          // add(_ProcurementLoadedEvent<T>(data));

          // Optionally, emit another state or handle other logic
          // emit(DataAddedState<T>()); // For example, notify that data is added
        },
        onError: (e) {
          add(_ProcurementLoadError('Error loading data: $e'));
        },
      );

      // Await for the subscription to be done (optional)
      // await _getDataStreamObserver.asFuture();

      /*List<CacheData> firstData =  await _dataRepository.getAllData().first; // Ensure await

      final data = _listDoc(firstData);

      emit(DataLoadedState<T>(data));*/
    } catch (e) {
      add(_ProcurementLoadError('Error loading procurements: $e'));
      emit(ProcurementError<T>('Error loading data: $e'));
    } finally {
      // Ensure to cancel the subscription when it's no longer needed
      // This could be in the dispose() method of a widget or BLoC
      _getDataStreamObserver?.cancel();
    }
  }

  Future<void> _onGetByIds(
    GetProcurementsByIds<T> event,
    Emitter<ProcurementState<T>> emit,
  ) async {
    emit(LoadingProcurement<T>());
    try {
      final localDataList = await _procurementRepository.getManyDataByIDs(
        event.documentIDs,
      );

      if (localDataList.isNotEmpty) {
        final data = _toList(localDataList);

        add(_ProcurementsLoaded<T>(data));
        // emit(DataLoadedState<T>(data));
      }
    } catch (e) {
      add(_ProcurementLoadError('Error loading procurements by IDs: $e'));
      emit(ProcurementError<T>(e.toString()));
    }
  }

  Future<void> _onGetById(
    GetProcurementById<T> event,
    Emitter<ProcurementState<T>> emit,
  ) async {
    emit(LoadingProcurement<T>());
    try {
      final localData = await _procurementRepository.getDataById(
        event.documentId,
        field: event.field,
      );

      if (localData != null) {
        final data = fromFirestore(localData.data, localData.id);
        add(_ProcurementLoaded<T>(data));
      } else {
        emit(ProcurementError<T>('Document not found'));
      }
    } catch (e) {
      add(_ProcurementLoadError('Error loading procurement by ID: $e'));
      emit(ProcurementError<T>(e.toString()));
    }
  }

  Future<void> _onGetWithSameId(
    GetProcurementsWithSameId<T> event,
    Emitter<ProcurementState<T>> emit,
  ) async {
    emit(LoadingProcurement<T>());
    try {
      final localData = await _procurementRepository.getAllDataWithSameId(
        event.documentId,
        field: event.field,
      );

      if (localData.isNotEmpty) {
        final data = _toList(localData);
        emit(ProcurementsLoaded<T>(data));
      } else {
        emit(ProcurementError<T>('Data not found'));
      }
    } catch (e) {
      add(_ProcurementLoadError('Error loading procurements by same ID: $e'));
      emit(ProcurementError<T>(e.toString()));
    }
  }

  Future<void> _onSearch(
    SearchProcurement<T> event,
    Emitter<ProcurementState<T>> emit,
  ) async {
    emit(LoadingProcurement<T>());
    try {
      List<CacheData> data = await _procurementRepository.searchData(
        event.query,
        primaryField: event.primaryField ?? '',
        optionalField: event.optionalField,
        secondaryField: event.secondaryField,
        tertiaryField: event.tertiaryField,
      );

      var localData = _toList(data);
      emit(ProcurementsLoaded<T>(localData));
      // emit(DataLoadedState<T>(data.cast<T>()));
    } catch (e) {
      add(_ProcurementLoadError('Error searching procurements: $e'));
      emit(ProcurementError<T>('Error searching data: $e'));
    }
  }

  Future<void> _onAdd(
    AddProcurement<T> event,
    Emitter<ProcurementState<T>> emit,
  ) async {
    try {
      // Add data to Firestore and update local storage
      await _procurementRepository.createData(toCache(event.data));

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(ProcurementAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      add(_ProcurementLoadError('Error saving procurement: $e'));
      emit(ProcurementError<T>(e.toString()));
    }
  }

  Future<void> _onAddMany(
    AddProcurement<List<T>> event,
    Emitter<ProcurementState<T>> emit,
  ) async {
    try {
      for (var item in event.data) {
        // Add data to Firestore
        await _procurementRepository.createData(toCache(item));
      }

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(ProcurementAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      add(_ProcurementLoadError('Error saving procurements: $e'));
      emit(ProcurementError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onUpdate(
    UpdateProcurement event,
    Emitter<ProcurementState<T>> emit,
  ) async {
    try {
      final isPartialUpdate = event.mapData?.isNotEmpty ?? false;
      final data = isPartialUpdate
          ? {'data': event.mapData}
          : toCache(event.data as T);

      await _procurementRepository.updateData(
        event.documentId,
        data: data,
        isPartial: isPartialUpdate, // true if not a full model update
      );

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data updated
      emit(ProcurementUpdated<T>(message: 'Changes successfully saved'));
    } catch (e) {
      add(_ProcurementLoadError('Error updating procurement: $e'));
      emit(ProcurementError<T>(e.toString()));
    }
  }

  /// Use to add/update audit log [_onAuditLog]
  Future<void> _onAuditLog(
    AuditProcurement event,
    Emitter<ProcurementState<T>> emit,
  ) async {
    try {
      await _procurementRepository.updateData(
        event.documentId,
        data: {'data': event.log},
        isPartial: true, // true if not a full model update
      );
    } catch (e) {
      add(
        _ProcurementLoadError(
          'Error saving/updating procurement audit log: $e',
        ),
      );
      emit(ProcurementError<T>(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteProcurement<String> event,
    Emitter<ProcurementState<T>> emit,
  ) async {
    try {
      // Delete data from Firestore and update local storage
      await _procurementRepository.deleteData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(GetProcurements<T>());

      // Update State: Notify that data deleted
      emit(ProcurementDeleted<T>(message: 'Data deleted successfully'));
    } catch (e) {
      add(_ProcurementLoadError('Error deleting procurement: $e'));
      emit(ProcurementError<T>(e.toString()));
    }
  }

  Future<void> _onDeleteMany(
    DeleteProcurement<List<String>> event,
    Emitter<ProcurementState<T>> emit,
  ) async {
    try {
      if (event.documentId.isEmpty) {
        emit(ProcurementError<T>('No Procurement were selected to delete.'));
        return;
      }

      // Delete data from Firestore and update local storage
      await _procurementRepository.deleteManyData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(GetProcurements<T>());

      // Update State: Notify that data deleted
      emit(ProcurementDeleted<T>(message: 'Data deleted successfully'));
    } catch (e) {
      add(_ProcurementLoadError('Error deleting procurements: $e'));
      emit(ProcurementError<T>(e.toString()));
    }
  }

  void _onShortUIDLoaded(
    _ShortIDLoaded<T> event,
    Emitter<ProcurementState<T>> emit,
  ) {
    emit(ProcurementLoaded<T>(event.shortID));
  }

  void _onLoaded(
    _ProcurementsLoaded<T> event,
    Emitter<ProcurementState<T>> emit,
  ) {
    emit(ProcurementsLoaded<T>(event.data));
  }

  void _onSingleLoaded(
    _ProcurementLoaded<T> event,
    Emitter<ProcurementState<T>> emit,
  ) {
    emit(ProcurementLoaded<T>(event.data));
  }

  void _onLoadError(
    _ProcurementLoadError event,
    Emitter<ProcurementState<T>> emit,
  ) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(error: event.error, fileName: 'procurement_bloc');
    emit(ProcurementError<T>(event.error));
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
    _procurementRepository.cancelDataSubscription();
    _getDataStreamObserver?.cancel();
    return super.close();
  }
}
