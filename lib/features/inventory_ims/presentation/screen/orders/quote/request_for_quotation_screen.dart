import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/request_for_quote_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/orders/request_price_quotation_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/quote/add/add_request_for_quotation.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/quote/list/list_quotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestForQuotationScreen extends StatelessWidget {
  const RequestForQuotationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RequestForQuoteBloc>(
      create: (context) =>
          RequestForQuoteBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<RequestForQuote>()),
      child: CustomScaffold(
        title: requestPriceQuoteScreenTitle.toUpperAll,
        body: _buildBody(),
        floatingActionButton: context.buildFloatingBtn(
          'Request For Quotes',
          onPressed: () => context.openAddRequestForQuotation(),
        ),
      ),
    );
  }

  CustomTab _buildBody() {
    return CustomTab(
      length: 2,
      openThisTab: 0,
      tabs: [
        {'label': 'Request For Quote', 'icon': Icons.miscellaneous_services},
        {'label': 'Awarded RFQ', 'icon': Icons.card_giftcard},
      ],
      children: [ListQuotations(), ListQuotations(isAward: true)],
    );
  }
}
