import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/barcode_scanner.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/models/delivery_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/delivery/delivery_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/deliveries/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateDeliveryForm on BuildContext {
  Future<void> openUpdateDelivery({required Delivery delivery}) =>
      openBottomSheet(
        isExpand: false,
        child: BottomSheetScaffold(
          title: 'Edit Delivery',
          body: _UpdateDeliveryBody(delivery: delivery),
        ),
      );
}

class _UpdateDeliveryBody extends StatefulWidget {
  final Delivery delivery;

  const _UpdateDeliveryBody({required this.delivery});

  @override
  State<_UpdateDeliveryBody> createState() => _UpdateDeliveryBodyState();
}

class _UpdateDeliveryBodyState extends State<_UpdateDeliveryBody> {
  Delivery get _delivery => widget.delivery;

  String? _selectedOrderNumber;
  String? _selectedDeliveryStatus;
  String? _selectedDeliveryType;

  final _formKey = GlobalKey<FormState>();

  late final _barcodeController = TextEditingController(
    text: _delivery.barcode,
  );
  late final _deliveryPersonController = TextEditingController(
    text: _delivery.deliveryPerson,
  );
  late final _deliveryPhoneController = TextEditingController(
    text: _delivery.deliveryPhone,
  );
  late final _remarksController = TextEditingController(
    text: _delivery.remarks,
  );

  @override
  void dispose() {
    _deliveryPersonController.dispose();
    _barcodeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final item = _delivery.copyWith(
        orderNumber: _selectedOrderNumber ?? _delivery.orderNumber,
        barcode: _barcodeController.text,
        deliveryPhone: _deliveryPhoneController.text,
        deliveryPerson: _deliveryPersonController.text,
        status: _selectedDeliveryStatus ?? _delivery.status,
        deliveryType: _selectedDeliveryType ?? _delivery.deliveryType,
        remarks: _remarksController.text,
        storeNumber: _delivery.storeNumber,
        createdBy: _delivery.createdBy,
        updatedBy: context.employee!.fullName,
      );

      /// Update Delivery
      context.read<DeliveryBloc>().add(
        UpdateInventory<Delivery>(documentId: _delivery.id, data: item),
      );

      _isDelivered(_selectedDeliveryStatus);

      context.showAlertOverlay('Delivery successfully updated');

      Navigator.pop(context);
    }
  }

  /// Update Delivery Status
  void _updateStatus(status) {
    _delivery.copyWith(status: status);
    setState(() => _selectedDeliveryStatus = status);

    /// Update Delivery Status
    context.read<DeliveryBloc>().add(
      UpdateInventory<Delivery>(
        documentId: _delivery.id,
        mapData: {'status': status},
      ),
    );

    _isDelivered(status);

    context.showAlertOverlay('Changes saved');
  }

  /// Update OrderStatus & record new Sales once the order(s) have been successfully delivered
  void _isDelivered(status) {
    if (status == 'delivered' && _delivery.orderNumber.isNotEmpty) {
      context.read<DeliveryBloc>().isDelivered(_delivery.orderNumber);
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
        Text('Update Delivery Status', style: context.textTheme.titleLarge),
        const SizedBox(height: 10.0),
        DeliveryStatusDropdown(
          initialStatus: _delivery.status,
          onChanged: (s) => _updateStatus(s),
        ),
        HorizontalDivider(thickness: 8.0),
        _formBody(),
      ],
    );
  }

  ExpansionTile _formBody() {
    return ExpansionTile(
      dense: true,
      title: Text(
        'Modify this Delivery',
        textAlign: TextAlign.center,
        style: context.textTheme.titleLarge,
      ),
      subtitle: Text(
        'ID ${_delivery.id}'.toUpperAll,
        textAlign: TextAlign.center,
      ),
      childrenPadding: const EdgeInsets.only(bottom: 20.0),
      children: [
        const SizedBox(height: 20),
        OrderNumberDropdown(
          initialValue: _delivery.orderNumber,
          onChanged: (orderNumber, itemName) =>
              setState(() => _selectedOrderNumber = orderNumber),
        ),
        const SizedBox(height: 20),
        DeliveryStatusAndTypesDropdown(
          initialStatus: _delivery.status,
          initialType: _delivery.deliveryType,
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
        context.confirmableActionButton(onPressed: _onSubmit),
      ],
    );
  }
}
