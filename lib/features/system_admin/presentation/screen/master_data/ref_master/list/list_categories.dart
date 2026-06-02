import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/category_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/category_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'category/all_categories.dart';

class ListCategories extends StatelessWidget {
  const ListCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CategoryBloc>(
      create: (context) =>
          CategoryBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<Category>()),
      child: _buildBody(),
    );
  }

  CustomTab _buildBody() {
    return CustomTab(
      length: 2,
      // isScrollable: true,
      tabs: [
        CustomTabModel(label: 'Material Category', icon: Icons.list_alt),
        CustomTabModel(label: 'Service Category', icon: Icons.sell_outlined),
      ],
      children: [AllCategories(), AllCategories(isService: true)],
    );
  }
}
