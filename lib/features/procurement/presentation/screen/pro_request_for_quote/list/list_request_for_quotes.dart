import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/data/data_sources/remote/get_suppliers.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_link_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_rfq/pro_request_for_quote_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/create/create_request_for_quotation.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/list/open_rfq_with_suppliers.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/list/see_rfq_details.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/update/update_request_for_quotation.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/widget/rfq_form_inputs.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/widget/rfq_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// LIST Request For Quotations
class ListRequestForQuotes extends StatefulWidget {
  final bool isAwarded;

  const ListRequestForQuotes({super.key, this.isAwarded = false});

  @override
  State<ListRequestForQuotes> createState() => _ListRequestForQuotesState();
}

class _ListRequestForQuotesState extends State<ListRequestForQuotes> {
  bool _inProgress = false;
  final List<RequestForQuote> _selectedForCompare = [];
  final List<RequestForQuote> _rfqsWithTaxes = [];
  final List<String> _selectedIds = [];
  final List<Supplier> _suppliers = [];

  bool get _isAwarded => widget.isAwarded;

  ProRequestForQuoteBloc get _bloc => context.read<ProRequestForQuoteBloc>();

  void _isDeleting(bool status) {
    setState(() => _inProgress = status);
    if (!status) _selectedIds.clear(); // Clear selected items
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
  }

  void _handleBlocState(
    BuildContext cxt,
    ProcurementState<RequestForQuote> state,
  ) {
    switch (state) {
      case ProcurementDeleted<RequestForQuote>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
        _isDeleting(false);
      case ProcurementError<RequestForQuote>():
        _showAlert('Error saving changes');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      ProRequestForQuoteBloc,
      ProcurementState<RequestForQuote>
    >(listener: _handleBlocState, child: _buildBody());
  }

  BlocBuilder<ProRequestForQuoteBloc, ProcurementState<RequestForQuote>>
  _buildBody() {
    return BlocBuilder<
      ProRequestForQuoteBloc,
      ProcurementState<RequestForQuote>
    >(
      builder: (context, state) {
        return switch (state) {
          LoadingProcurement<RequestForQuote>() => context.loader,
          ProcurementsLoaded<RequestForQuote>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Request For Quote',
                    onPressed: () => context.openRFQForm(),
                  )
                : _buildCard(context, results),
          ProcurementError<RequestForQuote>(error: final error) =>
            context.buildError(error),
          _ => const SizedBox.shrink(), // Default case
        };
      },
    );
  }

  ({List<List<String>> rows, List<List<String>>? childrenRow}) _filterRFQs(
    List<RequestForQuote> quotes,
  ) {
    if (_isAwarded) {
      final todayQuotes = RequestForQuote.filterAwardedRFQ(
        quotes,
      ).map((o) => o.itemAsList).toList();

      return (rows: todayQuotes, childrenRow: null);
    }

    final todayQuotes = RequestForQuote.filterRFQByDate(
      quotes,
    ).map((o) => o.itemAsList).toList();
    final pastQuotes = RequestForQuote.filterRFQByDate(
      quotes,
      isSameDay: false,
    ).map((o) => o.itemAsList).toList();

    return (rows: todayQuotes, childrenRow: pastQuotes);
  }

