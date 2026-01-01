import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
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
  bool? _isChecked;
  Subscription? _selectedSubscription;

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
    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 1,
      toolbar: _buildToolbar(context),
      toolbarAlignment: WrapAlignment.end,
      headers: Subscription.dataTableHeader,
      rows: subscriptions.map((d) => d.itemAsList).toList(),
      onEditTap: (row) async => await _onEditTap(subscriptions, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(row.first),
      onChecked: (bool? isChecked, List<String> row) =>
          _onChecked(subscriptions, isChecked, row.first),
    );
  }

  _buildToolbar(BuildContext context) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      runAlignment: WrapAlignment.end,
      children: [
        context.elevatedButton(
          'Create Subscription',
          onPressed: () async => await context.openCreateNewSubscription(),
          bgColor: kDangerColor,
          txtColor: kWhiteColor,
        ),
        if (_isChecked == true) ...{
          context.elevatedButton(
            'Assign License',
            tooltip: 'Assign new licenses to subscription',
            onPressed: () async {
              if (_selectedSubscription == null) return;

              /// Assign licenses to subscription
              await context.openUpdateSubscription(
                isAssign: true,
                subscription: _selectedSubscription!,
              );
            },
            bgColor: kGrayBlueColor,
            txtColor: kWhiteColor,
          ),
        },
      ],
    );
  }

  // Handle onChecked orders
  void _onChecked(
    List<Subscription> subscriptions,
    bool? isChecked,
    String id,
  ) async {
    final subscription = _filterSub(id: id, subscriptions);

    setState(() {
      _isChecked = isChecked;

      if (_isChecked == true) {
        _selectedSubscription = subscription;
      }
    });
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
    {
      final isConfirmed = await context.confirmUserActionDialog();
      if (mounted && isConfirmed) {
        // Delete subscription
        context.read<SubscriptionBloc>().add(
          DeleteTenant<String>(documentId: id),
        );

        // Navigator.pop(context);
      }
    }
  }
}
