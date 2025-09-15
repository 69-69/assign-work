import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/item_config/index.dart';
import 'package:flutter/material.dart';

class ProductConfigScreen extends StatelessWidget {
  const ProductConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  CustomTab _buildBody() {
    return const CustomTab(
      length: 2,
      indicatorWeight: 1.0,
      tabs: [
        {'label': 'Any widgets', 'icon': Icons.select_all},
        {'label': 'Item Category', 'icon': Icons.category_outlined},
      ],
      children: [Text('Any widgets can be here'), ListCategories()],
    );
  }
}
