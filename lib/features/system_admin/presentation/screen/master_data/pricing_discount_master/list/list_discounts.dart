import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:flutter/material.dart';

import 'discount/index.dart';

class ListDiscountScreen extends StatelessWidget {
  const ListDiscountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  CustomTab _buildBody() {
    return CustomTab(
      length: 2,
      // isScrollable: true,
      tabs: [
        CustomTabModel(label: 'Discount Group', icon: Icons.discount),
        CustomTabModel(label: 'Discount Rules', icon: Icons.rule),
      ],
      children: [ListDiscountGroups(), ListDiscountRules()],
    );
  }
}
