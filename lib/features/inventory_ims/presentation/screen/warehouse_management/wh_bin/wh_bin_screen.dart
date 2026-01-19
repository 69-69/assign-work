import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_bin_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/wh_bin_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_bin/list/list_wh_bins.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WHBinScreen extends StatelessWidget {
  const WHBinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WHBinBloc>(
      create: (context) =>
          WHBinBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<WHBin>()),
      child: CustomScaffold(
        title: whBinStorageScreenTitle.toUpperAll,
        body: ListWHBins(),
      ),
    );
  }
}
