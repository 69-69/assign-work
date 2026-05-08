import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/price_list_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/price_list_master_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/price_list_master/list/list_price_master.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PriceListMasterScreen extends StatelessWidget {
  const PriceListMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PriceMasterBloc>(
      create: (context) =>
          PriceMasterBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<PriceMaster>()),
      child: CustomScaffold(
        title: priceMasterScreenTitle.toUpperAll,
        body: ListPriceMaster(),
      ),
    );
  }
}
