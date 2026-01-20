import 'dart:async';

import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/util/extensions/collection_type.dart';
import 'package:assign_erp/features/agent/domain/repositories/agent_repository.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'agent_event.dart';
part 'agent_state.dart';

/// AgentBloc
///
class AgentBloc<T> extends Bloc<AgentEvent, AgentState<T>> {
  final AgentRepository _agentRepository;

  /// toCache/toJson Function [toCache]
  final Map<String, dynamic> Function(T data) toCache;

  /// toJson/toMap Function [toFirestore]
  final Map<String, dynamic> Function(T data) toFirestore;

  /// fromJson/fromMap Function [fromFirestore]
  final T Function(Map<String, dynamic> data, String documentId) fromFirestore;

  AgentBloc({
    required FirebaseFirestore firestore,
    CollectionType? collectionType,
    required String collectionPath,
    required this.fromFirestore,
    required this.toFirestore,
    required this.toCache,
  }) : _agentRepository = AgentRepository(
         firestore: firestore,
         collectionPath: collectionPath,
         collectionType: collectionType ?? CollectionType.clients,
       ),
       super(LoadingClients<T>()) {
    _initialize();

    _agentRepository.dataStream.listen(
      (cacheData) => add(_ClientsLoaded<T>(_toList(cacheData))),
    );
  }

  Future<void> _initialize() async {
    on<RefreshClients<T>>(_onRefreshClients);
    on<LoadClients<T>>(_onLoadClients);
    on<_ClientsLoaded<T>>(_onClientsLoaded);
    on<_ClientLoaded<T>>(_onClientLoaded);
    on<_AgentError>(_onAgentError);
  }

  /*Future<void> _onRefreshClients(
    RefreshClients<T> event,
    Emitter<AgentState<T>> emit,
  ) async {
    emit(LoadingClients<T>());
    try {
      final completer = Completer<void>();
      // Trigger data refresh in the DataRepository
      await _agentRepository.refreshCacheData(completer: completer);
      // Wait for Firestore stream to emit and complete the cache update
      await completer.future;
      // Fetch the updated data from the repository
      final updatedData = await _agentRepository.getAllData().first;
      final data = _toList(updatedData);
      prettyPrint('Updated Data: $data', data.length);

      // Emit the loaded state with the refreshed data
      emit(ClientsLoaded<T>(data));
    } catch (e) {
      // Emit an error state in case of failure
      emit(AgentError<T>(e.toString()));
    }
  }*/

  Future<void> _onRefreshClients(
    RefreshClients<T> event,
    Emitter<AgentState<T>> emit,
  ) async {
    emit(LoadingClients<T>());

    try {
      final workspaces = await _agentRepository.getAgentClientWorkspaces();

      final data = _toList(workspaces);

      // Emit the loaded state with the refreshed data
      emit(ClientsLoaded<T>(data));
    } catch (e) {
      add(_AgentError('Error refreshing clients: $e'));
      // Emit an error state in case of failure
      emit(AgentError<T>(e.toString()));
    }
  }

  /// Load All Data Function [_onLoadClients]
  Future<void> _onLoadClients(
    LoadClients<T> event,
    Emitter<AgentState<T>> emit,
  ) async {
    emit(LoadingClients<T>());

    try {
      final workspaces = await _agentRepository.getAgentClientWorkspaces();

      final data = _toList(workspaces);

      emit(ClientsLoaded<T>(data));
    } catch (e) {
      add(_AgentError('Error loading clients: $e'));
      emit(AgentError<T>('Error loading data: $e'));
    }
  }

  void _onClientsLoaded(_ClientsLoaded<T> event, Emitter<AgentState<T>> emit) {
    emit(ClientsLoaded<T>(event.data));
  }

  void _onClientLoaded(_ClientLoaded<T> event, Emitter<AgentState<T>> emit) {
    emit(ClientLoaded<T>(event.data));
  }

  void _onAgentError(_AgentError event, Emitter<AgentState<T>> emit) {
    final errorLogCache = ErrorLogCache();
    errorLogCache.setError(error: event.error, fileName: 'Agent_bloc');
    emit(AgentError<T>(event.error));
  }

  List<T> _toList(List<CacheData> cacheData) {
    return cacheData
        .map((cache) => fromFirestore(cache.data, cache.id))
        .toList();
  }

  @override
  Future<void> close() {
    _agentRepository.cancelDataSubscription();
    return super.close();
  }
}
