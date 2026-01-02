import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
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
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/widget/rfq_printer.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_taxes.dart';
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
  // List to group quotations for printout
  final List<RequestForQuote> _selectedForCompare = [];
  final List<RequestForQuote> _rfqsWithTaxes = [];
  final List<String> _selectedIds = [];
  final List<Supplier> _suppliers = [];

  bool get _isAwarded => widget.isAwarded;

  ProRequestForQuoteBloc get _readBloc =>
      context.read<ProRequestForQuoteBloc>();

  @override
  Widget build(BuildContext context) {
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
      onOptButtonTap: (row) async => await _onPrintRFQ(quotes, row.first),
      onEditTap: (row) async => await _onEditTap(quotes, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(quotes, row.first),
    );
  }

  // Updates selected IDs and triggers additional logic (like selecting quotes)
  void _updateSelectedIds(
    bool? isChecked,
    String id,
    List<RequestForQuote> quotes,
  ) {
    if (isChecked == true) {
      if (!_selectedIds.contains(id)) {
        _selectedIds.add(id);
        _selectedRFQs(quotes); // Only select quotes when IDs are updated
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
    List<RequestForQuote> quotes,
  ) {
    _selectedIds.clear();
    if (isChecked) {
      // Add all selected rows, ensuring uniqueness using a Set
      _selectedIds.addAll(checkedRows.map((e) => e.first).toSet());
      _selectedRFQs(quotes);
    }
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
    return AdaptiveLayout(
      isFormBuilder: false,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        context.actionInfoButton(
          'Refresh ${_isAwarded ? 'Awarded' : 'Request For'} Quotes',
          label: 'RFQ',
          count: rfqs.length,
          onPressed: () =>
              _readBloc.add(RefreshProcurements<RequestForQuote>()),
        ),
        const SizedBox(width: 20),
        context.elevatedButton(
          'Create RFQ',
          bgColor: kDangerColor,
          txtColor: kWhiteColor,
          onPressed: () => context.openRFQForm(),
        ),
        // Compare two RFQS
        if (_selectedIds.length == 2) ...[
          const SizedBox(width: 20),
          context.compareButton(
            'Compare RFQ',
            onPressed: () async => await _onCompareTwoRFQ(context),
            bgColor: kSuccessColor,
            txtColor: kWhiteColor,
            tooltip: 'Compare two RFQs',
          ),
        ],
        if (_selectedIds.length > 1) ...[
          const SizedBox(width: 20),
          context.elevatedButton(
            'Delete',
            txtColor: kWhiteColor,
            bgColor: kDangerColor,
            tooltip: 'Delete selected RFQ',
            onPressed: () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (mounted && isConfirmed) {
                /// Delete all selected Quotations from RFQ-DB
                _readBloc.add(
                  DeleteProcurement<List<String>>(documentId: _selectedIds),
                );
              }
            },
          ),
        ],
        // final quoteBloc = context.read<RequestPriceQuotationBloc>();
        // final quoteBloc = BlocProvider.of<RequestPriceQuotationBloc>(context, listen: false);
        /*const SizedBox(height: 20),
        _IssueMultiQuotesPrintout(
          quotes: _selectedForCompare,
          onDone: (s) => setState(() => _selectedForCompare.clear()),
        ),*/
      ],
    );
  }

  RequestForQuote? _getRFQById(List<RequestForQuote> rfqs, String id) {
    final rfq = RequestForQuote.findRFQById(rfqs, id);
    return rfq.isEmpty ? null : rfq;
  }

  Future<RequestForQuote> _applyTaxesToRFQ(RequestForQuote rfq) async {
    final taxMap = await GetTaxes.loadAllTaxRates();
    return rfq.computeTaxAmounts(taxMap);
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
      final rfqWithTaxes = await _applyTaxesToRFQ(rfq);
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
        return await context.openRFQDetails(
          rfq: rfq,
          supplier: supplier,
          bloc: _readBloc,
        );
      },
      onMultipleSuppliers: (rfq, supplierLinks) async {
        return await context.openRFQWithSuppliers(
          supplierLinks: supplierLinks,
          onSelected: (supplier) => context.openRFQDetails(
            rfq: rfq,
            supplier: supplier,
            bloc: _readBloc,
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

    await context.openUpdateRequestForQuote(rfq: rfq);
  }

  Future<void> _onDeleteTap(List<RequestForQuote> rfqs, String id) async {
    final rfq = _getRFQById(rfqs, id);
    if (rfq == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      final bloc = _readBloc;

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

    final rfqWithTaxes = await _applyTaxesToRFQ(rfq);
    if (!mounted) return;

    final supplierLinks = rfq.supplierLinks;

    _readBloc.add(_updateHistory(rfq, action: auditAction));

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

/* Future<void> _onViewDetails2(List<RequestForQuote> quotes, String id) async {
    final quote = _getQuoteById(quotes, id);
    if (!mounted || quote == null || quote.supplierLinks.isNullOrEmpty) return;

    final quoteWithTaxes = await _applyTaxesToQuote(quote);
    List<SupplierLink> supplierLinks = quote.supplierLinks;

    // Log that User viewed details
    if (AuditTracker.shouldLog(id: quote.id, type: DocType.rfq)) {
      _readBloc.add(_updateHistory(quote, action: AuditAction.viewed));
    }

    // Check the length of supplierLinks
    // If Single supplier → open RFQ Details directly
    if (supplierLinks.length == 1) {
      final supplier = await _getSupplier(supplierLinks.first.supplierId);
      if (!mounted || supplier == null) return;

      await context.openRFQDetails(
        quote: quoteWithTaxes,
        supplier: supplier,
        bloc: _readBloc,
      );
      return;
    }

    if (!mounted) return;
    // Otherwise, Multiple supplierLinks → let user select one to view RFQ details
    await context.openRFQInvitedSuppliers(
      supplierLinks: supplierLinks,
      onSelected: (Supplier supplier) async => await context.openRFQDetails(
        quote: quoteWithTaxes,
        supplier: supplier,
        bloc: _readBloc,
      ), // Open RFQ Details Screen
    );
  }


  Future<dynamic> _printout2(
    List<RequestForQuote> quotes,
    String id,
  ) => Future.delayed(kRProgressDelay, () async {
    final quote = _getQuoteById(quotes, id);
    if (!mounted || quote == null || quote.supplierLinks.isNullOrEmpty) return;

    final quoteWithTaxes = await _applyTaxesToQuote(quote);
    List<SupplierLink> supplierLinks = quote.supplierLinks;

    _readBloc.add(_updateHistory(quote, action: AuditAction.printed));

    // Check the length of supplierLinks
    // If Single supplier → print RFQ directly
    if (supplierLinks.length == 1) {
      final supplier = await _getSupplier(supplierLinks.first.supplierId);
      if (!mounted || supplier == null) return;

      await RFQPrinter(quote: quoteWithTaxes, supplier: supplier).printRFQ();

      return;
    }

    if (!mounted) return;
    // Otherwise, Multiple supplierLinks → let user select one to print RFQ with
    await context.openRFQInvitedSuppliers(
      supplierLinks: quote.supplierLinks,
      onSelected: (Supplier supplier) async => await RFQPrinter(
        quote: quoteWithTaxes,
        supplier: supplier,
      ).printRFQ(), // Print the RFQ for the selected supplier
    );
  });*/

/*/// Print grouped or multiple Purchase Quotes [_IssueMultiQuotesPrintout]
class _IssueMultiQuotesPrintout extends StatelessWidget {
  final List<RequestForQuote> quotes;
  final Function(bool) onDone;

  const _IssueMultiQuotesPrintout({required this.quotes, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return quotes.isEmpty
        ? const SizedBox.shrink()
        : Center(child: _buildBody(context));
  }

  _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Wrap(
        spacing: 20,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          _buildPrintButton(context),
          _buildNote(),
          _buildDeleteButton(context),
        ],
      ),
    );
  }

  _buildPrintButton(BuildContext context) {
    return context.elevatedIconBtn(
      Icon(Icons.print, color: kWarningColor),
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: kWarningColor),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      onPressed: () async {
        final sup = await GetSuppliers.bySupplierId(quotes.first.supplierId);

        // Perform action after loading
        RFQPrinter(quote: quotes.first, supplier: sup).printRFQ();
      },
      label: const Text('Print', style: TextStyle(color: kWarningColor)),
    );
  }

  Future<bool> _confirmDeleteDialog(BuildContext context) async {
    return context.confirmAction<bool>(
      const Text('Are you sure you want to delete the selected Quote?'),
      title: "Confirm Delete",
      onAccept: "Delete",
      onReject: "Cancel",
    );
  }

  _buildDeleteButton(BuildContext context) {
    return context.elevatedIconBtn(
      Icon(Icons.delete, color: kWhiteColor),
      style: OutlinedButton.styleFrom(backgroundColor: context.errorColor),
      onPressed: () async {
        final isConfirmed = await _confirmDeleteDialog(context);
        if (context.mounted && isConfirmed) {
          final ids = quotes.map((q) => q.id).toList();

          // Remove quotes from quotes-DB
          ProRequestForQuoteBloc(
            firestore: FirebaseFirestore.instance,
          ).add(DeleteProcurement<List<String>>(documentId: ids));

          // Check if totalDeleted isEqual to total quotes,
          // is so, then deletion completed
          onDone(true);
        }
      },
      label: const Text('Delete', style: TextStyle(color: kWhiteColor)),
    );
  }

  Padding _buildNote() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: RichText(
        text: const TextSpan(
          text: 'NOTE: ',
          style: TextStyle(color: kDangerColor, fontWeight: FontWeight.bold),
          children: [
            TextSpan(
              text:
                  'Multiple or Grouped Quotations Must Have Identical RFQ Numbers',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/
