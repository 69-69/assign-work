import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_rfq/pro_request_for_quote_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/list/list_request_for_quotes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProRequestForQuoteScreen extends StatelessWidget {
  const ProRequestForQuoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProRequestForQuoteBloc>(
      create: (context) =>
          ProRequestForQuoteBloc(firestore: FirebaseFirestore.instance)
            ..add(GetProcurements<RequestForQuote>()),
      child: CustomScaffold(
        title: requestPriceQuoteScreenTitle.toUpperAll,
        body: _buildBody(),
      ),
    );
  }

  CustomTab _buildBody() {
    return CustomTab(
      length: 2,
      openThisTab: 0,
      tabs: [
        CustomTabModel(label: 'Request For Quote', icon: Icons.request_quote),
        CustomTabModel(label: 'Awarded RFQ', icon: Icons.card_giftcard),
      ],
      children: [ListRequestForQuotes(), ListRequestForQuotes(isAwarded: true)],
    );
  }
}
