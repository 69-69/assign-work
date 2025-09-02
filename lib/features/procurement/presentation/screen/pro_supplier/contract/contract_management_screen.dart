import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:flutter/material.dart';

class ContractManagementScreen extends StatelessWidget {
  const ContractManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: contractManagementScreenTitle.toUpperAll,
      body: Center(child: Text("Contract Management Screen")),
    );
  }
}
