import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/app_training/data/models/subscription_model.dart';
import 'package:assign_erp/features/app_training/presentation/screen/how_to_renew_license/widget/subscription_details_dialog.dart';
import 'package:flutter/material.dart';

import 'overview_details.dart';

class SubscriptionOverview extends StatelessWidget {
  final Workspace? myAgent;

  const SubscriptionOverview({super.key, this.myAgent});

  @override
  Widget build(BuildContext context) {
    final subscriptions = subs.map((sub) => Feature.fromMap(sub)).toList();

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overview,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          SizedBox(height: 20),
          Text(
            'Subscription Licenses Overview',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.outlineColor,
            ),
            textScaler: TextScaler.linear(context.textScaleFactor),
          ),
          SizedBox(height: 10),

          // Subscription List
          ...subscriptions.map((sub) => OverviewCard(sub: sub)),

          if (myAgent != null) ...[
            GenericCard(
              headTitle: 'License Agent Contact',
              title: myAgent!.clientName,
              subTitle: 'Your License Agent',
              extra: [
                {'title': 'Mobile', 'value': myAgent!.mobileNumber},
                {'title': 'Email', 'value': myAgent!.email},
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class OverviewCard extends StatelessWidget {
  final Feature sub;

  const OverviewCard({super.key, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        dense: true,
        title: Text(
          '${sub.title} License',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(sub.description),
        onTap: () async {
          await context.openDetailsBottomSheet(sub.title);
          /*Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OverviewDetails(subscriptionName: sub.title),
            ),
          );*/
        },
      ),
    );
  }
}
