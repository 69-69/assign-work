import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:flutter/material.dart';

import 'list/index.dart';

class PricingDiscountMasterScreen extends StatelessWidget {
  const PricingDiscountMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: priceMasterScreenTitle.toUpperAll,
      body: _buildBody(),
    );
  }

  CustomTab _buildBody() {
    return CustomTab(
      length: 2,
      isVertical: true,
      isScrollable: true,
      tabs: [
        CustomTabModel(label: 'Pricing', icon: Icons.price_change_outlined),
        CustomTabModel(label: 'Discounts', icon: Icons.discount_outlined),
      ],
      children: [ListPricingScreen(), ListDiscountScreen()],
    );
  }
}
