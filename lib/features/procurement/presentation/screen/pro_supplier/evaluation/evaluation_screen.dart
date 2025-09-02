import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:flutter/material.dart';

class SupplierEvaluationScreen extends StatelessWidget {
  const SupplierEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: supplierEvaluationScreenTitle.toUpperAll,
      body: Center(child: Text("Supplier Evaluation Screen")),
    );
  }
}
