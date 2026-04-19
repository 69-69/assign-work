import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/warehouse_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/warehouse_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/warehouse/list/list_warehouses.dart';
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
            ..add(GetSetups<Warehouse>()),
      child: CustomScaffold(
        title: warehouseScreenTitle.toUpperAll,
        body: ListWarehouses(),
      ),
    );
  }
}
