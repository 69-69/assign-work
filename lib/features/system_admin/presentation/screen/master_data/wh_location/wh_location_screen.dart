import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/wh_location_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/wh_location_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/wh_location/list/list_wh_locations.dart';
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
            ..add(GetSetups<WHLocation>()),
      child: CustomScaffold(
        title: whLocStorageScreenTitle.toUpperAll,
        body: ListWHLocations(),
      ),
    );
  }
}
