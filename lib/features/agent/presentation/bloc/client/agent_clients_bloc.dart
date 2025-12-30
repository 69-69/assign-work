import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/agent/data/models/agent_client_model.dart';
import 'package:assign_erp/features/agent/presentation/bloc/agent_bloc.dart';

/// Get Agent's Clients(Subscribers) Workspaces Bloc [AgentClientBloc]
class AgentClientBloc extends AgentBloc<AgentClient> {
  AgentClientBloc({required super.firestore})
    : super(
        collectionPath: agentClientsDBColPath,
        fromFirestore: (data, id) => AgentClient.fromMap(data, id: id),
        toFirestore: (client) => client.toMap(),
        toCache: (client) => client.toCache(),
      );
}
