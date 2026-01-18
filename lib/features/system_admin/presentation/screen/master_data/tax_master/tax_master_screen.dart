import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/taxes/tax_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/tax_master/list/list_taxes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageTaxScreen extends StatelessWidget {
  const ManageTaxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TaxBloc>(
      create: (context) =>
          TaxBloc(firestore: FirebaseFirestore.instance)..add(GetSetups<Tax>()),
      child: CustomScaffold(
        title: taxMasterScreenTitle.toUpperAll,
        body: const ListTaxes(),
      ),
    );
  }
}
