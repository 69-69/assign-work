import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:flutter/material.dart';

class WarehouseProductScreen extends StatelessWidget {
  const WarehouseProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: warehouseScreenTitle.toUpperAll,
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Warehouse'),
      ),
      actions: const [],
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
