import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:assign_erp/features/sales_distribution/data/model/sales_quotation_model.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_distribution_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_quotation/sales_quotation_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/screen/sales_quotation/list/list_sales_quotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesQuotationScreen extends StatelessWidget {
  const SalesQuotationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SalesQuotationBloc>(
      create: (context) =>
          SalesQuotationBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSalesDistributions<SalesQuotation>()),
      child: CustomScaffold(
        title: salesQuoteScreenTitle.toUpperAll,
        body: _buildBody(),
      ),
    );
  }

  CustomTab _buildBody() {
    return CustomTab(
      length: 2,
      openThisTab: 0,
      tabs: [
        CustomTabModel(label: 'Sales Quotations', icon: Icons.list_alt),
        CustomTabModel(label: 'Approved SOs', icon: Icons.approval),
      ],
      children: [ListSalesQuotations(), ListSalesQuotations(isApproved: true)],
    );
  }
}
