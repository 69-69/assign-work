import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/pricing_discount_master/list/pricing/index.dart';
import 'package:flutter/material.dart';

class ListPricingScreen extends StatelessWidget {
  const ListPricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  CustomTab _buildBody() {
    return CustomTab(
      length: 2,
      // isScrollable: true,
      tabs: [
        CustomTabModel(label: 'Price Lists', icon: Icons.list_alt),
        CustomTabModel(label: 'Price entries', icon: Icons.sell_outlined),
      ],
      children: [PriceLists(), PriceEntries()],
    );
  }
}
