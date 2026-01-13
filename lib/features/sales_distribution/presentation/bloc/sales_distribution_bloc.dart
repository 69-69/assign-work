import 'dart:async';

import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/util/extensions/collection_type.dart';
import 'package:assign_erp/features/sales_distribution/domain/repository/sales_distribution_repository.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sales_distribution_event.dart';
part 'sales_distribution_state.dart';

/// SalesDistributionBloc
///
class SalesDistributionBloc<T>
    extends Bloc<SalesDistributionEvent, SalesDistributionState<T>> {
  final SalesDistributionRepository _salesQuoteRepository;

  /// toCache/toJson Function [toCache]
  final Map<String, dynamic> Function(T data) toCache;

  /// toJson/toMap Function [toFirestore]
  final Map<String, dynamic> Function(T data) toFirestore;

  /// fromJson/fromMap Function [fromFirestore]
  final T Function(Map<String, dynamic> data, String documentId) fromFirestore;
  final CollectionType? collectionType;

  // Set up the stream subscription
  StreamSubscription<List<CacheData>>? _getDataStreamObserver;

  SalesDistributionBloc({
    required FirebaseFirestore firestore,
    required String collectionPath,
    required this.fromFirestore,
    required this.toFirestore,
    required this.toCache,
    this.collectionType,
  }) : _salesQuoteRepository = SalesDistributionRepository(
         firestore: firestore,
         collectionPath: collectionPath,
         collectionType: collectionType ?? CollectionType.stores,
       ),
       super(LoadingSalesDistribution<T>()) {
    _initialize();

    _salesQuoteRepository.dataStream.listen(
      (cacheData) => add(_SalesDistributionsLoaded<T>(_toList(cacheData))),
    );
  }

  Future<void> _initialize() async {
    // on<GetShortIDEvent<T>>(_onGetShortID);
    on<RefreshSalesDistributions<T>>(_onRefreshSalesDistributions);
    on<GetSalesDistributions<T>>(_onGetSalesDistributions);
    on<GetSalesDistributionById<T>>(_onGetSalesDistributionById);
    on<GetSalesDistributionsByIds<T>>(_onGetSalesDistributionsByIds);
    on<GetSalesDistributionsWithSameId<T>>(_onGetSalesDistributionsWithSameId);
    on<SearchSalesDistribution<T>>(_onSearchSalesDistribution);
    on<AddSalesDistribution<T>>(_onAddSalesDistribution);
    on<AddSalesDistribution<List<T>>>(_onAddSalesDistributions);
    on<UpdateSalesDistribution>(_onUpdateSalesDistribution);
    on<AuditSalesDistribution>(_onAuditLog);
    on<DeleteSalesDistribution<String>>(_onDeleteSalesDistribution);
    on<DeleteSalesDistribution<List<String>>>(_onDeleteSalesDistributions);
    on<_ShortIDLoaded<T>>(_onShortUIDLoaded);
    on<_SalesDistributionsLoaded<T>>(_onSalesDistributionLoaded);
    on<_SalesDistributionLoaded<T>>(_onSingleSalesDistributionLoaded);
    on<_SalesDistributionLoadError>(_onSalesDistributionLoadError);
  }

  Future<void> _onRefreshSalesDistributions(
    RefreshSalesDistributions<T> event,
    Emitter<SalesDistributionState<T>> emit,
  ) async {
    emit(LoadingSalesDistribution<T>());
    try {
      // Trigger data refresh in the DataRepository
      await _salesQuoteRepository.refreshCacheData();

      // Fetch the updated data from the repository
      final snapshot = await _salesQuoteRepository.getAllCacheData().first;
      final data = _toList(snapshot);

      // Emit the loaded state with the refreshed data
      emit(SalesDistributionsLoaded<T>(data));
    } catch (e) {
      // Emit an error state in case of failure
      emit(SalesDistributionError<T>(e.toString()));
    }
  }

  /// Load All Data Function [_onGetSalesDistributions]
  Future<void> _onGetSalesDistributions(
    GetSalesDistributions<T> event,
    Emitter<SalesDistributionState<T>> emit,
  ) async {
    emit(LoadingSalesDistribution<T>());

    try {
      _getDataStreamObserver = _salesQuoteRepository.getAllCacheData().listen(
        (snapshot) {
          final data = _toList(snapshot);
          emit(SalesDistributionsLoaded<T>(data));
        },
        onError: (e) =>
            add(_SalesDistributionLoadError('Error loading data: $e')),
      );
    } catch (e) {
      emit(SalesDistributionError<T>('Error loading data: $e'));
    } finally {
      // Ensure to cancel the subscription when it's no longer needed
      // This could be in the dispose() method of a widget or BLoC
      _getDataStreamObserver?.cancel();
    }
  }

  Future<void> _onGetSalesDistributionsByIds(
    GetSalesDistributionsByIds<T> event,
    Emitter<SalesDistributionState<T>> emit,
  ) async {
    emit(LoadingSalesDistribution<T>());
    try {
      final localDataList = await _salesQuoteRepository.getManyDataByIDs(
        event.documentIDs,
      );

      if (localDataList.isNotEmpty) {
        final data = _toList(localDataList);

        add(_SalesDistributionsLoaded<T>(data));
        // emit(DataLoadedState<T>(data));
      }
    } catch (e) {
      emit(SalesDistributionError<T>(e.toString()));
    }
  }

  Future<void> _onGetSalesDistributionById(
    GetSalesDistributionById<T> event,
    Emitter<SalesDistributionState<T>> emit,
  ) async {
    emit(LoadingSalesDistribution<T>());
    try {
      final localData = await _salesQuoteRepository.getDataById(
        event.documentId,
        field: event.field,
      );

      if (localData != null) {
        final data = fromFirestore(localData.data, localData.id);
        add(_SalesDistributionLoaded<T>(data));
      } else {
        emit(SalesDistributionError<T>('Document not found'));
      }
    } catch (e) {
      emit(SalesDistributionError<T>(e.toString()));
    }
  }

  Future<void> _onGetSalesDistributionsWithSameId(
    GetSalesDistributionsWithSameId<T> event,
    Emitter<SalesDistributionState<T>> emit,
  ) async {
    emit(LoadingSalesDistribution<T>());
    try {
      final localData = await _salesQuoteRepository.getAllDataWithSameId(
        event.documentId,
        field: event.field,
      );

      if (localData.isNotEmpty) {
        final data = _toList(localData);
        emit(SalesDistributionsLoaded<T>(data));
      } else {
        emit(SalesDistributionError<T>('Data not found'));
      }
    } catch (e) {
      emit(SalesDistributionError<T>(e.toString()));
    }
  }

  Future<void> _onSearchSalesDistribution(
    SearchSalesDistribution<T> event,
    Emitter<SalesDistributionState<T>> emit,
  ) async {
    emit(LoadingSalesDistribution<T>());
    try {
      List<CacheData> data = await _salesQuoteRepository.searchData(
        event.query,
        primaryField: event.primaryField ?? '',
        optionalField: event.optionalField,
        secondaryField: event.secondaryField,
        tertiaryField: event.tertiaryField,
      );

      var localData = _toList(data);
      emit(SalesDistributionsLoaded<T>(localData));
      // emit(DataLoadedState<T>(data.cast<T>()));
    } catch (e) {
      emit(SalesDistributionError<T>('Error searching data: $e'));
    }
  }

  Future<void> _onAddSalesDistribution(
    AddSalesDistribution<T> event,
    Emitter<SalesDistributionState<T>> emit,
  ) async {
    try {
      // Add data to Firestore and update local storage
      await _salesQuoteRepository.createData(toCache(event.data));

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(SalesDistributionAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(SalesDistributionError<T>(e.toString()));
    }
  }

  Future<void> _onAddSalesDistributions(
    AddSalesDistribution<List<T>> event,
    Emitter<SalesDistributionState<T>> emit,
  ) async {
    try {
      for (var item in event.data) {
        // Add data to Firestore
        await _salesQuoteRepository.createData(toCache(item));
      }

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(SalesDistributionAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(SalesDistributionError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onUpdateSalesDistribution(
    UpdateSalesDistribution event,
    Emitter<SalesDistributionState<T>> emit,
  ) async {
    try {
      final isPartialUpdate = event.mapData?.isNotEmpty ?? false;
      final data = isPartialUpdate
          ? {'data': event.mapData}
          : toCache(event.data as T);

      await _salesQuoteRepository.updateData(
        event.documentId,
        data: data,
        isPartial: isPartialUpdate, // true if not a full model update
      );

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data updated
      emit(SalesDistributionUpdated<T>(message: 'data updated successfully'));
    } catch (e) {
      emit(SalesDistributionError<T>(e.toString()));
    }
  }

  /// Use to add/update audit log [_onAuditLog]
  Future<void> _onAuditLog(
    AuditSalesDistribution event,
    Emitter<SalesDistributionState<T>> emit,
  ) async {
    try {
      await _salesQuoteRepository.updateData(
        event.documentId,
        data: {'data': event.log},
        isPartial: true, // true if not a full model update
      );
    } catch (e) {
      emit(SalesDistributionError<T>(e.toString()));
    }
  }

  Future<void> _onDeleteSalesDistribution(
    DeleteSalesDistribution<String> event,
    Emitter<SalesDistributionState<T>> emit,
  ) async {
    try {
      // Delete data from Firestore and update local storage
      await _salesQuoteRepository.deleteData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(GetSalesDistributions<T>());

      // Update State: Notify that data deleted
      emit(SalesDistributionDeleted<T>(message: 'data deleted successfully'));
    } catch (e) {
      emit(SalesDistributionError<T>(e.toString()));
    }
  }

  Future<void> _onDeleteSalesDistributions(
    DeleteSalesDistribution<List<String>> event,
    Emitter<SalesDistributionState<T>> emit,
  ) async {
    try {
      // Delete data from Firestore and update local storage
      await _salesQuoteRepository.deleteManyData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(GetSalesDistributions<T>());

      // Update State: Notify that data deleted
      emit(SalesDistributionDeleted<T>(message: 'data deleted successfully'));
    } catch (e) {
      emit(SalesDistributionError<T>(e.toString()));
    }
  }

  void _onShortUIDLoaded(
    _ShortIDLoaded<T> event,
    Emitter<SalesDistributionState<T>> emit,
  ) {
    emit(SalesDistributionLoaded<T>(event.shortID));
  }

  void _onSalesDistributionLoaded(
    _SalesDistributionsLoaded<T> event,
    Emitter<SalesDistributionState<T>> emit,
  ) {
    emit(SalesDistributionsLoaded<T>(event.data));
  }

  void _onSingleSalesDistributionLoaded(
    _SalesDistributionLoaded<T> event,
    Emitter<SalesDistributionState<T>> emit,
  ) {
    emit(SalesDistributionLoaded<T>(event.data));
  }

  void _onSalesDistributionLoadError(
    _SalesDistributionLoadError event,
    Emitter<SalesDistributionState<T>> emit,
  ) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(
      error: event.error,
      fileName: 'sales_distribution_bloc',
    );
    emit(SalesDistributionError<T>(event.error));
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
    _salesQuoteRepository.cancelDataSubscription();
    _getDataStreamObserver?.cancel();
    return super.close();
  }
}
