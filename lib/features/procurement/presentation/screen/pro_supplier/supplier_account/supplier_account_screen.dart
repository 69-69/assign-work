import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_vendor/suppliers_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_supplier/supplier_account/list/list_suppliers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SupplierAccountScreen extends StatelessWidget {
  const SupplierAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: supplierAccountScreenTitle.toUpperAll,
      body: BlocProvider<SupplierBloc>(
        create: (context) =>
            SupplierBloc(firestore: FirebaseFirestore.instance)
              ..add(GetProcurements<Supplier>()),
        child: ListSuppliers(),
      ),
    );
  }
}
