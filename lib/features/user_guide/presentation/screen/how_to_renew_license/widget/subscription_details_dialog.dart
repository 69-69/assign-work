import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/text_to_speech.dart';
import 'package:assign_erp/features/system_admin/data/models/company_info_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'overview_details.dart';

extension SubscriptionDetails<T> on BuildContext {
  Future<void> openDetailsBottomSheet(String subscriptionName) =>
      openBottomSheet(
        isExpand: true,
        child: FormBottomSheet(
          title: '$subscriptionName License',
          body: _SubscriptionDetailsBody(subscriptionName: subscriptionName),
        ),
      );
}

class _SubscriptionDetailsBody extends StatelessWidget {
  final String subscriptionName;

  const _SubscriptionDetailsBody({required this.subscriptionName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyBloc, SetupState<Company>>(
      builder: (context, state) => _buildBody(context),
    );
  }

  _buildBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Features of $subscriptionName Subscription',
            style: context.textTheme.titleLarge?.copyWith(
              color: kDarkTextColor,
              fontWeight: FontWeight.w500,
            ),
            // textScaler: TextScaler.linear(context.textScaleFactor),
          ),
          SizedBox(height: 10),
          buildDetails(),
        ],
      ),
    );
  }

  Widget buildDetails() {
    final subscription = subscriptionDetails[subscriptionName.toLowerAll];

    if (subscription != null) {
      final description = subscription.description;
      final features = subscription.features.map(
        (key, value) => MapEntry(key, value.description),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render description
          ...description.map((text) => Text(text)),
          SizedBox(height: 10),
          TextToSpeech(
            title: 'Include',
            subTitle: 'Details of features',
            guides: features, // Passing features directly as a list of strings
          ),
        ],
      );
    } else {
      return Text('No details available');
    }
  }
}
