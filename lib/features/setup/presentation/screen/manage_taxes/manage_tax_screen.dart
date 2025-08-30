import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/setup/data/models/tax_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/taxes/tax_bloc.dart';
import 'package:assign_erp/features/setup/presentation/screen/manage_taxes/list/list_taxes.dart';
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
        noAppBar: true,
        body: const ListTaxes(),
        bottomNavigationBar: const SizedBox.shrink(),
      ),
    );
  }
}
