import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:flutter/material.dart';

class ProWorkflowApprovalsScreen extends StatelessWidget {
  const ProWorkflowApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: proWorkflowApprovalsScreenTitle.toUpperAll,
      body: CustomTab(
        length: 3,
        openThisTab: 0,
        hideIcon: false,
        tabs: [
          CustomTabModel(
            label: 'Purchase Requisition',
            icon: Icons.edit_document,
          ),
          CustomTabModel(
            label: 'Request For Quote',
            icon: Icons.request_page_outlined,
          ),
          CustomTabModel(label: 'Purchase Order', icon: Icons.paypal),
        ],
        children: [
          Center(child: Text('Purchase Requisition Screen')),
          Center(child: Text('Request For Quote Screen')),
          Center(child: Text('Purchase Order Screen')),
        ],
      ),
    );
  }
}
