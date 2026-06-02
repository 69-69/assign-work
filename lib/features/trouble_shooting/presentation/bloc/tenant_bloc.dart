import 'dart:async';

import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/network/data_sources/remote/repository/data_repository.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/collection_type.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'tenant_event.dart';
part 'tenant_state.dart';

/// TroubleShootBloc
///
class TenantBloc<T> extends Bloc<TenantEvent, TenantState<T>> {
  final DataRepository _dataRepository;

  /// toCache/toJson Function [toCache]
  final Map<String, dynamic> Function(T data) toCache;

  /// toJson/toMap Function [toFirestore]
  final Map<String, dynamic> Function(T data) toFirestore;

  /// fromJson/fromMap Function [fromFirestore]
  final T Function(Map<String, dynamic> data, String documentId) fromFirestore;

  TenantBloc({
    required FirebaseFirestore firestore,
    CollectionType? collectionType,
    required String collectionPath,
    required this.fromFirestore,
    required this.toFirestore,
    required this.toCache,
  }) : _dataRepository = DataRepository(
         firestore: firestore,
         collectionPath: collectionPath,
         collectionType: collectionType,
       ),
       super(LoadingTenants<T>()) {
    _initialize();

    _dataRepository.dataStream.listen(
      (cacheData) => add(_TenantsLoaded<T>(_toList(cacheData))),
    );
  }

  Future<void> _initialize() async {
    on<RefreshTenants<T>>(_onRefresh);
    on<LoadTenants<T>>(_onLoad);
    on<LoadTenantById<T>>(_onLoadById);
    on<UpdateTenant>(_onUpdate);
    on<OverrideTenant>(_onOverride);
    on<RevokeAuthorizedDeviceId>(_onRevokeAuthorizedDeviceIds);
    on<DeleteTenant<String>>(_onDelete);
    on<DeleteTenant<List<String>>>(_onDeleteMany);
    on<_TenantsLoaded<T>>(_onManyLoaded);
    on<_TenantLoaded<T>>(_onLoaded);
    on<_TenantError<T>>(_onError);
    on<AddSubscription<T>>(_onAddSub);
    on<SearchSubscriptions<T>>(_onSearchSub);
    on<_SubscriptionError<T>>(_onSubError);
  }

  Future<void> _onRefresh(
    RefreshTenants<T> event,
    Emitter<TenantState<T>> emit,
  ) async {
    emit(LoadingTenants<T>());
    try {
      await _dataRepository.refreshCacheData();
      // Fetch the updated data from the repository
      final updatedData = await _dataRepository.getAllCacheData().first;
      final data = _toList(updatedData);
      prettyPrint('Updated Data: $data', data.length);

      // Emit the loaded state with the refreshed data
      emit(TenantsLoaded<T>(data));
    } catch (e) {
      // Emit an error state in case of failure
      add(_TenantError('Error refreshing tenants: $e'));
      emit(TenantError<T>(e.toString()));
    }
  }

  Future<void> _onSearchSub(
    SearchSubscriptions<T> event,
    Emitter<TenantState<T>> emit,
  ) async {
    emit(LoadingSubcriptions<T>());
    try {
      List<CacheData> data = await _dataRepository.searchData(
        event.query,
        primaryField: event.primaryField ?? '',
        optionalField: event.optionalField,
        secondaryField: event.secondaryField,
        tertiaryField: event.tertiaryField,
      );

      var localData = _toList(data);
      emit(SubscriptionsLoaded<T>(localData));
      // emit(DataLoadedState<T>(data.cast<T>()));
    } catch (e) {
      add(_SubscriptionError('Error searching subscriptions: $e'));
      emit(SubscriptionError<T>('Error searching data: $e'));
    }
  }

  Future<void> _onAddSub(
    AddSubscription<T> event,
    Emitter<TenantState<T>> emit,
  ) async {
    try {
      // Add data to Firestore and update local storage
      await _dataRepository.createData(toCache(event.data));

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data added
      emit(SubscriptionAdded<T>(message: 'Subscription added successfully'));
    } catch (e) {
      add(_SubscriptionError('Error saving subscription: $e'));
      emit(SubscriptionError<T>(e.toString()));
    }
  }

  /// Load All Data Function [_onLoad]
  Future<void> _onLoad(
    LoadTenants<T> event,
    Emitter<TenantState<T>> emit,
  ) async {
    emit(LoadingTenants<T>());

    try {
      final workspaces = await _dataRepository.getAllRemoteData();

      final data = _toList(workspaces);

      emit(TenantsLoaded<T>(data));
    } catch (e) {
      add(_TenantError('Error loading tenants: $e'));
      emit(TenantError<T>('Error loading data: $e'));
    }
  }

