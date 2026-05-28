import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
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
  List<String> _selectedIds = [];
  AllTenantsBloc get _bloc => context.read<AllTenantsBloc>();

  Workspace? _selectedWorkspace(List<Workspace> workspaces) {
    if (_selectedIds.length != 1) return null;

    return _findWorkspace(workspaces, _selectedIds.first);
  }

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
                    'New Workspace',
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
  })_filterExpiry(List<Workspace> workspaces) {
    final unExpired = Workspace.filterStatus(workspaces);
    final expired = Workspace.filterStatus(workspaces, expired: true);
    final unKnown = Workspace.filterUnknown(workspaces);

    return (expired: expired, unExpired: unExpired, unKnown: unKnown);
  }

  Widget _buildCard(BuildContext context, List<Workspace> workspaces) {
    final data = _filterExpiry(workspaces);
    final expiredWorkspaces = data.expired.map(_toTableRow).toList();

    /// These are FAKE/UNKNOWN Tenant Workspaces
    final unKnownWorkspaces = data.unKnown.map(_toTableRow).toList();

    return DynamicDataTable2(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: Workspace.dataTableHeader,
      toolbar: _buildToolbar(data.unExpired),
      rows: data.unExpired.map(_toTableRow).toList(),
      childrenRow: [...unKnownWorkspaces, ...expiredWorkspaces],
      selectedRowKeys: _selectedIds,
      onSelectionChanged: (ids, rows) {
        setState(() => _selectedIds = ids);
      },
      onEditTap: (row) async => await _onEditTap(workspaces, row.id),
      onDeleteTap: (row) async =>
          await _onDeleteTap(row.id, workspaceRole: row.values[1]),
      optButtonIcon: Icons.support_agent,
      optButtonLabel: 'Chat',
      onOptButtonTap: (row) => context.goNamed(
        RouteNames.tenantChat,
        pathParameters: {'clientWorkspaceId': row.id},
      ),
    );
  }

  DataTableRow _toTableRow(Workspace e) =>
      DataTableRow.fromList(e.id, e.itemAsList());

  Widget _buildToolbar(List<Workspace> tenants) {
    final workspace = _selectedWorkspace(tenants);
    final isOne = workspace != null;

    return ListToolbarButtons(
      secondaryIcon: Icons.edit,
      dataLength: tenants.length,
      tertiaryIcon: Icons.vpn_key,
      secondaryLabel: 'Edit Access',
      refreshLabel: 'Refresh',
      primaryLabel: 'New Workspace',
      tertiaryLabel: 'Assign Subscription',
      tertiaryTooltip: 'Assign Workspace Subscription & License',
      onPrimary: () => context.openCreateWorkspacePopUp(),
      onRefresh: () => _bloc.add(RefreshTenants<Workspace>()),
      onSecondary: isOne
          ? () async => _onEditTap(tenants, workspace.id)
          : null,
      onTertiary: isOne
          ? () async {
              await context.assignSubscriptionToWorkspaceDialog(
                workspaceId: workspace.id,
                workspaceName: workspace.name,
                initialSub: workspace.subscriptionId,
                initialMaxDevices: workspace.maxAllowedDevices,
              );
            }
          : null,
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

  Future<void> _onDeleteTap(
    String workspaceId, {
    String workspaceRole = '',
  }) async {
    if (workspaceRole.isEmpty) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      // Delete Tenant Associated Data
      await _bloc.deleteTenantData(workspaceId, workspaceRole.toLowerFirst);
      // Delete Tenant Workspace
      _bloc.add(DeleteTenant<String>(documentId: workspaceId));
    }
  }
}
