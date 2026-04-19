import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_pick_shipping_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/picking_shipments_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PickingShipmentScreen extends StatelessWidget {
  const PickingShipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PickingShipmentsBloc>(
      create: (context) =>
      PickingShipmentsBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<PickList>()),
      child: CustomScaffold(
        title: whPickShipmentScreenTitle.toUpperAll,
        body: Center(child: Text('Picking Shipment Screen')),
      ),
    );
  }
}
