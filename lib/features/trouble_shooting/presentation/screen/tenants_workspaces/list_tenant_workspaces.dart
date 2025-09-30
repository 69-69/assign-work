import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/auth/presentation/screen/workspace/create/create_workspace_acc.dart';
import 'package:assign_erp/features/auth/presentation/screen/workspace/update/update_workspace_acc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/all_tenants/all_tenants_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/tenant_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/widget/assign_subscription_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ListTenantWorkspaces extends StatefulWidget {
  const ListTenantWorkspaces({super.key});

  @override
  State<ListTenantWorkspaces> createState() => _ListTenantWorkspacesState();
}

class _ListTenantWorkspacesState extends State<ListTenantWorkspaces> {
  bool? _isChecked;
  Workspace? _selectedWorkspace;

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  BlocBuilder<AllTenantsBloc, TenantState<Workspace>> _buildBody() {
    return BlocBuilder<AllTenantsBloc, TenantState<Workspace>>(
      buildWhen: (oldState, newState) => oldState != newState,
      builder: (context, state) {
        return switch (state) {
          LoadingTenants<Workspace>() => context.loader,
          TenantsLoaded<Workspace>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Setup New Workspace',
                    onPressed: () => context.openCreateWorkspacePopUp(),
                  )
                : _buildCard(context, results),
          TenantError<AllTenantsBloc>(error: var error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  ({
    List<Workspace> expired,
    List<Workspace> unExpired,
    List<Workspace> unKnown,
  })
  _filterExpiry(List<Workspace> workspaces) {
    final unExpired = Workspace.filterStatus(workspaces);
    final expired = Workspace.filterStatus(workspaces, expired: true);
    final unKnown = Workspace.filterUnknown(workspaces);

    return (expired: expired, unExpired: unExpired, unKnown: unKnown);
  }

  Widget _buildCard(BuildContext context, List<Workspace> workspaces) {
    final data = _filterExpiry(workspaces);
    final expiredWorkspaces = data.expired.map((w) => w.itemAsList()).toList();
    // These are FAKE/UNKNOWN Workspaces
    final unKnownWorkspaces = data.unKnown.map((w) => w.itemAsList()).toList();

    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: Workspace.dataTableHeader,
      anyWidget: _buildAnyWidget(data.unExpired),
      rows: data.unExpired.map((w) => w.itemAsList()).toList(),
      childrenRow: [...unKnownWorkspaces, ...expiredWorkspaces],
      onEditTap: (row) async => await _onEditTap(workspaces, row.first),
      onDeleteTap: (row) async =>
          await _onDeleteTap(row.first, workspaceRole: row[1]),
      onChecked: (bool? isChecked, List<String> row) =>
          _onChecked(workspaces, row.first, isChecked),
      optButtonIcon: Icons.support_agent,
      optButtonLabel: 'Tenant Chat',
      onOptButtonTap: (row) => context.goNamed(
        RouteNames.tenantChat,
        pathParameters: {'clientWorkspaceId': row.first},
      ),
    );
  }

  _buildAnyWidget(List<Workspace> tenants) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      runAlignment: WrapAlignment.spaceBetween,
      children: [
        context.actionInfoButton(
          'Refresh Workspaces',
          label: 'Workspaces',
          count: tenants.length,
          onPressed: () {
            // Refresh Workspace Data
            context.read<AllTenantsBloc>().add(RefreshTenants<Workspace>());
          },
        ),

        if (_isChecked == true) ...{
          context.elevatedButton(
            'Assign Subscription',
            tooltip: 'Assign Workspace Subscription & License',
            onPressed: () async {
              await context.assignSubscriptionToWorkspaceDialog(
                workspaceId: _selectedWorkspace!.id,
                workspaceName: _selectedWorkspace?.name,
                initialMaxDevices: _selectedWorkspace?.maxAllowedDevices,
              );
            },
            bgColor: kGrayBlueColor,
            txtColor: kWhiteColor,
          ),
        },
      ],
    );
  }

  Future<void> _onEditTap(List<Workspace> workspaces, String id) async {
    final workspace = _findWorkspace(workspaces, id);

    if (workspace != null) {
      await context.openUpdateWorkspacePopUp(workspace: workspace);
    }
  }

  Workspace? _findWorkspace(List<Workspace> workspaces, String id) =>
      Workspace.filterById(workspaces, id);

  // Handle onChecked orders
  void _onChecked(
    List<Workspace> workspaces,
    String id,
    bool? isChecked,
  ) async {
    final workspace = _findWorkspace(workspaces, id);

    setState(() {
      _isChecked = isChecked;

      if (_isChecked == true) {
        _selectedWorkspace = workspace;
      }
    });
  }

  Future<void> _onDeleteTap(
    String workspaceId, {
    String workspaceRole = '',
  }) async {
    if (workspaceRole.isEmpty) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      AllTenantsBloc allTenantsBloc = context.read<AllTenantsBloc>();
      // Delete Tenant Associated Data
      await allTenantsBloc.deleteTenantData(
        workspaceId,
        workspaceRole.toLowerFirst,
      );
      // Delete Tenant Workspace
      allTenantsBloc.add(DeleteTenant<String>(documentId: workspaceId));
    }
  }
}
