import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:flutter/material.dart';

class GoodsReceiptScreen extends StatelessWidget {
  const GoodsReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: goodsReceiptScreenTitle.toUpperAll,
      body: Center(
        child: Text(
          'Goods Receipt Screen',
          style: context.textTheme.titleLarge,
        ),
      ),
    );
  }
}
