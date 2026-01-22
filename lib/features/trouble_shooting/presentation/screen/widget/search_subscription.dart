import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/remote/get_subscriptions.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/subscription_model.dart';
import 'package:flutter/material.dart';

/// Search License Subscription [SearchRole]
class SearchSubscription extends StatefulWidget {
  final String? initialValue;
  final Function(Subscription?) onChanged;

  const SearchSubscription({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SearchSubscription> createState() => _SearchSubscriptionState();
}

class _SearchSubscriptionState extends State<SearchSubscription> {
  String? _initialValue;
  Subscription? _subscription;

  String get _labelText => 'Select Subscription...';

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSubscriptions());
  }

  Future _loadSubscriptions({String? filter}) async {
    final initial = widget.initialValue ?? '';
    final filterBy = filter.isNullOrEmpty ? initial : filter;
    // If filter contains wildCard/asterisk '*', load all Subscriptions
    // Else load Subscriptions that match the filter
    final subs = await (filterBy!.contains('*')
        ? GetSubscriptions.load()
        : GetSubscriptions.byAnyTerm(filterBy));

    if (mounted && initial.hasValue && subs.hasValue) {
      setState(() => _subscription = subs.first);
    }
    return subs;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Subscription>(
      selectedItem: _subscription,
      labelText: _labelText,
      helperText: 'Enter * for all subscriptions, or type to search',
      asyncItems: (String filter, loadProps) async =>
          await _loadSubscriptions(filter: filter),
      filterFn: (bin, filter) => _filterSub(filter, bin),
      itemAsString: (bin) => bin.itemAsString,
      onChanged: (sub) => widget.onChanged(sub),
      validator: (bin) => bin == null ? _labelText : null,
    );
  }

  bool _filterSub(String filter, Subscription item) {
    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = item.filterByAny(term);
    return matches;
  }
}

/*class SearchSubscription2 extends StatelessWidget {
  final String? initialValue;
  final Function(Subscription?) onChanged;

  const SearchSubscription2({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Subscription>(
      labelText: ('Select Subscription...').toTitle,
      asyncItems: (String filter, loadProps) async =>
          await GetSubscriptions.load(),
      filterFn: (sub, filter) {
        return _filterSub(filter, sub);
        var f = filter.isEmpty ? (initialValue ?? '') : filter;
        return sub.filterByAny(f);
      },
      itemAsString: (sub) => sub.itemAsString,
      onChanged: (sub) => onChanged(sub),
      validator: (sub) => sub == null ? 'Subscription is required' : null,
    );
  }

  bool _filterSub(String filter, Subscription item) {
    final term = filter.isEmpty ? (initialValue ?? '') : filter;
    final matches = item.filterByAny(term);
    return matches;
  }
}
*/
