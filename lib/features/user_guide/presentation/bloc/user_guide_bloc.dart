import 'dart:async';

import 'package:assign_erp/core/constants/collection_type.dart';
import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:assign_erp/features/user_guide/domain/repository/user_guide_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'user_guide_event.dart';
part 'user_guide_state.dart';

/// UserGuideBloc
///
class GuideBloc<T> extends Bloc<GuideEvent, GuideState<T>> {
  final GuideRepository _guideRepository;
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
  late StreamSubscription<List<CacheData>> _subscription;

  GuideBloc({
    this.collectionType,
    required FirebaseFirestore firestore,
    required this.collectionPath,
    required this.fromFirestore,
    required this.toFirestore,
    required this.toCache,
  }) : _guideRepository = GuideRepository(
         collectionType: collectionType,
         firestore: firestore,
         collectionPath: collectionPath,
       ),
       super(LoadingGuides<T>()) {
    _initialize();

    _guideRepository.dataStream.listen(
      (cacheData) => add(_GuidesLoaded<T>(_toList(cacheData))),
    );

    on<_GuidesLoaded<T>>((event, emit) => emit(GuidesLoaded<T>(event.data)));
  }

  Future<void> _initialize() async {
    on<RefreshGuides<T>>(_onRefreshGuides);
    on<LoadGuides<T>>(_onLoadGuides);
    on<LoadGuideById<T>>(_onLoadGuideById);
    on<AddGuide<T>>(_onAddGuide);
    on<AddGuide<List<T>>>(_onAddMultiGuide);
    on<UpdateGuide>(_onUpdateGuide);
    on<DeleteGuide>(_onDeleteGuide);
    on<_GuideLoaded<T>>(_onGuideLoaded);
    on<_GuideError>(_onGuideLoadError);
  }

  Future<void> _onRefreshGuides(
    RefreshGuides<T> event,
    Emitter<GuideState<T>> emit,
  ) async {
    emit(LoadingGuides<T>());
    try {
      // Trigger data refresh in the DataRepository
      await _guideRepository.refreshCacheData();

      // Fetch the updated data from the repository
      final snapshot = await _guideRepository.getAllCacheData().first;
      final data = _toList(snapshot);

      // Emit the loaded state with the refreshed data
      emit(GuidesLoaded<T>(data));
    } catch (e) {
      // Emit an error state in case of failure
      emit(GuideError<T>(e.toString()));
    }
  }

  /// Load All Data Function [_onLoadGuides]
  Future<void> _onLoadGuides(
    LoadGuides<T> event,
    Emitter<GuideState<T>> emit,
  ) async {
    emit(LoadingGuides<T>());

    try {
      _subscription = _guideRepository.getAllCacheData().listen(
        (snapshot) async {
          final data = _toList(snapshot);

          // Update internal state in the BLoC to reflect data loaded
          emit(GuidesLoaded<T>(data));

          // Trigger an event to handle the loaded data
          // add(_GuideLoadedEvent<T>(data));

          // Optionally, emit another state or handle other logic
          // emit(GuideAddedState<T>()); // For example, notify that data is added
        },
        onError: (e) {
          add(_GuideError('Error loading data: $e'));
        },
      );

      // Await for the subscription to be done (optional)
      await _subscription.asFuture();
    } catch (e) {
      emit(GuideError<T>('Error loading data: $e'));
    } finally {
      // Ensure to cancel the subscription when it's no longer needed
      // This could be in the dispose() method of a widget or BLoC
      _subscription.cancel();
    }
  }

  Future<void> _onLoadGuideById(
    LoadGuideById<T> event,
    Emitter<GuideState<T>> emit,
  ) async {
    emit(LoadingGuides<T>());
    try {
      final localData = await _guideRepository.getDataById(
        event.documentId,
        field: event.field,
      );

      if (localData != null) {
        final data = fromFirestore(localData.data, localData.id);
        add(_GuideLoaded<T>(data));
      } else {
        emit(GuideError<T>('Document not found'));
      }
    } catch (e) {
      emit(GuideError<T>(e.toString()));
    }
  }

  Future<void> _onAddGuide(
    AddGuide<T> event,
    Emitter<GuideState<T>> emit,
  ) async {
    try {
      // Add data to Firestore and update local storage
      await _guideRepository.createData(toCache(event.data));

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(GuideAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(GuideError<T>(e.toString()));
    }
  }

  Future<void> _onAddMultiGuide(
    AddGuide<List<T>> event,
    Emitter<GuideState<T>> emit,
  ) async {
    try {
      for (var item in event.data) {
        // Add data to Firestore
        _guideRepository.createData(toCache(item));
      }

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(GuideAdded<T>(message: 'Data added successfully'));
    } catch (e) {
      emit(GuideError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onUpdateGuide(
    UpdateGuide event,
    Emitter<GuideState<T>> emit,
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
      emit(GuideUpdated<T>(message: 'data updated successfully'));
    } catch (e) {
      emit(GuideError<T>(e.toString()));
    }
  }

  Future<void> _onDeleteGuide(
    DeleteGuide event,
    Emitter<GuideState<T>> emit,
  ) async {
    try {
      // Delete data from Firestore and update local storage
      await _guideRepository.deleteData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(LoadGuides<T>());

      // Update State: Notify that data deleted
      emit(GuideDeleted<T>(message: 'data deleted successfully'));
    } catch (e) {
      emit(GuideError<T>(e.toString()));
    }
  }

  /*void _onGuideLoaded(_GuidesLoaded<T> event, Emitter<GuideState<T>> emit) {
    emit(GuidesLoaded<T>(event.data));
  }*/

  void _onGuideLoaded(_GuideLoaded<T> event, Emitter<GuideState<T>> emit) {
    emit(GuideLoaded<T>(event.data));
  }

  void _onGuideLoadError(_GuideError event, Emitter<GuideState<T>> emit) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(error: event.error, fileName: 'user_guide_bloc');
    emit(GuideError<T>(event.error));
  }

  List<T> _toList(List<CacheData> cacheData) {
    return cacheData
        .map((cache) => fromFirestore(cache.data, cache.id))
        .toList();
  }

  @override
  Future<void> close() {
    _guideRepository.cancelDataSubscription();
    return super.close();
  }
}
