import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/request_for_quotation_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/orders/request_price_quotation_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/quote/add/add_request_for_quotation.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/quote/list/see_details.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/quote/update/update_request_for_quotation.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/print_request_for_quote.dart';
import 'package:assign_erp/features/setup/data/data_sources/remote/get_suppliers.dart';
import 'package:assign_erp/features/setup/data/data_sources/remote/get_taxes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// LIST Request For Quotations
class ListQuotations extends StatefulWidget {
  final bool isAward;
  const ListQuotations({super.key, this.isAward = false});

  @override
  State<ListQuotations> createState() => _ListQuotationsState();
}

class _ListQuotationsState extends State<ListQuotations> {
  // List to group quotations for printout
  final List<RequestForQuote> _printouts = [];
  bool get _isAward => widget.isAward;

  /*Future<void> computeAllTaxAmounts(RequestForQuotation quote) async {
    final taxRateMap = await GetTaxes.loadAllTaxRates();

    if (quote.taxMethod == TaxMethodToApply.perLineTax) {
      for (final item in quote.lineItems) {
        final taxRate = item.resolveTaxFromMap(taxRateMap);
        final taxAmount = (item.netPrice * taxRate) / 100;
        item.copyWith(taxAmount: taxAmount);
      }
    } else {
      double totalTax = 0.0;
      final taxRate = quote.resolveTaxFromMap(taxRateMap);
      for (final item in quote.lineItems) {
        final taxAmount = (item.netPrice * taxRate) / 100;
        totalTax += taxAmount;
      }
      quote.copyWith(headerTaxAmount: totalTax);
    }
  }*/

