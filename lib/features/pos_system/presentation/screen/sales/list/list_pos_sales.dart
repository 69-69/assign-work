import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_sale_model.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/pos_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/sales/pos_sale_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/sales/create/create_pos_sale.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/sales/update/update_pos_sale.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/widget/pos_report_printer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// All POS SALES
class ListPOSSales extends StatefulWidget {
  const ListPOSSales({super.key});

  @override
  State<ListPOSSales> createState() => _ListPOSSalesState();
}

class _ListPOSSalesState extends State<ListPOSSales> {
  // List to group orders for printout
  final List<POSSale> _groupReportsForPrintout = [];

  // final SaleBloc saleBloc = BlocProvider.of<SaleBloc>(context);

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  BlocBuilder<POSSaleBloc, POSState<POSSale>> _buildBody() {
    return BlocBuilder<POSSaleBloc, POSState<POSSale>>(
      builder: (context, state) {
        return switch (state) {
          LoadingPOS<POSSale>() => context.loader,
          POSsLoaded<POSSale>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Add Sales',
                    onPressed: () => context.openAddPOSSales(),
                  )
                : _buildCard(results),
          POSError<POSSale>(error: final error) => context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(List<POSSale> sales) {
    List<POSSale> todaySales = POSSale.filterSalesByDate(sales);
    List<POSSale> pastSales = POSSale.filterSalesByDate(
      sales,
      isSameDay: false,
    );

    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 2,
      headers: POSSale.dataTableHeader,
      toolbar: _buildToolbar(sales),
      rows: todaySales.map((s) => s.itemAsList).toList(),
      childrenRow: pastSales.map((s) => s.itemAsList).toList(),
      onChecked: (bool? isChecked, row) =>
          _onChecked(sales, isChecked, row.first),
      onAllChecked:
          (
            bool isChecked,
            List<bool> isAllChecked,
            List<List<String>> checkedRows,
          ) {
            // if all unChecked, empty _groupReportsForPrintout List
            if (!isAllChecked.first) {
              setState(() => _groupReportsForPrintout.clear());
            }
            if (checkedRows.isNotEmpty) {
              for (int i = 0; i < checkedRows.length; i++) {
                final id = checkedRows[i].first;
                _onChecked(sales, isChecked, id);
              }
            }
          },
      optButtonLabel: 'Report',
      onOptButtonTap: (row) async => await _onReportTap(sales, row.first),
      onEditTap: (row) => _onEditTap(sales, row.first),
      onDeleteTap: (row) => _onDeleteTap(sales, row.first),
    );
  }

  _buildToolbar(List<POSSale> sales) {
    return AdaptiveLayout(
      isFormBuilder: false,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        context.actionInfoButton(
          'Refresh Sales',
          label: 'Sales',
          count: sales.length,
          onPressed: () {
            /// Refresh sales data
            context.read<POSSaleBloc>().add(RefreshPOSs<POSSale>());
          },
        ),
        // final orderBloc = context.read<OrdersBloc>();
        // final orderBloc = BlocProvider.of<OrdersBloc>(context, listen: false);
        const SizedBox(height: 20),
        _IssueMultiReportPrintout(
          sales: _groupReportsForPrintout,
          onDone: (s) => setState(() => _groupReportsForPrintout.clear()),
        ),
      ],
    );
  }

  /// Checks if there is any incomplete sales data within the given list of sales. [_hasIncompleteSalesData]
  ///
  /// This function evaluates a list of [Sale] objects to determine if any of them
  /// have incomplete data. It returns a tuple indicating whether there is incomplete
  /// data and, if so, the invoice number associated with the incomplete sale.
  ({bool isIncomplete, String incompleteReceiptNo}) _hasIncompleteSalesData(
    List<POSSale> selectedSales,
  ) {
    if (selectedSales.isEmpty) {
      return (isIncomplete: true, incompleteReceiptNo: ''); // Handle empty list
    }

    String receiptNumber = '';

    // Check if any sale has incomplete data
    var hasIncompleteData = selectedSales.any((sale) {
      receiptNumber = sale.receiptNumber;

      return !sale.isDataComplete();
    });

    return (
      isIncomplete: hasIncompleteData,
      incompleteReceiptNo: receiptNumber,
    );
  }

  // Handle onChecked orders
  void _onChecked(List<POSSale> sales, bool? isChecked, String id) async {
    setState(() {
      final sale = sales.firstWhere((order) => order.id == id);

      if (isChecked != null && isChecked) {
        // A temporary list, tempOrdersForInvoice, is created which includes
        // the current orders in _ordersForInvoice and the new sale to be checked.
        List<POSSale> tempSalesReport = List.from(_groupReportsForPrintout)
          ..add(sale);

        ({bool isIncomplete, String incompleteReceiptNo}) r =
            _hasIncompleteSalesData(tempSalesReport);

        if (r.isIncomplete) {
          context.incompleteSalesDataWarningDialog(r.incompleteReceiptNo);
        } else {
          _groupReportsForPrintout.add(sale);
        }
      } else {
        _groupReportsForPrintout.remove(sale);
      }
    });
  }

  _onReportTap(List<POSSale> orders, String id) async {
    // Show progress dialog while loading data
    await context.progressBarDialog(
      request: _printout(orders, id),
      onSuccess: (_) => context.showAlertOverlay('Report successfully created'),
      onError: (error) => context.showAlertOverlay(
        'Report printout failed',
        bgColor: kDangerColor,
      ),
    );
  }

  Future<dynamic> _printout(List<POSSale> sales, String id) =>
      Future.delayed(kRProgressDelay, () async {
        // Simulate loading supplier and company info
        final getSales = POSSale.findSaleById(sales, saleId: id).toList();

        if (mounted && getSales.isNotEmpty) {
          POSReportPrinter(
            sales: getSales,
            storeNumber: context.employee!.storeNumber,
          ).printReport();
        }
      });

  Future<void> _onEditTap(List<POSSale> sales, String id) async {
    {
      final sale = POSSale.findSaleById(sales, saleId: id).first;

      return context.openUpdatePOSSale(sale: sale);
    }
  }

  Future<void> _onDeleteTap(List<POSSale> sales, String id) async {
    final sale = POSSale.findSaleById(sales, saleId: id).first;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Remove sale from Sales-list
      context.read<POSSaleBloc>().add(DeletePOS<String>(documentId: sale.id));
    }
  }

