import 'dart:async';

import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/util/extensions/collection_type.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:assign_erp/features/app_training/domain/repository/app_training_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_training_event.dart';

part 'app_training_state.dart';

/// AppTrainingBloc
///
class AppTrainingBloc<T> extends Bloc<AppTrainingEvent, AppTrainingState<T>> {
  final AppTrainingRepository _guideRepository;

  // final FirebaseFirestore _firestore;
  final String collectionPath;
  final CollectionType? collectionType;

  /// toCache/toJson Function [toCache]
  final Map<String, dynamic> Function(T data) toCache;

  /// toJson/toMap Function [toFirestore]
  final Map<String, dynamic> Function(T data) toFirestore;

  /// fromJson/fromMap Function [fromFirestore]
  final T Function(Map<String, dynamic> data, String documentId) fromFirestore;

  // Set up the stream subscription
  StreamSubscription<List<CacheData>>? _getDataStreamObserver;

  AppTrainingBloc({
    this.collectionType,
    required FirebaseFirestore firestore,
    required this.collectionPath,
    required this.fromFirestore,
    required this.toFirestore,
    required this.toCache,
  }) : _guideRepository = AppTrainingRepository(
         collectionType: collectionType,
         firestore: firestore,
         collectionPath: collectionPath,
       ),
       super(LoadingTrainings<T>()) {
    _initialize();

    _guideRepository.dataStream.listen(
      (cacheData) => add(_TrainingsLoaded<T>(_toList(cacheData))),
    );

    on<_TrainingsLoaded<T>>(
      (event, emit) => emit(TrainingsLoaded<T>(event.data)),
    );
  }

  Future<void> _initialize() async {
    on<RefreshTrainings<T>>(_onRefresh);
    on<LoadTrainings<T>>(_onLoad);
    on<LoadTrainingById<T>>(_onLoadById);
    on<AddTraining<T>>(_onAdd);
    on<AddTraining<List<T>>>(_onAddMany);
    on<UpdateTraining>(_onUpdate);
    on<DeleteTraining<String>>(_onDelete);
    on<DeleteTraining<List<String>>>(_onDeleteMany);
    on<_TrainingLoaded<T>>(_onLoaded);
    on<_TrainingError>(_onLoadError);
  }

  Future<void> _onRefresh(
    RefreshTrainings<T> event,
    Emitter<AppTrainingState<T>> emit,
  ) async {
    emit(LoadingTrainings<T>());
    try {
      // Trigger data refresh in the DataRepository
      await _guideRepository.refreshCacheData();

      // Fetch the updated data from the repository
      final snapshot = await _guideRepository.getAllCacheData().first;
      final data = _toList(snapshot);

      // Emit the loaded state with the refreshed data
      emit(TrainingsLoaded<T>(data));
    } catch (e) {
      // Emit an error state in case of failure
      emit(TrainingError<T>(e.toString()));
    }
  }

  /// Load All Data Function [_onLoad]
  Future<void> _onLoad(
    LoadTrainings<T> event,
    Emitter<AppTrainingState<T>> emit,
  ) async {
    emit(LoadingTrainings<T>());

    try {
      _getDataStreamObserver = _guideRepository.getAllCacheData().listen(
        (snapshot) async {
          final data = _toList(snapshot);

          // Update internal state in the BLoC to reflect data loaded
          emit(TrainingsLoaded<T>(data));

          // Trigger an event to handle the loaded data
          // add(_GuideLoadedEvent<T>(data));

          // Optionally, emit another state or handle other logic
          // emit(GuideAddedState<T>()); // For example, notify that data is added
        },
        onError: (e) {
          add(_TrainingError('Error loading data: $e'));
        },
      );

      // Await for the subscription to be done (optional)
      await _getDataStreamObserver?.asFuture();
    } catch (e) {
      emit(TrainingError<T>('Error loading data: $e'));
    } finally {
      // Ensure to cancel the subscription when it's no longer needed
      // This could be in the dispose() method of a widget or BLoC
      _getDataStreamObserver?.cancel();
    }
  }

  Future<void> _onLoadById(
    LoadTrainingById<T> event,
    Emitter<AppTrainingState<T>> emit,
  ) async {
    emit(LoadingTrainings<T>());
    try {
      final localData = await _guideRepository.getDataById(
        event.documentId,
        field: event.field,
      );

      if (localData != null) {
        final data = fromFirestore(localData.data, localData.id);
        add(_TrainingLoaded<T>(data));
      } else {
        emit(TrainingError<T>('Document not found'));
      }
    } catch (e) {
      emit(TrainingError<T>(e.toString()));
    }
  }

  Future<void> _onAdd(
    AddTraining<T> event,
    Emitter<AppTrainingState<T>> emit,
  ) async {
    try {
      // Add data to Firestore and update local storage
      await _guideRepository.createData(toCache(event.data));

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(TrainingAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(TrainingError<T>(e.toString()));
    }
  }

  Future<void> _onAddMany(
    AddTraining<List<T>> event,
    Emitter<AppTrainingState<T>> emit,
  ) async {
    try {
      for (var item in event.data) {
        // Add data to Firestore
        _guideRepository.createData(toCache(item));
      }

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(TrainingAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(TrainingError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onUpdate(
    UpdateTraining event,
    Emitter<AppTrainingState<T>> emit,
  ) async {
    try {
      final isPartialUpdate = event.mapData?.isNotEmpty ?? false;
      final data = isPartialUpdate
          ? {'data': event.mapData}
          : toCache(event.data as T);

      await _guideRepository.updateData(
        event.documentId,
        data: data,
        isPartial: isPartialUpdate, // true if not a full model update
      );

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data updated
      emit(TrainingUpdated<T>(message: 'Changes successfully saved'));
    } catch (e) {
      emit(TrainingError<T>(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteTraining<String> event,
    Emitter<AppTrainingState<T>> emit,
  ) async {
    try {
      // Delete data from Firestore and update local storage
      await _guideRepository.deleteData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(LoadTrainings<T>());

      // Update State: Notify that data deleted
      emit(TrainingDeleted<T>(message: 'Data deleted successfully'));
    } catch (e) {
      emit(TrainingError<T>(e.toString()));
    }
  }

  Future<void> _onDeleteMany(
    DeleteTraining<List<String>> event,
    Emitter<AppTrainingState<T>> emit,
  ) async {
    try {
      // Delete data from Firestore and update local storage
      await _guideRepository.deleteManyData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(LoadTrainings<T>());

      // Update State: Notify that data deleted
      emit(TrainingDeleted<T>(message: 'Data deleted successfully'));
    } catch (e) {
      emit(TrainingError<T>(e.toString()));
    }
  }

  /*void _onGuideLoaded(_GuidesLoaded<T> event, Emitter<GuideState<T>> emit) {
    emit(GuidesLoaded<T>(event.data));
  }*/

  void _onLoaded(_TrainingLoaded<T> event, Emitter<AppTrainingState<T>> emit) {
    emit(TrainingLoaded<T>(event.data));
  }

  void _onLoadError(_TrainingError event, Emitter<AppTrainingState<T>> emit) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(error: event.error, fileName: 'user_guide_bloc');
    emit(TrainingError<T>(event.error));
  }

  List<T> _toList(List<CacheData> cacheData) {
    return cacheData
        .map((cache) => fromFirestore(cache.data, cache.id))
        .toList();
  }

  @override
  Future<void> close() {
    _guideRepository.cancelDataSubscription();
    _getDataStreamObserver?.cancel();
    return super.close();
  }
}