  Widget _buildCard(BuildContext context, List<RequestForQuote> quotes) {
    // Filter for Quotations by date
    final filtered = _filterRFQs(quotes);

    return DynamicDataTable(
      omitAtIndex: 0,
      toolbar: _buildToolbar(quotes),
      headers: RequestForQuote.dataTableHeader,
      rows: filtered.rows,
      childrenRow: filtered.childrenRow,
      onViewDetailsTap: (row) async => _onViewDetails(quotes, row.first),
      selectedRowKeyIndex: 0,
      selectedRowKeys: _selectedIds,
      onChecked: (bool? isChecked, checkedRow) =>
          _onChecked(isChecked, checkedRow.first, quotes),
      onAllChecked: (bool isChecked, List<bool> isAllChecked, checkedRows) =>
          _onAllChecked(isChecked, checkedRows, quotes),
      optButtonLabel: 'Print',
      onOptButtonTap: (row) async => await _onPrintRFQ(quotes, row.first),
      onEditTap: (row) async => await _onEditTap(quotes, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(quotes, row.first),
    );
  }

  _onChecked(bool? isChecked, String id, List<RequestForQuote> quotes) {
    setState(() {
      if (isChecked == true) {
        if (!_selectedIds.contains(id)) {
          _selectedIds.add(id);
          _selectedRFQs(quotes); // Only select quotes when IDs are updated
        }
      } else {
        // Remove item from the selected list if unchecked
        _selectedIds.removeWhere((selectedId) => selectedId == id);
      }
    });
  }

  _onAllChecked(
    bool isChecked,
    List<List<String>> checkedRows,
    List<RequestForQuote> quotes,
  ) {
    setState(() {
      _selectedIds.clear();
      // Add all selected rows, ensuring uniqueness using a Set
      if (isChecked) {
        _selectedIds.addAll(checkedRows.map((e) => e.first).toSet());
        _selectedRFQs(quotes);
      }
    });
  }

  // Select quotes for comparison based on selected IDs
  void _selectedRFQs(List<RequestForQuote> rfqs) {
    if (_selectedIds.length == 2) {
      // Get the first two selected IDs from _selectedIds
      _selectedIds.take(2).forEach((id) {
        final rfq = _getRFQById(rfqs, id);
        if (rfq != null) {
          _selectedForCompare.add(rfq);
        }
      });
    }
  }

  void _clearComparisonData() {
    setState(() {
      _selectedIds.clear();
      _selectedForCompare.clear();
      _rfqsWithTaxes.clear();
      _suppliers.clear();
    });
  }

  _buildToolbar(List<RequestForQuote> rfqs) {
    return ListToolbarButtons(
      refreshLabel: 'Refresh RFQ',
      primaryLabel: 'Create RFQ',
      secondaryLabel: 'Edit RFQ',
      secondaryIcon: Icons.edit,
      dangerLabel: _inProgress ? 'Deleting...' : 'Delete RFQ',
      compareLabel: 'RFQ',
      dataLength: rfqs.length,
      onPrimary: () => context.openRFQForm(),
      onRefresh: () => _bloc.add(RefreshProcurements<RequestForQuote>()),

      onSecondary: _selectedIds.length == 1
          ? () async => _onEditTap(rfqs, _selectedIds.first)
          : null,
      onCompare: _selectedIds.length == 2
          ? () async => await _onCompareTwoRFQ(context)
          : null,
      onDanger: _selectedIds.isNotEmpty
          ? () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (mounted && isConfirmed) {
                _isDeleting(true);
                _bloc.add(
                  DeleteProcurement<List<String>>(documentId: _selectedIds),
                );
              }
            }
          : null,
    );
  }

  RequestForQuote? _getRFQById(List<RequestForQuote> rfqs, String id) {
    final rfq = RequestForQuote.findRFQById(rfqs, id);
    return rfq.isEmpty ? null : rfq;
  }

  Future<Supplier?> _getSupplier(String supplierId) async {
    final supplier = await GetSuppliers.bySupplierId(supplierId);
    return supplier.isEmpty ? null : supplier;
  }

  Future<void> _onCompareTwoRFQ(BuildContext cxt) async {
    if (_selectedForCompare.length != 2) {
      context.showAlertOverlay(
        'To compare, deselect and then reselect two RFQ',
        bgColor: kDangerColor,
        onCallback: () => _clearComparisonData(),
      );
      return;
    }
    // limit to 2 RFQ
    for (int i = 0; i < 2; i++) {
      final rfq = _selectedForCompare[i];
      final rfqWithTaxes = await RFQFormInputs.applyTaxesToRFQ(rfq);
      final supplier = await _getSupplier(rfq.supplierLinks.first.supplierId);
      if (!supplier.isNullOrEmpty) {
        _rfqsWithTaxes.add(rfqWithTaxes);
        _suppliers.add(supplier!);
      }
    }

    if (cxt.mounted) {
      if (_rfqsWithTaxes.length > 1 &&
          (_rfqsWithTaxes.length != _suppliers.length)) {
        cxt.showAlertOverlay('Mismatch between RFQ and suppliers.');
        return;
      }

      await cxt.openCompareRFQ(rfqs: _rfqsWithTaxes, suppliers: _suppliers);
      _clearComparisonData();
    }
  }

  Future<void> _onViewDetails(List<RequestForQuote> rfqs, String id) async {
    await _withRFQSupplierLinks(
      id,
      rfqs,
      auditAction: AuditAction.viewed,
      onSingleSupplier: (rfq, supplier) async {
        // Open RFQ Details Screen
        return await context.openRFQDetails(
          rfq: rfq,
          supplier: supplier,
          onPrint: (bool isPrinted) {
            if (isPrinted) _bloc.add(_updateHistory(rfq));
          },
        );
      },
      onMultipleSuppliers: (rfq, supplierLinks) async {
        // Open RFQ with suppliers selection
        return await context.openRFQWithSuppliers(
          supplierLinks: supplierLinks,
          // On selected supplier, open RFQ Details Screen
          onSelected: (supplier) => context.openRFQDetails(
            rfq: rfq,
            supplier: supplier,
            onPrint: (bool isPrinted) {
              if (isPrinted) _bloc.add(_updateHistory(rfq));
            },
          ),
        );
      },
    );
  }

