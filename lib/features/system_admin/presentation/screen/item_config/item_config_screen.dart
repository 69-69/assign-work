import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/item_config/index.dart';
import 'package:flutter/material.dart';

class ProductConfigScreen extends StatelessWidget {
  const ProductConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  CustomTab _buildBody(BuildContext context) {
    return CustomTab(
      length: 2,
      tabs: [
        {'label': 'Item Category', 'icon': Icons.category_outlined},
        {'label': 'Any Widget here', 'icon': Icons.widgets},
      ],
      children: [
        ListCategories(),
        Center(
          child: Text(
            'Any Widget Can be Used',
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
