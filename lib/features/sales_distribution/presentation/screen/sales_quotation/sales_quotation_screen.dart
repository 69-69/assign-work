import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:flutter/material.dart';

class SalesQuotationScreen extends StatelessWidget {
  const SalesQuotationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      isGradientBg: true,
      title: 'Sales Quotation Screen',
      body: Center(child: Text('Sales Quotation Screen')),
    );
  }
}
