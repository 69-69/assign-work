import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/subscription_model.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/subscription/subscription_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/tenant_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/manage_subscriptions/list/list_subscriptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageSubscriptionScreen extends StatelessWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionBloc>(
      create: (context) =>
          SubscriptionBloc(firestore: FirebaseFirestore.instance)
            ..add(LoadTenants<Subscription>()),
      child: CustomScaffold(
        title: subscriptionScreenTitle.toUpperAll,
        body: ListSubscriptions(),
      ),
    );
  }
}
