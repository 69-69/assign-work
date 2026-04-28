import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/layout/custom_scroll_bar.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/remote/get_tenant_by.dart';
import 'package:assign_erp/features/app_training/presentation/screen/how_to_renew_license/widget/subscription_overview.dart';
import 'package:flutter/material.dart';

class HowToRenewLicenseScreen extends StatefulWidget {
  const HowToRenewLicenseScreen({super.key});

  @override
  State<HowToRenewLicenseScreen> createState() =>
      _HowToRenewLicenseScreenState();
}

class _HowToRenewLicenseScreenState extends State<HowToRenewLicenseScreen> {
  Workspace? myAgent;

  @override
  void initState() {
    super.initState();
    _getAgent();
  }

  _getAgent() async {
    final info = (await GetTenant.byWorkspaceId(context.workspace!.agentId));
    setState(() => myAgent = info);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      subTitle: 'Subscription Licenses Guide',
      body: CustomScrollBar(
        controller: ScrollController(),
        child: SubscriptionOverview(myAgent: myAgent),
      ),
    );
  }
}
