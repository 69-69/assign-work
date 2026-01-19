import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_location_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/wh_location_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/list/list_wh_locations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WHLocationScreen extends StatelessWidget {
  const WHLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WHLocationBloc>(
      create: (context) =>
          WHLocationBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<WHLocation>()),
      child: CustomScaffold(
        title: whLocStorageScreenTitle.toUpperAll,
        body: ListWHLocations(),
      ),
    );
  }
}
