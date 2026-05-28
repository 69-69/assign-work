import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/material_or_service_choice.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/customer_crm/data/models/customer_model.dart';
import 'package:assign_erp/features/sales_distribution/data/model/sales_quotation_model.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_distribution_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_quotation/sales_quotation_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/screen/sales_quotation/create/create_sales_quotation.dart';
import 'package:assign_erp/features/sales_distribution/presentation/screen/sales_quotation/list/see_sales_quote_details.dart';
import 'package:assign_erp/features/sales_distribution/presentation/screen/sales_quotation/update/update_sales_quotation.dart';
import 'package:assign_erp/features/sales_distribution/presentation/screen/sales_quotation/widget/sq_form_inputs.dart';
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
  bool _inProgress = false;
  List<String> _selectedIds = [];

  bool get _isApproved => widget.isApproved;

  SalesQuotationBloc get _bloc => context.read<SalesQuotationBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _handleBlocState(
    BuildContext cxt,
    SalesDistributionState<SalesQuotation> state,
  ) {
    switch (state) {
      case SalesDistributionDeleted<SalesQuotation>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case SalesDistributionError<SalesQuotation>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      SalesQuotationBloc,
      SalesDistributionState<SalesQuotation>
    >(listener: _handleBlocState, child: _buildBody());
  }

  BlocBuilder<SalesQuotationBloc, SalesDistributionState<SalesQuotation>>
  _buildBody() {
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

  ({List<DataTableRow> rows, List<DataTableRow>? childrenRow}) _filterQuotes(
    List<SalesQuotation> quotes,
  ) {
    if (_isApproved) {
      final todayQuotes = SalesQuotation.filterApprovedSQ(
        quotes,
      ).map(_toTableRow).toList();

      return (rows: todayQuotes, childrenRow: null);
    }

    final todayQuotes = SalesQuotation.filterSQByDate(
      quotes,
    ).map(_toTableRow).toList();
    final pastQuotes = SalesQuotation.filterSQByDate(
      quotes,
      isSameDay: false,
    ).map(_toTableRow).toList();

    return (rows: todayQuotes, childrenRow: pastQuotes);
  }

  Widget _buildCard(BuildContext context, List<SalesQuotation> quotes) {
    // Filter Quotations by date
    final filtered = _filterQuotes(quotes);

    return DynamicDataTable2(
      omitAtIndex: 0,
      maskAtIndex: 2,
      toolbar: _buildToolbar(quotes),
      headers: SalesQuotation.dataTableHeader,
      rows: filtered.rows,
      template: SalesQuotation.templateHeader,
      childrenRow: filtered.childrenRow,
      onViewDetailsTap: (row) async => _onViewDetails(quotes, row.id),
      selectedRowKeys: _selectedIds,
      onSelectionChanged: (ids, rows) {
        setState(() => _selectedIds = ids);
      },
      optButtonLabel: 'Print',
      onOptButtonTap: (row) async => await _onPrintSQ(quotes, row.id),
      onEditTap: (row) async => await _onEditTap(quotes, row.id),
      onDeleteTap: (row) async => await _onDeleteTap(quotes, row.id),
    );
  }

  DataTableRow _toTableRow(SalesQuotation e) =>
      DataTableRow.fromList(e.id, e.itemAsList);

  _buildToolbar(List<SalesQuotation> quotes) {
    return ListToolbarButtons(
      refreshLabel: 'Refresh',
      primaryLabel: 'Create',
      secondaryLabel: 'Edit',
      secondaryIcon: Icons.edit,
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete',
      dataLength: quotes.length,
      onPrimary: () => _openCreateSQ(context),
      onRefresh: () => _bloc.add(RefreshSalesDistributions<SalesQuotation>()),
      onSecondary: _selectedIds.length == 1
          ? () async => _onEditTap(quotes, _selectedIds.first)
          : null,
      onDanger: _selectedIds.isNotEmpty
          ? () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (mounted && isConfirmed) {
                _isDeleting(true);
                _bloc.add(
                  DeleteSalesDistribution<List<String>>(
                    documentId: _selectedIds,
                  ),
                );
              }
            }
          : null,
    );
  }

  Future<void> _openCreateSQ(BuildContext cxt) async {
    final lineItemType = await cxt.openMaterialOrServiceToggle('Quote');

    if (cxt.mounted && '$lineItemType'.hasValue) {
      await cxt.openCreateSQForm(
        type: lineItemType,
        onBackPress: () async {
          Navigator.pop(cxt);

          if (cxt.mounted && '$lineItemType'.hasValue) {
            await _openCreateSQ(cxt);
          }
        },
      );
    }
  }

  SalesQuotation? _getSQById(List<SalesQuotation> quotes, String id) {
    final quote = SalesQuotation.findSQById(quotes, id);
    return quote.isEmpty ? null : quote;
  }

  Future<void> _onViewDetails(List<SalesQuotation> quotes, String id) async {
    await _withTaxAndCustomerInfo(
      id,
      quotes,
      auditAction: AuditAction.viewed,
      shouldProcessCustomerInfo: false,
      onQuoteProcessed: (quoteWithTax, customer) async {
        return await context.openSQDetails(
          salesQuote: quoteWithTax,
          // customer: customer,
          onPrint: (bool isPrinted) {
            if (isPrinted) _bloc.add(_updateHistory(quoteWithTax));
          },
        );
      },
    );
  }

  Future<void> _onPrintSQ(List<SalesQuotation> quotes, String id) async {
    // Show progress dialog while loading data
    await context.progressBarDialog(
      request: _printout(quotes, id),
      onSuccess: (_) => _showAlert('Printout successfully created'),
      onError: (error) => _showAlert('Quote printout failed'),
    );
  }

  Future<void> _printout(List<SalesQuotation> quotes, String id) async {
    await Future.delayed(kRProgressDelay);

    await _withTaxAndCustomerInfo(
      id,
      quotes,
      auditAction: AuditAction.printed,
      shouldProcessCustomerInfo: false,
      onQuoteProcessed: (quote, customer) {
        return Future.delayed(kRProgressDelay); // temporal placeholder
        // return SQPrinter(quote: quote, customer: customer).printSQ();
      },
    );
  }

  Future<void> _onEditTap(List<SalesQuotation> quotes, String id) async {
    await _withTaxAndCustomerInfo(
      id,
      quotes,
      auditAction: AuditAction.viewed,
      shouldProcessCustomerInfo: false,
      onQuoteProcessed: (quoteWithTaxes, _) async {
        return await context.openUpdateSalesQuote(serverQuote: quoteWithTaxes);
      },
    );
  }

  Future<void> _onDeleteTap(List<SalesQuotation> quotes, String id) async {
    final quote = _getSQById(quotes, id);
    if (quote == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      final bloc = _bloc;

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

  Future<void> _withTaxAndCustomerInfo(
    String quoteId,
    List<SalesQuotation> quotes, {
    bool shouldProcessCustomerInfo = true,
    required AuditAction auditAction,
    required Future<void> Function(
      SalesQuotation quoteWithTaxes,
      Customer customer,
    )
    onQuoteProcessed,
  }) async {
    final quote = _getSQById(quotes, quoteId); // Get quote by ID
    if (!mounted || quote == null || quote.customerId.isNullOrEmpty) return;

    final quoteWithTaxes = await SQFormInputs.applyTaxesToQuote(
      quote,
    ); // Apply taxes
    if (!mounted) return;

    // Update history with the audit action
    _bloc.add(_updateHistory(quote, action: auditAction));

    if (!shouldProcessCustomerInfo) {
      return onQuoteProcessed(quoteWithTaxes, Customer.empty);
    }

    // Fetch customer information
    final customer = await SQFormInputs.getCustomer(quote.customerId);
    if (!mounted || customer == null) return;

    // Process quote with customer data
    await onQuoteProcessed(quoteWithTaxes, customer);
  }

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
