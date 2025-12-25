import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/layout/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/invoice/widget/index.dart';
import 'package:flutter/material.dart';

class InvoiceScreen extends StatefulWidget {
  final String? title;
  final Object? item;

  const InvoiceScreen({super.key, this.item, this.title});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  Map<String, dynamic> searchData = {};
  final ScrollController _scrollController = ScrollController();

  String get title => widget.title ?? 'invoice';

  Map<String, dynamic> get data =>
      (widget.item ?? searchData) as Map<String, dynamic>;

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Print ${title.toTitle}',
      body: CustomScrollBar(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 20.0),
        child: InvoiceSummary(title: title, data: data),
      ),
      actions: const [],
      floatingActionButton: context.buildFloatingBtn(
        'print out',
        onPressed: () {},
        icon: Icons.print,
      ),
    );
  }
}
