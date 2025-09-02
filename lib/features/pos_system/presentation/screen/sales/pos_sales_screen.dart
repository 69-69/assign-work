import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_sale_model.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/pos_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/sales/pos_sale_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/sales/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PosSalesScreen extends StatelessWidget {
  const PosSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<POSSaleBloc>(
      create: (context) =>
          POSSaleBloc(firestore: FirebaseFirestore.instance)
            ..add(GetPOSs<POSSale>()),
      child: CustomScaffold(
        title: posSalesScreenTitle.toUpperAll,
        body: const ListPOSSales(),
        floatingActionButton: context.buildFloatingBtn(
          'Add Sales',
          onPressed: () => context.openAddPOSSales(),
        ),
      ),
    );
  }
}