  /*Future<({RequestForQuote rfq, Map<String, Map<String, dynamic>> taxNames})>
  calculateTaxAmounts(RequestForQuote quote) async {
    // Calculate tax amounts for each line item (perLineTax)
    if (quote.taxMethod == TaxMethodToApply.perLineTax) {
      final updatedItems = quote.lineItems.map((item) {
        final taxRate = item.resolveTaxFromMap(taxRateMap);
        final taxAmount = (item.netPrice * taxRate) / 100;
        return item.copyWith(taxAmount: taxAmount);
      }).toList();

      // Update line items in the quote
      quote = quote.copyWith(lineItems: updatedItems);
    } else {
      // Calculate total tax amount (headerTax)
      final taxRate = quote.resolveTaxFromMap(taxRateMap);
      final totalTax = quote.lineItems.fold(0.0, (s, item) {
        final taxAmount = (item.netPrice * taxRate) / 100;
        return s + taxAmount;
      });
      prettyPrint('tax-amt', taxRateMap);

      quote = quote.copyWith(headerTaxAmount: totalTax);
    }
    return (rfq: quote, taxNames: taxRateMap);
  }*/

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RequestForQuoteBloc, InventoryState<RequestForQuote>>(
      builder: (context, state) {
        return switch (state) {
          LoadingInventory<RequestForQuote>() => context.loader,
          InventoriesLoaded<RequestForQuote>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Request For Quote',
                    onPressed: () => context.openAddRequestForQuotation(),
                  )
                : _buildCard(context, results),
          InventoryError<RequestForQuote>(error: final error) =>
            context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  ({List<List<String>> rows, List<List<String>>? childrenRow}) _filterQuotes(
    List<RequestForQuote> quotes,
  ) {
    if (_isAward) {
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
    final data = _filterQuotes(quotes);

    return DynamicDataTable(
      omitAtIndex: 0,
      anyWidget: _buildAnyWidget(quotes),
      headers: RequestForQuote.dataTableHeader,
      rows: data.rows,
      childrenRow: data.childrenRow,
      onViewDetailsTap: (row) async => _onViewDetailsTap(quotes, row.first),
      onChecked: (bool? isChecked, row) =>
          _onChecked(quotes, id: row.first, isChecked: isChecked),
      onAllChecked:
          (
            bool isChecked,
            List<bool> isAllChecked,
            List<List<String>> checkedRows,
          ) {
            // if all are unChecked, empty _printouts List
            if (!isAllChecked.first) {
              setState(() => _printouts.clear());
            }
            if (checkedRows.isNotEmpty) {
              for (int i = 0; i < checkedRows.length; i++) {
                final id = checkedRows[i].first;
                _onChecked(quotes, id: id, isChecked: isChecked);
              }
            }
          },
      optButtonLabel: 'Print',
      onOptButtonTap: (row) async => await _onPrintRFQTap(quotes, row.first),
      onEditTap: (row) async => await _onEditTap(quotes, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(quotes, row.first),
    );
  }

  _buildAnyWidget(List<RequestForQuote> quotes) {
    return AdaptiveLayout(
      isFormBuilder: false,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        context.actionInfoButton(
          'Refresh ${_isAward ? 'Award' : 'Request'} For Quotes',
          label: 'Quotations',
          count: quotes.length,
          // Dispatch an event to refresh data
          onPressed: () {
            // Refresh Request For Quotation Data
            context.read<RequestForQuoteBloc>().add(
              RefreshInventories<RequestForQuote>(),
            );
          },
        ),
        // final quoteBloc = context.read<RequestPriceQuotationBloc>();
        // final quoteBloc = BlocProvider.of<RequestPriceQuotationBloc>(context, listen: false);
        const SizedBox(height: 20),
        _IssueMultiQuotesPrintout(
          quotes: _printouts,
          onDone: (s) => setState(() => _printouts.clear()),
        ),
      ],
    );
  }

  /// Check if selected Quotes are related by RFQNumber [_haveSameRFQNumber]
  /// @Return: return Pattern, i.e ({bool a, String b})
  ({bool status, String misMatchID}) _haveSameRFQNumber(
    List<RequestForQuote> selectedQuotes,
  ) {
    if (selectedQuotes.isEmpty) {
      return (status: true, misMatchID: ''); // Handle empty list
    }

    String misMatchRFQNumber = '';
    final firstRFQNumber = selectedQuotes.first.rfqNumber;

    var status = selectedQuotes.every((quote) {
      misMatchRFQNumber = quote.rfqNumber;

      return quote.rfqNumber == firstRFQNumber;
    });

    return (status: status, misMatchID: misMatchRFQNumber);
  }

  // Handle onChecked Quotations
  void _onChecked(
    List<RequestForQuote> quotes, {
    required String id,
    bool? isChecked,
  }) async {
    setState(() {
      final quote = quotes.firstWhere((q) => q.id == id);

      if (isChecked != null && isChecked) {
        // A temporary list, tempQuotesForPrintout, is created which includes
        // the current quotation in _printouts and the new quotation to be checked.
        List<RequestForQuote> tempQuotesForPrintout = List.from(_printouts)
          ..add(quote);

        ({bool status, String misMatchID}) r = _haveSameRFQNumber(
          tempQuotesForPrintout,
        );

        if (r.status) {
          _printouts.add(quote);
        } else {
          context.orderNumberMisMatchWarningDialog(r.misMatchID);
        }
      } else {
        _printouts.remove(quote);
      }
    });
  }

  _onPrintRFQTap(List<RequestForQuote> quotes, String id) async {
    // Show progress dialog while loading data
    await context.progressBarDialog(
      request: _printout(quotes, id),
      onSuccess: (_) =>
          context.showAlertOverlay('Printout successfully created'),
      onError: (error) => context.showAlertOverlay(
        'RFQ printout failed',
        bgColor: kDangerColor,
      ),
    );
  }

  Future<dynamic> _printout(List<RequestForQuote> rfq, String id) =>
      Future.delayed(kRProgressDelay, () async {
        // Simulate loading supplier and company info
        final quote = RequestForQuote.findRFQById(rfq, id).first;
        final sup = await GetSuppliers.bySupplierId(quote.supplierId);

        if (quote.isNotEmpty && sup.isNotEmpty) {
          // Perform action after loading
          PrintRequestForQuotation(quote: quote, supplier: sup).onPrintRFQ();
        }
      });

  Future<void> _onEditTap(List<RequestForQuote> quotes, String id) async {
    final quote = RequestForQuote.findRFQById(quotes, id).first;
    await context.openUpdateRequestForQuotation(quote: quote);
  }

  Future<void> _onDeleteTap(List<RequestForQuote> quotes, String id) async {
    final rfq = RequestForQuote.findRFQById(quotes, id).first;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Remove Quotation from Quote-DB
      context.read<RequestForQuoteBloc>().add(
        DeleteInventory<String>(documentId: rfq.id),
      );
    }
  }

  Future<void> _onViewDetailsTap(
    List<RequestForQuote> quotes,
    String id,
  ) async {
    final taxMap = await GetTaxes.loadAllTaxRates();
    final quote = RequestForQuote.findRFQById(quotes, id).first;

    var newQuote = quote.computeTaxAmounts(taxMap);
    final supplier = await GetSuppliers.bySupplierId(quote.supplierId);
    if (mounted) {
      await context.openSeeDetails(
        quote: newQuote,
        taxNames: taxMap,
        supplier: supplier.name,
      );
    }
  }
}

/// Print grouped or multiple Purchase Quotes [_IssueMultiQuotesPrintout]
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
        PrintRequestForQuotation(
          quote: quotes.first,
          supplier: sup,
        ).onPrintRFQ();
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
      style: OutlinedButton.styleFrom(
        backgroundColor: context.colorScheme.error,
      ),
      onPressed: () async {
        final isConfirmed = await _confirmDeleteDialog(context);
        if (context.mounted && isConfirmed) {
          final ids = quotes.map((q) => q.id).toList();

          // Remove quotes from quotes-DB
          RequestForQuoteBloc(
            firestore: FirebaseFirestore.instance,
          ).add(DeleteInventory<List<String>>(documentId: ids));

          // Check if totalDeleted isEqual to total quotes,
          // is so, then deletion completed
          onDone(true);

          /* int totalDeleted = 0;
            totalDeleted++;
            for (var quote in quotes) {}
            if (totalDeleted == quote.length) {
              onDone(true);
            }*/
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
}
