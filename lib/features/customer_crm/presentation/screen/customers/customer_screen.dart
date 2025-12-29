import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/customer_crm/data/models/customer_model.dart';
import 'package:assign_erp/features/customer_crm/presentation/bloc/create_acc/customer_acc_bloc.dart';
import 'package:assign_erp/features/customer_crm/presentation/bloc/customer_bloc.dart';
import 'package:assign_erp/features/customer_crm/presentation/screen/customers/create/create_customer.dart';
import 'package:assign_erp/features/customer_crm/presentation/screen/customers/list/list_customers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerScreen extends StatelessWidget {
  final String openTab;

  const CustomerScreen({super.key, this.openTab = '0'});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CustomerAccountBloc>(
      create: (context) =>
          CustomerAccountBloc(firestore: FirebaseFirestore.instance)
            ..add(GetCustomers<Customer>()),
      child: CustomScaffold(
        title: customersScreenTitle.toUpperAll,
        body: _buildBody(),
        actions: const [],
        floatingActionButton: context.buildFloatingBtn(
          'create customer account',
          onPressed: () => context.openAddCustomer(),
        ),
      ),
    );
  }

  CustomTab _buildBody() {
    final openThisTab = int.tryParse(openTab) ?? 0;

    return CustomTab(
      openThisTab: openThisTab,
      length: 3,
      tabs: [
        CustomTabModel(label: 'Customers', icon: Icons.group),
        CustomTabModel(label: 'Activities', icon: Icons.account_tree),
        CustomTabModel(
          label: 'Statement of Account',
          icon: Icons.pending_actions,
        ),
      ],
      children: const [
        ListCustomers(),
        Center(child: Text('Activities')),
        Center(
          child: Text(
            'Statement of Account'
            '| Date         | Type           | Ref #     | Debit    | Credit    | Balance    |\n'
            '| --------------- | ----------------- | ------------ | ----------- | ------------ | ------------- |\n'
            '| 01-Jan-25       | Opening Bal       |              |             |        | 1,000   |\n'
            '| 05-Jan-25       | Invoice           | INV001       | 500         |        | 1,500   |\n'
            '| 10-Jan-25       | Payment           | PAY001       |             | 300    | 1,200   |\n'
            '| 15-Jan-25       | Credit Note       | CN001        |             | 50     | 1,150   |\n'
            '| 31-Jan-25       | Closing Bal       |              |             |        | 1,150   |\n'
            '| 01-Feb-25       | Opening Bal       |              |             |        | 1,150   |\n',
          ),
        ),
      ],
    );
  }
}

/*1. Purpose of a Statement of Account
Shows all transactions between your company and a customer
Helps the customer reconcile their accounts
Used internally to track outstanding balances, payments, and credits

| Section                    | Details                                                                                 |
| -------------------------- | --------------------------------------------------------------------------------------- |
| Customer Information       | Customer ID, Name, Billing Address, Contact info                                        |
| Statement Period           | Start Date, End Date                                                                    |
| Opening Balance            | Amount carried forward from previous period                                             |
| Invoices                   | List of invoices issued, with: <br>• Invoice Number<br>• Date<br>• Amount<br>• Due Date |
| Credit Notes / Adjustments | Any returns, discounts, or corrections applied                                          |
| Payments Received          | List of payments made, with date and amount                                             |
| Closing Balance            | Outstanding amount at end of period                                                     |
| Aging Summary (optional)   | Categorizes unpaid amounts by period (e.g., 0–30, 31–60 days)                           |

Example Statement of Account
| Date      | Type        | Ref #  | Debit | Credit | Balance |
| --------- | ----------- | ------ | ----- | ------ | ------- |
| 01-Jan-25 | Opening Bal |        |       |        | 1,000   |
| 05-Jan-25 | Invoice     | INV001 | 500   |        | 1,500   |
| 10-Jan-25 | Payment     | PAY001 |       | 300    | 1,200   |
| 15-Jan-25 | Credit Note | CN001  |       | 50     | 1,150   |
| 31-Jan-25 | Closing Bal |        |       |        | 1,150   |


void main() {
  var soa = StatementOfAccount(
    customerId: "CUST001",
    customerName: "ABC Corp",
    billingAddress: "123 Main St, City",
    periodStart: DateTime(2025, 1, 1),
    periodEnd: DateTime(2025, 1, 31),
    openingBalance: 1000,
    transactions: [
      AccountTransaction(
          date: DateTime(2025, 1, 5),
          type: "Invoice",
          referenceNumber: "INV001",
          debit: 500),
      AccountTransaction(
          date: DateTime(2025, 1, 10),
          type: "Payment",
          referenceNumber: "PAY001",
          credit: 300),
      AccountTransaction(
          date: DateTime(2025, 1, 15),
          type: "CreditNote",
          referenceNumber: "CN001",
          credit: 50),
    ],
  );

  print("Closing Balance: ${soa.closingBalance}"); // 1150
}
*/

class StatementOfAccount {
  /// Customer Information
  final String customerId;
  final String customerName;

  /// Statement Period
  final DateTime periodStart;
  final DateTime periodEnd;

  /// Opening and Closing Balances
  final double openingBalance;
  double closingBalance;

  /// Transactions
  final List<AccountTransaction> transactions;

  StatementOfAccount({
    required this.customerId,
    required this.customerName,
    required this.periodStart,
    required this.periodEnd,
    required this.openingBalance,
    this.closingBalance = 0,
    required this.transactions,
  }) {
    // Calculate closing balance automatically
    closingBalance = _calculateClosingBalance();
  }

  double _calculateClosingBalance() {
    double balance = openingBalance;
    for (var txn in transactions) {
      balance += txn.debit - txn.credit;
    }
    return balance;
  }
}

class AccountTransaction {
  final DateTime date;
  final String type; // "Invoice", "Payment", "CreditNote"
  final String referenceNumber;
  final double debit; // Amount billed
  final double credit; // Amount paid / credited

  AccountTransaction({
    required this.date,
    required this.type,
    required this.referenceNumber,
    this.debit = 0,
    this.credit = 0,
  });
}
