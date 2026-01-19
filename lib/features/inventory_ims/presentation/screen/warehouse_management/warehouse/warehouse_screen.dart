import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/warehouse_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/warehouse_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/warehouse/list/list_warehouses.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WarehouseScreen extends StatelessWidget {
  const WarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WarehouseBloc>(
      create: (context) =>
          WarehouseBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<Warehouse>()),
      child: CustomScaffold(
        title: warehouseScreenTitle.toUpperAll,
        body: ListWarehouses(),
      ),
    );
  }
}