  Future<void> _onLoadById(
    LoadTenantById<T> event,
    Emitter<TenantState<T>> emit,
  ) async {
    emit(LoadingTenants<T>());
    try {
      final res = await _dataRepository.getDataById(event.documentId);

      if (res != null) {
        final data = fromFirestore(res.data, res.id);
        emit(TenantLoaded<T>(data));
      } else {
        emit(TenantError<T>('Document not found'));
      }
    } catch (e) {
      add(_TenantError('Error loading tenant by id: $e'));
      emit(TenantError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onUpdate(
    UpdateTenant event,
    Emitter<TenantState<T>> emit,
  ) async {
    try {
      final isPartialUpdate = event.mapData?.isNotEmpty ?? false;
      final data = isPartialUpdate
          ? {'data': event.mapData}
          : toCache(event.data as T);

      await _dataRepository.updateData(
        event.documentId,
        data: data,
        isPartial: isPartialUpdate, // true if not a full model update
      );

      // Trigger LoadDataEvent to reload the data
      // add(LoadDataEvent<T>());

      // Update State: Notify that data updated
      emit(TenantUpdated<T>(message: 'Changes successfully saved'));
    } catch (e) {
      add(_TenantError('Error updating tenant: $e'));
      emit(TenantError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onOverride(
    OverrideTenant event,
    Emitter<TenantState<T>> emit,
  ) async {
    try {
      var mapData = event.mapData;
      final data = mapData != null && mapData.isNotEmpty
          ? {'data': mapData}
          : toCache(event.data as T);

      await _dataRepository.overrideData(event.documentId, data: data);

      // Update State: Notify that data updated
      emit(TenantOverridden<T>(message: 'data successfully overridden'));
    } catch (e) {
      add(_TenantError('Error overriding tenant: $e'));
      emit(TenantError<T>(e.toString()));
    }
  }

  /// Dispatches an event to reset workspace authorized device IDs for the clients workspace.
  ///
  /// If a specific [did] (device ID) is provided, it will be removed from the
  /// list of authorized devices. If [did] is null, the event will trigger
  /// removal of all authorized device IDs.
  Future<void> _onRevokeAuthorizedDeviceIds(
    RevokeAuthorizedDeviceId event,
    Emitter<TenantState<T>> emit,
  ) async {
    emit(TenantDeleting());
    try {
      final did = event.data != null
          ? FieldValue.arrayRemove([event.data])
          : [];

      await _dataRepository.updateData(
        event.documentId,
        isPartial: true,
        data: {'authorizedDeviceIds': did},
      );

      // Trigger LoadDataEvent to reload the data
      add(LoadTenants<T>());

      // Update State: Notify that ids Remove
      emit(
        TenantDeleted<T>(message: 'Authorized Device Id remove successfully'),
      );
    } catch (e) {
      add(_TenantError('Error revoking tenant devices: $e'));
      emit(TenantError<T>(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteTenant<String> event,
    Emitter<TenantState<T>> emit,
  ) async {
    emit(TenantDeleting());
    try {
      // Delete data from Firestore and update local storage
      await _dataRepository.deleteData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(LoadTenants<T>());

      // Update State: Notify that data deleted
      emit(TenantDeleted<T>(message: 'Data deleted successfully'));
    } catch (e) {
      add(_TenantError('Error deleting single tenant: $e'));
      emit(TenantError<T>(e.toString()));
    }
  }

  Future<void> _onDeleteMany(
    DeleteTenant<List<String>> event,
    Emitter<TenantState<T>> emit,
  ) async {
    emit(TenantDeleting());
    try {
      // Delete data from Firestore and update local storage
      await _dataRepository.deleteManyData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(LoadTenants<T>());

      // Update State: Notify that data deleted
      emit(TenantDeleted<T>(message: 'Data deleted successfully'));
    } catch (e) {
      add(_TenantError('Error deleting multiple tenant: $e'));
      emit(TenantError<T>(e.toString()));
    }
  }

  void _onManyLoaded(_TenantsLoaded<T> event, Emitter<TenantState<T>> emit) {
    emit(TenantsLoaded<T>(event.data));
  }

  void _onLoaded(_TenantLoaded<T> event, Emitter<TenantState<T>> emit) {
    emit(TenantLoaded<T>(event.data));
  }

  /// Handles Tenant Error failures.
  ///
  /// This method saves/logs the encountered error to the `centralized error cache`
  /// for diagnostics and emits an [TenantError] state to notify listeners
  /// of the failure.
  void _onError(_TenantError<T> event, Emitter<TenantState<T>> emit) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(error: event.error, fileName: 'tenant_bloc');
    emit(TenantError<T>(event.error));
  }

  /// Handles Subscription Error failures.
  ///
  /// This method saves/logs the encountered error to the `centralized error cache`
  /// for diagnostics and emits an [SubscriptionError] state to notify listeners
  /// of the failure.
  void _onSubError(
    _SubscriptionError<T> event,
    Emitter<TenantState<T>> emit,
  ) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(error: event.error, fileName: 'subscription_bloc');
    emit(SubscriptionError<T>(event.error));
  }

  List<T> _toList(List<CacheData> cacheData) {
    return cacheData
        .map((cache) => fromFirestore(cache.data, cache.id))
        .toList();
  }

  @override
  Future<void> close() {
    _dataRepository.cancelDataSubscription();
    return super.close();
  }
}
