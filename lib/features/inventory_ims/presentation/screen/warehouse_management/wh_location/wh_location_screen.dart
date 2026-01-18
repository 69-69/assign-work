import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:flutter/material.dart';

class WhLocationScreen extends StatelessWidget {
  const WhLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: whLocationScreenTitle.toUpperAll,
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Warehouse Location Screen',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
