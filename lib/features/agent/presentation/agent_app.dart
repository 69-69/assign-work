import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/agent/data/models/agent_client_model.dart';
import 'package:assign_erp/features/agent/presentation/bloc/agent_bloc.dart';
import 'package:assign_erp/features/agent/presentation/bloc/client/agent_clients_bloc.dart';
import 'package:assign_erp/features/agent/presentation/screen/list/agent_clients_workspaces.dart';
import 'package:assign_erp/features/auth/presentation/screen/workspace/create/create_workspace_acc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AgentApp extends StatelessWidget {
  const AgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AgentClientBloc>(
      create: (context) =>
          AgentClientBloc(firestore: FirebaseFirestore.instance)
            ..add(LoadClients<AgentClient>()),
      child: CustomScaffold(
        title: clienteleScreenTitle.toUpperAll,
        body: AgentClientsWorkspaces(),
        floatingActionButton: context.buildFloatingBtn(
          'setup new workspace',
          icon: Icons.workspaces_outline,
          onPressed: () => context.openCreateWorkspacePopUp(),
        ),
      ),
    );
  }
}
