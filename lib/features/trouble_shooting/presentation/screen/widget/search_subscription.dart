import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/remote/get_subscriptions.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/subscription_model.dart';
import 'package:flutter/material.dart';

/// Search License Subscription [SearchRole]
class SearchSubscription extends StatelessWidget {
  final String? initialValue;
  final Function(Subscription?) onChanged;

  const SearchSubscription({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Subscription>(
      labelText: (initialValue ?? 'Select Subscription...').toTitleCase,
      asyncItems: (String filter, loadProps) async =>
          await GetSubscriptions.load(),
      filterFn: (sub, filter) {
        var f = filter.isEmpty ? (initialValue ?? '') : filter;
        return sub.filterByAny(f);
      },
      itemAsString: (sub) => sub.itemAsString,
      onChanged: (sub) => onChanged(sub),
      validator: (sub) => sub == null ? 'Subscription is required' : null,
    );
  }
}
