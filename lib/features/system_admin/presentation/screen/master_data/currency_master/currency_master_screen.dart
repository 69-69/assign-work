import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/currency_master/list/list_currency_master.dart';
import 'package:flutter/material.dart';

class CurrencyMasterScreen extends StatefulWidget {
  const CurrencyMasterScreen({super.key});

  @override
  State<CurrencyMasterScreen> createState() => _CurrencyMasterScreenState();
}

class _CurrencyMasterScreenState extends State<CurrencyMasterScreen> {

  @override
  Widget build(BuildContext context) {

    return CustomScaffold(
      title: currencyMasterScreenTitle.toUpperAll,
      body: ListCurrencyMaster(),
    );
  }

}
