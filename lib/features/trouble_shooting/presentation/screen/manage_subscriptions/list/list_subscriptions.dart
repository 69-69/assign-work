import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/subscription_model.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/subscription/subscription_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/tenant_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/manage_subscriptions/create/create_subscription.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/manage_subscriptions/update/update_subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListSubscriptions extends StatefulWidget {
  const ListSubscriptions({super.key});

  @override
  State<ListSubscriptions> createState() => _ListSubscriptionsState();
}

class _ListSubscriptionsState extends State<ListSubscriptions> {
  List<String> _selectedIds = [];

  SubscriptionBloc get _bloc => context.read<SubscriptionBloc>();

  Subscription? _selectedSubscription(List<Subscription> subscriptions) {
    if (_selectedIds.length != 1) return null;

    return _filterSub(id: _selectedIds.first, subscriptions);
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  BlocBuilder<SubscriptionBloc, TenantState<Subscription>> _buildBody() {
    return BlocBuilder<SubscriptionBloc, TenantState<Subscription>>(
      buildWhen: (oldState, newState) => oldState != newState,
      builder: (context, state) {
        return switch (state) {
          LoadingTenants<Subscription>() => context.loader,
          TenantsLoaded<Subscription>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Subscription',
                    onPressed: () => context.openCreateNewSubscription(),
                  )
                : _buildCard(context, results),
          TenantError<SubscriptionBloc>(error: var error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext context, List<Subscription> subscriptions) {
    return DynamicDataTable2(
      omitAtIndex: 0,
      maskAtIndex: 1,
      toolbar: _buildToolbar(context, subscriptions),
      headers: Subscription.dataTableHeader,
      rows: subscriptions.map(_toTableRow).toList(),
      selectedRowKeys: _selectedIds,
      onSelectionChanged: (ids, rows) {
        setState(() => _selectedIds = ids);
      },
      onEditTap: (row) async => await _onEditTap(subscriptions, row.id),
      onDeleteTap: (row) async => await _onDeleteTap(row.id),
    );
  }

  DataTableRow _toTableRow(Subscription e) =>
      DataTableRow.fromList(e.id, e.itemAsList);

  Widget _buildToolbar(BuildContext context, List<Subscription> subscriptions) {
    final subscription = _selectedSubscription(subscriptions);
    final isOne = subscription != null;

    return ListToolbarButtons(
      secondaryIcon: Icons.edit,
      tertiaryIcon: Icons.vpn_key,
      dataLength: subscriptions.length,
      secondaryLabel: 'Edit Subscription',
      tertiaryLabel: 'Assign License',
      primaryLabel: 'New Subscription',
      refreshLabel: 'Refresh',
      tertiaryTooltip: 'Assign new licenses to subscription',
      onPrimary: () => context.openCreateNewSubscription(),
      onRefresh: () => _bloc.add(RefreshTenants<Subscription>()),
      onSecondary: isOne
          ? () async => _onEditTap(subscriptions, subscription.id)
          : null,
      onTertiary: isOne
          ? () async {
              /// Assign licenses to subscription
              await context.openUpdateSubscription(
                isAssign: true,
                subscription: subscription,
              );
            }
          : null,
    );
  }

  Future<void> _onEditTap(List<Subscription> subscriptions, String id) async {
    final subscription = _filterSub(subscriptions, id: id);

    if (subscription != null) {
      await context.openUpdateSubscription(subscription: subscription);
    }
  }

  Subscription? _filterSub(
    List<Subscription> subscriptions, {
    required String id,
  }) => Subscription.findById(subscriptions, id);

  Future<void> _onDeleteTap(String id) async {
      final isConfirmed = await context.confirmUserActionDialog();
      if (mounted && isConfirmed) {
        // Delete subscription
        _bloc.add(DeleteTenant<String>(documentId: id));
      }
  }
}
