import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_quote/pro_request_for_quote_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
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
        body: Center(child: Text('Procurement Request For Quote')),
      ),
    );
  }
}
