import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/wh_bin_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/wh_bin_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/wh_bin/list/list_wh_bins.dart';
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
            ..add(GetSetups<WHBin>()),
      child: CustomScaffold(
        title: whBinStorageScreenTitle.toUpperAll,
        body: ListWHBins(),
      ),
    );
  }
}
