import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/discount_group_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/discount_rule_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/pricing_discount_master/create/create_discount_rule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListDiscountRules extends StatefulWidget {
  const ListDiscountRules({super.key});

  @override
  State<ListDiscountRules> createState() => _ListDiscountRulesState();
}

class _ListDiscountRulesState extends State<ListDiscountRules> {
  bool _inProgress = false;
  List<String> _selectedIds = [];

  late final DiscountRuleBloc _bloc;

  // DiscountRuleBloc get _bloc => context.read<DiscountRuleBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) => context.showAlertOverlay(msg);

  void _handleBlocState(BuildContext cxt, SetupState<DiscountRule> state) {
    switch (state) {
      case SetupDeleted<DiscountRule>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case SetupError<DiscountRule>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _bloc = DiscountRuleBloc(firestore: FirebaseFirestore.instance)
      ..add(GetSetups<DiscountRule>());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<DiscountRuleBloc, SetupState<DiscountRule>>(
        listener: _handleBlocState,
        child: _buildBody(),
      ),
    );
  }

  BlocBuilder<DiscountRuleBloc, SetupState<DiscountRule>> _buildBody() {
    return BlocBuilder<DiscountRuleBloc, SetupState<DiscountRule>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<DiscountRule>() => context.loader,
          SetupsLoaded<DiscountRule>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Discount Rule',
                    onPressed: () => _openDiscountRuleForm(context),
                  )
                : _buildCard(context, results),
          SetupError<DiscountRule>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<DiscountRule> masters) {
    return DynamicDataTable2(
      omitAtIndex: 0,
      // maskAtIndex: 1,
      toolbar: _buildToolbar(masters),
      headers: DiscountRule.dataTableHeader,
      rows: masters.map(_toTableRow).toList(),
      template: DiscountRule.templateHeader,
      selectedRowKeys: _selectedIds,
      onSelectionChanged: (ids, rows) {
        setState(() => _selectedIds = ids);
      },
      onEditTap: (row) async => await _onEditTap(masters, row.id),
      onDeleteTap: (row) async => await _onDeleteTap(masters, row.id),
    );
  }

  TableRowData _toTableRow(DiscountRule e) =>
      TableRowData.fromList(e.id, e.itemAsList);

  Widget _buildToolbar(List<DiscountRule> masters) {
    return ListToolbarButtons(
      dataLength: masters.length,
      primaryLabel: 'Create',
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete',
      refreshLabel: 'Refresh',
      onPrimary: () => _openDiscountRuleForm(context),
      onRefresh: () => _bloc.add(RefreshSetups<DiscountRule>()),
      onDanger: _selectedIds.isNotEmpty
          ? () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (mounted && isConfirmed) {
                _isDeleting(true);
                _bloc.add(DeleteSetup<List<String>>(documentId: _selectedIds));
              }
            }
          : null,
    );
  }

  Future<void> _onEditTap(List<DiscountRule> rules, String id) async {
    final rule = DiscountRule.findById(rules, id);
    if (rule == null) return;

    await _openDiscountRuleForm(context, serverItem: rule);
  }

  Future<void> _onDeleteTap(List<DiscountRule> rules, String id) async {
    final rule = DiscountRule.findById(rules, id);
    if (rule == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      _bloc.add(DeleteSetup<String>(documentId: rule.id));
    }
  }

  Future<void> _openDiscountRuleForm(
    BuildContext cxt, {
    DiscountRule? serverItem,
  }) async => await cxt.openAddDiscountRule(serverRule: serverItem);

  /*_onChecked(bool? isChecked, checkedRow) {
    setState(() {
      final id = checkedRow.first;
      if (isChecked == true) {
        if (!_selectedIds.contains(id)) _selectedIds.add(id);
      } else {
        // Remove item from the selected list if unchecked
        _selectedIds.removeWhere((selectedId) => selectedId == id);
      }
    });
  }

  _onAllChecked(
    bool isChecked,
    List<bool> isAllChecked,
    List<List<String>> checkedRows,
  ) {
    setState(() {
      _selectedIds.clear();
      // Add all selected rows, ensuring uniqueness using a Set
      if (isChecked) {
        _selectedIds.addAll(checkedRows.map((e) => e.first).toSet());
      }
    });
  }*/
}
