import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:flutter/material.dart';

import 'attributes/index.dart';

class ListAttributes extends StatelessWidget {
  const ListAttributes({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  CustomTab _buildBody(BuildContext context) {
    return CustomTab(
      length: 2,
      isScrollable: true,
      tabs: [
        CustomTabModel(label: 'Groups & Types', icon: Icons.copy_all),
        CustomTabModel(label: 'Values', icon: Icons.tune),
      ],
      children: [
        AttributeTypes(),
        AttributeValues(),
        /*Center(
          child: Text(
            'Variants: ex: [Color: red, Size: M, Material: Cotton]\n'
            'These are not Variants, but Product Fields: [Model: 2023, Brand: Nike, Type: Sport, Gender: Men, Age: 20-30,]',
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),*/
      ],
    );
  }
}
