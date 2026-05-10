import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/index.dart';
import 'package:flutter/material.dart';

class VariantsMasterScreen extends StatelessWidget {
  const VariantsMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: variantMasterScreenTitle.toUpperAll,
      body: _buildBody(context),
    );
  }

  CustomTab _buildBody(BuildContext context) {
    return CustomTab(
      length: 2,
      isVertical: true,
      isScrollable: true,
      tabs: [
        CustomTabModel(label: 'Attributes', icon: Icons.tune),
        CustomTabModel(label: 'Variants', icon: Icons.copy_all),
      ],
      children: [
        ListAttributes(),
        ListVariants(),
      ],
    );
  }
}
