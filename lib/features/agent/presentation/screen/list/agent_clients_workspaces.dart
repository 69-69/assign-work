import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/agent/data/models/agent_client_model.dart';
import 'package:assign_erp/features/agent/presentation/bloc/agent_bloc.dart';
import 'package:assign_erp/features/agent/presentation/bloc/client/agent_clients_bloc.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/auth/presentation/screen/workspace/create/create_workspace_acc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AgentClientsWorkspaces extends StatefulWidget {
  const AgentClientsWorkspaces({super.key});

  @override
  State<AgentClientsWorkspaces> createState() => _AgentClientsWorkspacesState();
}

class _AgentClientsWorkspacesState extends State<AgentClientsWorkspaces> {
  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  BlocBuilder<AgentClientBloc, AgentState<AgentClient>> _buildBody() {
    return BlocBuilder<AgentClientBloc, AgentState<AgentClient>>(
      buildWhen: (oldState, newState) => oldState != newState,
      builder: (context, state) {
        return switch (state) {
          LoadingClients<AgentClient>() => context.loader,
          ClientsLoaded<AgentClient>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Setup New Workspace',
                    onPressed: () => context.openCreateWorkspacePopUp(),
                  )
                : _buildCard(context, results),
          AgentError<AgentClient>(error: var error) => context.buildError(
            error,
          ),
          ClientLoaded<AgentClient>() => context.loader,
        };
      },
    );
  }

  ({List<Workspace> expired, List<Workspace> unExpired}) _filterExpiry(
    List<Workspace> workspaces,
  ) {
    final unExpired = Workspace.filterStatus(workspaces);
    final expired = Workspace.filterStatus(workspaces, expired: true);

    return (expired: expired, unExpired: unExpired);
  }

  Widget _buildCard(BuildContext context, List<AgentClient> clientWorkspaces) {
    List<Workspace> workspaces = clientWorkspaces
        .where((e) => e.clientWorkspace != null)
        .map((e) => e.clientWorkspace!)
        .toList();

    final filters = _filterExpiry(workspaces);

    return DynamicDataTable(
      omitAtIndex: 0,
      headers: Workspace.dataTableHeader,
      anyWidget: _buildAnyWidget(filters.unExpired),
      rows: filters.unExpired.map((w) => w.itemAsList()).toList(),
      childrenRow: filters.expired.map((w) => w.itemAsList()).toList(),
      optButtonIcon: Icons.support_agent,
      optButtonLabel: 'Client Chat',
      onOptButtonTap: (row) => context.goNamed(
        RouteNames.tenantChat,
        pathParameters: {'clientWorkspaceId': row.first},
      ),
    );
  }

  _buildAnyWidget(List<Workspace> tenants) {
    return context.actionInfoButton(
      'Refresh Workspaces',
      label: 'Workspaces',
      count: tenants.length,
      onPressed: () {
        // Refresh Workspace Data
        context.read<AgentClientBloc>().add(RefreshClients<AgentClient>());
      },
    );
  }
}
