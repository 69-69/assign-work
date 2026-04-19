import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_movement_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/internal_movements_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InternalMovementScreen extends StatelessWidget {
  const InternalMovementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InternalMovementsBloc>(
      create: (context) =>
      InternalMovementsBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<WHMovement>()),
      child: CustomScaffold(
        title: whInternalMovementScreenTitle.toUpperAll,
        body: Center(child: Text('Internal Movement Screen')),
      ),
    );
  }
}
