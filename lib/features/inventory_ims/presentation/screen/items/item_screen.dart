import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/item/item_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/items/create/create_item.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/items/list_stocks/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  // String _barcodeValue = '';

  // bool isScanCompleted = false;
  ItemBloc _initializeProductBloc(BuildContext context) {
    final productBloc = ItemBloc(firestore: FirebaseFirestore.instance);
    productBloc.add(GetInventories<Item>());
    return productBloc;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ItemBloc>(
      create: _initializeProductBloc,
      child: CustomScaffold(
        title: stocksScreenTitle.toUpperAll,
        body: _buildBody(),
        floatingActionButton: context.buildFloatingBtn(
          'Create Stock',
          onPressed: () => context.openAddItem(),
        ),
      ),
    );
  }

  _buildBody() {
    return CustomTab(
      length: 4,
      tabs: [
        CustomTabModel(label: 'Products', icon: Icons.line_style),
        CustomTabModel(label: 'Expired', icon: Icons.date_range),
        CustomTabModel(
          label: 'Stock Level',
          icon: Icons.dashboard_customize_outlined,
        ),
        CustomTabModel(
          label: 'Out-Stock',
          icon: Icons.space_dashboard_outlined,
        ),
      ],
      children: [
        ListProducts(),
        ListExpired(),
        ListStockLevel(),
        Center(
          child: Text(
            'Replace Out-Stock with "(Sales): Update Historical sales data for forecasting"',
          ),
        ),
      ],
    );
  }

  /*BarcodeScanner _buildBarcodeScanner() {
    return BarcodeScanner(
      childWidget: (void Function()? scanFunction, List<Barcode> barcodes) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted && barcodes.isNotEmpty) {
            setState(() => _barcodeValue = barcodes.first.displayValue);
          }
        });
        return FloatingActionButton(
          onPressed: scanFunction,
          tooltip: 'Scan Product',
          child: const Icon(Icons.qr_code_scanner),
        );
      },
    );
  }*/
}