  // Function to map Sale object to its respective row data
  /*List mapSalesToRows(List<Sale> salesList) {
     return salesList.map((Sale s) async {
      final product = await GetProducts.byProductId(s.productId);
      final f = GetProducts.byProductId(s.productId).asStream().map<double>((s)=>s.costPrice);

      // Calculate profit for each sale item
      final profit = s.calculateProfit(product.costPrice);
      // Create a list representing the sale item with profit appended
      List<dynamic> r = s.itemAsList();
      r.add(profit.toString());

      r= rowData;
    }).toList();
  }*/
}

/// Print grouped or multiple Sales Report [_IssueMultiInvoicePrintout]
class _IssueMultiReportPrintout extends StatelessWidget {
  final List<POSSale> sales;
  final Function(bool) onDone;

  const _IssueMultiReportPrintout({required this.sales, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return sales.isEmpty
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
        POSReportPrinter(
          sales: sales,
          storeNumber: context.employee!.storeNumber,
        ).printReport();
      },
      label: const Text('Report', style: TextStyle(color: kWarningColor)),
    );
  }

  Future<bool> _confirmDeleteDialog(BuildContext context) async {
    return context.confirmAction<bool>(
      const Text('Are you sure you want to delete the selected sales?'),
      title: "Confirm Delete",
      onAcceptLabel: "Delete",
      onRejectLabel: "Cancel",
    );
  }

  _buildDeleteButton(BuildContext context) {
    return context.elevatedIconBtn(
      Icon(Icons.delete, color: kWhiteColor),
      style: OutlinedButton.styleFrom(backgroundColor: context.errorColor),
      onPressed: () async {
        final isConfirmed = await _confirmDeleteDialog(context);
        if (context.mounted && isConfirmed) {
          final ids = sales.map((s) => s.id).toList();

          // Remove order from Orders-DB
          POSSaleBloc(
            firestore: FirebaseFirestore.instance,
          ).add(DeletePOS<List<String>>(documentId: ids));

          // Check if totalDeleted isEqual to total orders,
          // is so, then deletion completed
          onDone(true);

          /* int totalDeleted = 0;
            totalDeleted++;
            for (var sale in sales) {}
            if (totalDeleted == sales.length) {
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
              text: 'Sales Reports will be organized by date on the printout.',
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
