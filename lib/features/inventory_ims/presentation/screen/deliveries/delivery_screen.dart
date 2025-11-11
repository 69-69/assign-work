import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/delivery_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/delivery/delivery_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/deliveries/create/create_delivery.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/deliveries/list/list_delivery.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeliveryScreen extends StatelessWidget {
  final String openTab;

  const DeliveryScreen({super.key, this.openTab = '0'});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DeliveryBloc>(
      create: (context) =>
          DeliveryBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<Delivery>()),
      child: CustomScaffold(
        title: deliveryScreenTitle.toUpperAll,
        body: _buildBody(),
        actions: const [],
        floatingActionButton: context.buildFloatingBtn(
          'add delivery',
          onPressed: () => context.openAddDelivery(),
        ),
      ),
    );
  }

  CustomTab _buildBody() {
    final openThisTab = int.tryParse(openTab) ?? 0;

    return CustomTab(
      openThisTab: openThisTab,
      length: 4,
      tabs: const [
        {'label': 'Deliveries', 'icon': Icons.delivery_dining},
        {'label': 'Pending', 'icon': Icons.pending},
        {'label': 'Shipped or Dispatched', 'icon': Icons.local_shipping},
        {'label': 'Delivered', 'icon': Icons.checklist},
      ],
      children: const [
        ListDeliveries(),
        Center(child: Text('Pending')),
        Center(child: Text('Shipped or Dispatched')),
        Center(child: Text('Delivered')),
      ],
    );
  }
}