  Future<void> _onPrintRFQ(List<RequestForQuote> rfqs, String id) async {
    // Show progress dialog while loading data
    await context.progressBarDialog(
      request: _printout(rfqs, id),
      onSuccess: (_) =>
          context.showAlertOverlay('Printout successfully created'),
      onError: (error) => context.showAlertOverlay(
        'RFQ printout failed',
        bgColor: kDangerColor,
      ),
    );
  }

  Future<void> _printout(List<RequestForQuote> rfqs, String id) async {
    await Future.delayed(kRProgressDelay);

    await _withRFQSupplierLinks(
      id,
      rfqs,
      auditAction: AuditAction.printed,
      onSingleSupplier: (rfq, supplier) {
        return RFQPrinter(rfq: rfq, supplier: supplier).printRFQ();
      },
      onMultipleSuppliers: (rfq, supplierLinks) {
        return context.openRFQWithSuppliers(
          subTitle: 'printout RFQ',
          supplierLinks: supplierLinks,
          onSelected: (supplier) =>
              RFQPrinter(rfq: rfq, supplier: supplier).printRFQ(),
        );
      },
    );
  }

  Future<void> _onEditTap(List<RequestForQuote> rfqs, String id) async {
    final rfq = _getRFQById(rfqs, id);
    if (rfq == null) return;

    await context.openUpdateRFQ(rfq: rfq);
  }

  Future<void> _onDeleteTap(List<RequestForQuote> rfqs, String id) async {
    final rfq = _getRFQById(rfqs, id);
    if (rfq == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      final bloc = _bloc;

      bloc
        ..add(_updateHistory(rfq))
        ..add(DeleteProcurement<String>(documentId: rfq.id));
    }
  }

  /// Audit Log Entry (Tracking actions)
  AuditProcurement<RequestForQuote> _updateHistory(
    RequestForQuote rfq, {
    AuditAction action = AuditAction.deleted,
  }) {
    return AuditProcurement<RequestForQuote>(
      documentId: rfq.id,
      log: AuditLog.logScaffold(
        oldLogs: rfq.history,
        newLog: AuditLog(
          action: action,
          actionBy: context.employee!.employeeId,
          statusAfterAction: rfq.getRFQStatus,
        ),
      ),
    );
  }

  /// Orchestrates an RFQ action that depends on supplier selection.
  /// [_withRFQSupplierLinks]
  /// Resolves the RFQ by [id], applies taxes, logs the given [auditAction],
  /// and then:
  /// - Executes [onSingleSupplier] if exactly one supplier is linked
  /// - Prompts supplier selection and executes [onMultipleSuppliers] otherwise
  ///
  /// Safely guards against invalid state (unmounted widget, missing RFQ,
  /// or empty supplier links) and rechecks [mounted] after async gaps.
  Future<void> _withRFQSupplierLinks(
    String id,
    List<RequestForQuote> rfqs, {
    required AuditAction auditAction,
    required Future<void> Function(
      RequestForQuote rfqWithTaxes,
      Supplier supplier,
    )
    onSingleSupplier,
    required Future<void> Function(
      RequestForQuote rfqWithTaxes,
      List<SupplierLink> supplierLinks,
    )
    onMultipleSuppliers,
  }) async {
    final rfq = _getRFQById(rfqs, id);
    if (!mounted || rfq == null || rfq.supplierLinks.isNullOrEmpty) return;

    final rfqWithTaxes = await RFQFormInputs.applyTaxesToRFQ(rfq);
    if (!mounted) return;

    final supplierLinks = rfq.supplierLinks;

    _bloc.add(_updateHistory(rfq, action: auditAction));

    // Single supplier
    if (supplierLinks.length == 1) {
      final supplier = await _getSupplier(supplierLinks.first.supplierId);
      if (!mounted || supplier == null) return;

      await onSingleSupplier(rfqWithTaxes, supplier);
      return;
    }

    if (!mounted) return;

    // Multiple suppliers
    await onMultipleSuppliers(rfqWithTaxes, supplierLinks);
  }
}
