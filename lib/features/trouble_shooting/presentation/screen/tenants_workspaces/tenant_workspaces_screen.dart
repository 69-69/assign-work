import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/all_tenants/all_tenants_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/tenant_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/tenants_workspaces/list_tenant_workspaces.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TenantWorkspacesScreen extends StatelessWidget {
  const TenantWorkspacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AllTenantsBloc>(
      create: (context) =>
          AllTenantsBloc(firestore: FirebaseFirestore.instance)
            ..add(LoadTenants<Workspace>()),
      child: CustomScaffold(
        title: allWorkspacesScreenTitle.toUpperAll,
        body: ListTenantWorkspaces(),
      ),
    );
  }
}
