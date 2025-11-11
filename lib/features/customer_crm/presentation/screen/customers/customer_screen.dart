import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/customer_crm/data/models/customer_model.dart';
import 'package:assign_erp/features/customer_crm/presentation/bloc/create_acc/customer_acc_bloc.dart';
import 'package:assign_erp/features/customer_crm/presentation/bloc/customer_bloc.dart';
import 'package:assign_erp/features/customer_crm/presentation/screen/customers/create/create_customer.dart';
import 'package:assign_erp/features/customer_crm/presentation/screen/customers/list/list_customers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerScreen extends StatelessWidget {
  final String openTab;

  const CustomerScreen({super.key, this.openTab = '0'});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CustomerAccountBloc>(
      create: (context) =>
          CustomerAccountBloc(firestore: FirebaseFirestore.instance)
            ..add(GetCustomers<Customer>()),
      child: CustomScaffold(
        title: customersScreenTitle.toUpperAll,
        body: _buildBody(),
        actions: const [],
        floatingActionButton: context.buildFloatingBtn(
          'create customer account',
          onPressed: () => context.openAddCustomer(),
        ),
      ),
    );
  }

  CustomTab _buildBody() {
    final openThisTab = int.tryParse(openTab) ?? 0;

    return CustomTab(
      openThisTab: openThisTab,
      length: 3,
      tabs: const [
        {'label': 'Customers', 'icon': Icons.group},
        {'label': 'Activities', 'icon': Icons.account_tree},
        {'label': 'Statement of Account', 'icon': Icons.pending_actions},
      ],
      children: const [
        ListCustomers(),
        Center(child: Text('Activities')),
        Center(child: Text('Statement of Account')),
      ],
    );
  }
}
