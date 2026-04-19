import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_inbound_receive_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/inbound_receiving_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InboundReceivingScreen extends StatelessWidget {
  const InboundReceivingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InboundReceivingBloc>(
      create: (context) =>
      InboundReceivingBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<InBoundReceive>()),
      child: CustomScaffold(
        title: whInboundReceivingScreenTitle.toUpperAll,
        body: Center(child: Text('Inbound Receiving Screen')),
      ),
    );
  }
}
