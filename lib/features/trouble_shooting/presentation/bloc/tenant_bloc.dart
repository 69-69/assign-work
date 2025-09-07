import 'dart:async';

import 'package:assign_erp/core/constants/collection_type.dart';
import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/network/data_sources/remote/repository/data_repository.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
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
    on<RefreshTenants<T>>(_onRefreshClients);
    on<LoadTenants<T>>(_onLoadTenants);
    on<LoadTenantById<T>>(_onLoadTenantById);
    on<UpdateTenant>(_onUpdateTenant);
    on<OverrideTenant>(_onOverrideTenant);
    on<RevokeAuthorizedDeviceId>(_onRevokeAuthorizedDeviceIds);
    on<AddSubscription<T>>(_onAddSubscription);
    on<DeleteTenant>(_onDeleteTenant);
    on<_TenantsLoaded<T>>(_onTenantsLoaded);
    on<_TenantLoaded<T>>(_onTenantLoaded);
    on<_TenantError<T>>(_onTenantError);
  }

  Future<void> _onRefreshClients(
    RefreshTenants<T> event,
    Emitter<TenantState> emit,
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
      emit(TenantError<T>(e.toString()));
    }
  }

  Future<void> _onAddSubscription(
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
      emit(TenantError<T>(e.toString()));
    }
  }

  /// Load All Data Function [_onLoadTenants]
  Future<void> _onLoadTenants(
    LoadTenants<T> event,
    Emitter<TenantState<T>> emit,
  ) async {
    emit(LoadingTenants<T>());

    try {
      final workspaces = await _dataRepository.getAllRemoteData();

      final data = _toList(workspaces);

      emit(TenantsLoaded<T>(data));
    } catch (e) {
      emit(TenantError<T>('Error loading data: $e'));
    }
  }

  Future<void> _onLoadTenantById(
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
      emit(TenantError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onUpdateTenant(
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
      emit(TenantUpdated<T>(message: 'data updated successfully'));
    } catch (e) {
      emit(TenantError<T>(e.toString()));
    }
  }

  /// Note:: use Generic or Map data update
  Future<void> _onOverrideTenant(
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
      emit(TenantError<T>(e.toString()));
    }
  }

  Future<void> _onDeleteTenant(
    DeleteTenant event,
    Emitter<TenantState<T>> emit,
  ) async {
    try {
      // Delete data from Firestore and update local storage
      await _dataRepository.deleteData(event.documentId);

      // Trigger LoadDataEvent to reload the data
      add(LoadTenants<T>());

      // Update State: Notify that data deleted
      emit(TenantDeleted<T>(message: 'data deleted successfully'));
    } catch (e) {
      emit(TenantError<T>(e.toString()));
    }
  }

  void _onTenantsLoaded(_TenantsLoaded<T> event, Emitter<TenantState<T>> emit) {
    emit(TenantsLoaded<T>(event.data));
  }

  void _onTenantLoaded(_TenantLoaded<T> event, Emitter<TenantState<T>> emit) {
    emit(TenantLoaded<T>(event.data));
  }

  void _onTenantError(_TenantError<T> event, Emitter<TenantState<T>> emit) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(error: event.error, fileName: 'Tenant_bloc');
    emit(TenantError<T>(event.error));
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
