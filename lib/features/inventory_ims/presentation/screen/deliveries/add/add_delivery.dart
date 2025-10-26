import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/barcode_scanner.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/customer_crm/data/data_sources/remote/get_customers.dart';
import 'package:assign_erp/features/inventory_ims/data/data_sources/remote/get_orders.dart';
import 'package:assign_erp/features/inventory_ims/data/models/delivery_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/delivery/delivery_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/deliveries/widget/form_inputs.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/sales_doc_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AddDelivery on BuildContext {
  Future<void> openAddDelivery({Widget? header}) => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(title: 'Add Delivery', body: _AddDeliveryBody()),
  );
}

class _AddDeliveryBody extends StatefulWidget {
  const _AddDeliveryBody();

  @override
  State<_AddDeliveryBody> createState() => _AddDeliveryBodyState();
}

class _AddDeliveryBodyState extends State<_AddDeliveryBody> {
  String _selectedOrderNumber = '';
  String? _selectedDeliveryStatus;
  String? _selectedDeliveryType;

  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _deliveryPersonController = TextEditingController();
  final _deliveryPhoneController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  void dispose() {
    _deliveryPhoneController.dispose();
    _deliveryPersonController.dispose();
    _barcodeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final item = Delivery(
        orderNumber: _selectedOrderNumber,
        barcode: _barcodeController.text,
        status: _selectedDeliveryStatus ?? '',
        deliveryType: _selectedDeliveryType ?? '',
        deliveryPhone: _selectedDeliveryStatus ?? '',
        deliveryPerson: _deliveryPersonController.text,
        remarks: _remarksController.text,

        storeNumber: context.employee!.storeNumber,
        createdBy: context.employee!.fullName,
      );

      context.read<DeliveryBloc>().add(AddInventory<Delivery>(data: item));

      _formKey.currentState!.reset();

      _confirmPrintoutDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(context),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 20.0),
        OrderNumberDropdown(
          onChanged: (orderNumber, itemName) =>
              setState(() => _selectedOrderNumber = orderNumber),
        ),
        const SizedBox(height: 20.0),
        DeliveryStatusAndTypesDropdown(
          onTypeChange: (t) => setState(() => _selectedDeliveryType = t),
          onStatusChange: (s) => setState(() => _selectedDeliveryStatus = s),
        ),
        const SizedBox(height: 20.0),
        DeliveryPersonAndPhoneInput(
          deliveryPersonController: _deliveryPersonController,
          deliveryPhoneController: _deliveryPhoneController,
        ),
        const SizedBox(height: 20.0),
        RemarksTextField(controller: _remarksController),
        const SizedBox(height: 20.0),
        BarcodeScannerWithTextField(
          controller: _barcodeController,
          onChanged: (t) => setState(() {}),
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          label: 'Add Delivery',
          onPressed: _onSubmit,
        ),
      ],
    );
  }

  Future<void> _confirmPrintoutDialog() async {
    final isConfirmed = await context.confirmAction<bool>(
      const Text('Would you like to print the Invoice & Way-bill?'),
      title: "Invoice & Way-Bill",
      onAcceptLabel: "Print",
      onRejectLabel: "Cancel",
    );

    if (mounted && isConfirmed) {
      // Show progress dialog while loading data
      await context.progressBarDialog(
        request: _printout(),
        onSuccess: (_) =>
            context.showAlertOverlay('Delivery successfully created'),
        onError: (error) => context.showAlertOverlay(
          'Invoice & Way-Bill printout failed: $error',
          bgColor: kDangerColor,
        ),
      );
    }
  }

  Future<dynamic> _printout() => Future.delayed(kRProgressDelay, () async {
    // Simulate loading supplier and company info
    final orders = await GetOrders.getWithSameId(_selectedOrderNumber);
    final cus = await GetAllCustomers.byCustomerId(orders.first.customerId);
    if (orders.isNotEmpty && cus.isNotEmpty) {
      SalesDocPrinter(
        orders: orders,
        customer: cus,
      ).printDoc(title: 'delivery note');
    }
  });
}
