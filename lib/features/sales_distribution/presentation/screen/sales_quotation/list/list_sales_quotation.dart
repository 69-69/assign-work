import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/material_or_service_choice.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/customer_crm/data/data_sources/remote/get_customers.dart';
import 'package:assign_erp/features/customer_crm/data/models/customer_model.dart';
import 'package:assign_erp/features/sales_distribution/data/model/sales_quotation_model.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_distribution_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_quotation/sales_quotation_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/screen/sales_quotation/create/create_sales_quotation.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_taxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// List Sales Quotations
class ListSalesQuotations extends StatefulWidget {
  final bool isApproved;

  const ListSalesQuotations({super.key, this.isApproved = false});

  @override
  State<ListSalesQuotations> createState() => _ListSalesQuotationsState();
}

class _ListSalesQuotationsState extends State<ListSalesQuotations> {
  // List to group quotations for printout
  final List<SalesQuotation> _selectedForCompare = [];
  final List<String> _selectedIds = [];

  bool get _isApproved => widget.isApproved;

  SalesQuotationBloc get _readBloc => context.read<SalesQuotationBloc>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      SalesQuotationBloc,
      SalesDistributionState<SalesQuotation>
    >(
      builder: (context, state) {
        return switch (state) {
          LoadingSalesDistribution<SalesQuotation>() => context.loader,
          SalesDistributionsLoaded<SalesQuotation>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Sales Quote',
                    onPressed: () => _openCreateSQ(context),
                  )
                : _buildCard(context, results),
          SalesDistributionError<SalesQuotation>(error: final error) =>
            context.buildError(error),
          _ => const SizedBox.shrink(), // Default case
        };
      },
    );
  }

  ({List<List<String>> rows, List<List<String>>? childrenRow}) _filterQuotes(
    List<SalesQuotation> quotes,
  ) {
    if (_isApproved) {
      final todayQuotes = SalesQuotation.filterApprovedSQ(
        quotes,
      ).map((o) => o.itemAsList).toList();

      return (rows: todayQuotes, childrenRow: null);
    }

    final todayQuotes = SalesQuotation.filterSQByDate(
      quotes,
    ).map((o) => o.itemAsList).toList();
    final pastQuotes = SalesQuotation.filterSQByDate(
      quotes,
      isSameDay: false,
    ).map((o) => o.itemAsList).toList();

    return (rows: todayQuotes, childrenRow: pastQuotes);
  }

  Widget _buildCard(BuildContext context, List<SalesQuotation> quotes) {
    // Filter for Quotations by date
    final filtered = _filterQuotes(quotes);

    return DynamicDataTable(
      omitAtIndex: 0,
      toolbar: _buildToolbar(quotes),
      headers: SalesQuotation.dataTableHeader,
      rows: filtered.rows,
      childrenRow: filtered.childrenRow,
      onViewDetailsTap: (row) async => _onViewDetails(quotes, row.first),
      selectedRowKeyIndex: 0,
      // Column index used as row key (e.g., ID)
      selectedRowKeys: _selectedIds,
      // Currently selected row keys
      onChecked: (bool? isChecked, checkedRow) {
        setState(() => _updateSelectedIds(isChecked, checkedRow.first, quotes));
      },
      onAllChecked:
          (
            bool isChecked,
            List<bool> isAllChecked,
            List<List<String>> checkedRows,
          ) {
            setState(
              () => _updateAllSelectedIds(isChecked, checkedRows, quotes),
            );
          },
      optButtonLabel: 'Print',
      onOptButtonTap: (row) async => await _onPrintSQ(quotes, row.first),
      onEditTap: (row) async => await _onEditTap(quotes, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(quotes, row.first),
    );
  }

  Future<void> _openCreateSQ(BuildContext cxt) async {
    final lineItemType = await cxt.openMaterialOrServiceToggle('Quote');
    if (cxt.mounted && '$lineItemType'.isNotNullNorEmpty) {
      await cxt.openCreateSQForm(
        type: lineItemType,
        onBackPress: () async {
          Navigator.pop(cxt);

          if (cxt.mounted && '$lineItemType'.isNotNullNorEmpty) {
            await _openCreateSQ(cxt);
          }
        },
      );
    }
  }

  // Updates selected IDs and triggers additional logic (like selecting quotes)
  void _updateSelectedIds(
    bool? isChecked,
    String id,
    List<SalesQuotation> quotes,
  ) {
    if (isChecked == true) {
      if (!_selectedIds.contains(id)) {
        _selectedIds.add(id);
        _selectedQuotes(quotes); // Only select quotes when IDs are updated
      }
    } else {
      // Remove item from the selected list if unchecked
      _selectedIds.removeWhere((selectedId) => selectedId == id);
    }
  }

  // Updates selected IDs for all checked rows
  void _updateAllSelectedIds(
    bool isChecked,
    List<List<String>> checkedRows,
    List<SalesQuotation> quotes,
  ) {
    _selectedIds.clear();
    if (isChecked) {
      // Add all selected rows, ensuring uniqueness using a Set
      _selectedIds.addAll(checkedRows.map((e) => e.first).toSet());
      _selectedQuotes(quotes);
    }
  }

  // Select quotes for comparison based on selected IDs
  void _selectedQuotes(List<SalesQuotation> quotes) {
    if (_selectedIds.length == 2) {
      // Get the first two selected IDs from _selectedIds
      _selectedIds.take(2).forEach((id) {
        final quote = _getSQById(quotes, id);
        if (quote != null) {
          _selectedForCompare.add(quote);
        }
      });
    }
  }

  _buildToolbar(List<SalesQuotation> quotes) {
    return AdaptiveLayout(
      isFormBuilder: false,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        context.actionInfoButton(
          'Refresh ${_isApproved ? 'Approved' : ''} Quotes',
          label: 'Quotations',
          count: quotes.length,
          onPressed: () =>
              _readBloc.add(RefreshSalesDistributions<SalesQuotation>()),
        ),
        const SizedBox(width: 20),
        context.elevatedButton(
          'Create Sales Quote',
          onPressed: () => _openCreateSQ(context),
          bgColor: kDangerColor,
          txtColor: kWhiteColor,
        ),
        if (_selectedIds.length > 1) ...[
          const SizedBox(width: 20),
          context.elevatedButton(
            'Delete',
            txtColor: kWhiteColor,
            bgColor: kDangerColor,
            tooltip: 'Delete selected Quotes',
            onPressed: () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (mounted && isConfirmed) {
                /// Delete all selected Sales Quotations
                _readBloc.add(
                  DeleteSalesDistribution<List<String>>(
                    documentId: _selectedIds,
                  ),
                );
              }
            },
          ),
        ],
      ],
    );
  }

  SalesQuotation? _getSQById(List<SalesQuotation> quotes, String id) {
    final quote = SalesQuotation.findSQById(quotes, id);
    return quote.isEmpty ? null : quote;
  }

  Future<SalesQuotation> _applyTaxesToSQ(SalesQuotation quote) async {
    final taxMap = await GetTaxes.loadAllTaxRates();
    return quote.computeTaxAmounts(taxMap);
  }

  Future<Customer?> _getCustomer(String customerId) async {
    final customer = await GetAllCustomers.byCustomerId(customerId);
    return customer.isEmpty ? null : customer;
  }

  Future<void> _onViewDetails(List<SalesQuotation> quotes, String id) async {
    await _withCustomerInfo(
      id,
      quotes,
      auditAction: AuditAction.viewed,
      onSingleCustomer: (quote, customer) async {
        return Future.delayed(kRProgressDelay); // temporal placeholder
        /*return await context.openSQDetails(
          quote: quote,
          customer: customer,
          bloc: _readBloc,
        );*/
      },
    );
  }

  Future<void> _onPrintSQ(List<SalesQuotation> quotes, String id) async {
    // Show progress dialog while loading data
    await context.progressBarDialog(
      request: _printout(quotes, id),
      onSuccess: (_) =>
          context.showAlertOverlay('Printout successfully created'),
      onError: (error) => context.showAlertOverlay(
        'Quote printout failed',
        bgColor: kDangerColor,
      ),
    );
  }

  Future<void> _printout(List<SalesQuotation> quotes, String id) async {
    await Future.delayed(kRProgressDelay);

    await _withCustomerInfo(
      id,
      quotes,
      auditAction: AuditAction.printed,
      onSingleCustomer: (quote, customer) {
        return Future.delayed(kRProgressDelay); // temporal placeholder
        // return SQPrinter(quote: quote, customer: customer).printSQ();
      },
    );
  }

  Future<void> _onEditTap(List<SalesQuotation> quotes, String id) async {
    final quote = _getSQById(quotes, id);
    if (quote == null) return;

    // await context.openUpdateSalesQuote(quote: quote);
  }

  Future<void> _onDeleteTap(List<SalesQuotation> quotes, String id) async {
    final quote = _getSQById(quotes, id);
    if (quote == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      final bloc = _readBloc;

      bloc
        ..add(_updateHistory(quote))
        ..add(DeleteSalesDistribution<String>(documentId: quote.id));
    }
  }

  /// Audit Log Entry (Tracking actions)
  AuditSalesDistribution<SalesQuotation> _updateHistory(
    SalesQuotation quote, {
    AuditAction action = AuditAction.deleted,
  }) {
    return AuditSalesDistribution<SalesQuotation>(
      documentId: quote.id,
      log: AuditLog.logScaffold(
        oldLogs: quote.history,
        newLog: AuditLog(
          action: action,
          actionBy: context.employee!.employeeId,
          statusAfterAction: quote.getSQStatus,
        ),
      ),
    );
  }

  Future<void> _withCustomerInfo(
    String id,
    List<SalesQuotation> quotes, {
    required AuditAction auditAction,
    required Future<void> Function(
      SalesQuotation quoteWithTaxes,
      Customer customer,
    )
    onSingleCustomer,
  }) async {
    final quote = _getSQById(quotes, id);
    if (!mounted || quote == null || quote.customerId.isNullOrEmpty) return;

    final quoteWithTaxes = await _applyTaxesToSQ(quote);
    if (!mounted) return;

    _readBloc.add(_updateHistory(quote, action: auditAction));

    final customer = await _getCustomer(quote.customerId);
    if (!mounted || customer == null) return;

    await onSingleCustomer(quoteWithTaxes, customer);
  }
}
