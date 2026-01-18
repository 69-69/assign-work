import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/ref_master/index.dart';
import 'package:flutter/material.dart';

class ReferenceMasterScreen extends StatelessWidget {
  const ReferenceMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: referenceMasterScreenTitle.toUpperAll,
      body: _buildBody(context),
    );
  }

  CustomTab _buildBody(BuildContext context) {
    return CustomTab(
      length: 3,
      isVertical: true,
      isScrollable: true,
      tabs: [
        CustomTabModel(label: 'Item Category', icon: Icons.category),
        CustomTabModel(label: 'Units of Measure', icon: Icons.straighten),
        CustomTabModel(label: 'Variants & Attributes', icon: Icons.tune),
      ],
      children: [
        ListCategories(),
        Center(
          child: Text(
            'Unit of Measure',
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        Center(
          child: Text(
            'Variants: ex: [Color: red, Size: M, Material: Cotton, Model: 2023, Brand: Nike, Type: Sport, Gender: Men, Age: 20-30,]',
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
