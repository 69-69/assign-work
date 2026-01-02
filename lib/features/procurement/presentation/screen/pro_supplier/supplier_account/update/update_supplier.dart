import 'package:assign_erp/core/network/data_sources/models/contact_person_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/form/business_to_industries_dropdown.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_vendor/suppliers_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/system_admin/data/models/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateSupplier on BuildContext {
  Future openUpdateSupplier({required Supplier supplier}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: 'Edit Supplier',
      subtitle: supplier.name.toTitle,
      body: _UpdateSupplierForm(supplier: supplier),
    ),
  );
}

class _UpdateSupplierForm extends StatefulWidget {
  final Supplier supplier;

  const _UpdateSupplierForm({required this.supplier});

  @override
  State<_UpdateSupplierForm> createState() => _UpdateSupplierFormState();
}

class _UpdateSupplierFormState extends State<_UpdateSupplierForm> {
  Supplier get _serverSupplier => widget.supplier;

  final _formKey = GlobalKey<FormState>();
  final List<Supplier> _suppliers = [];
  final List<ContactPerson> _contactPersons = [];

  bool get isFormValid => _formKey.currentState!.validate();

  @override
  void dispose() {
    super.dispose();
  }

  void _onSubmit() {
    if (_serverSupplier.isNotNullNorEmpty) {
      final updated = _prepareUpdatedSupplier();

      context.read<SupplierBloc>().add(
        UpdateProcurement<Supplier>(
          documentId: _serverSupplier.id,
          data: updated,
        ),
      );

      context.showAlertOverlay(
        'Changes successfully saved',
        onCallback: () => Navigator.pop(context),
      );
    }
  }

  Supplier _prepareUpdatedSupplier() {
    final supplier = _suppliers.first;

    return _serverSupplier.copyWith(
      name: supplier.name,
      phone: supplier.phone,
      email: supplier.email,
      address: supplier.address,
      items: supplier.items,
      businessType: supplier.businessType,
      bankDetails: supplier.bankDetails,
      taxDetails: supplier.taxDetails,
      contactPersons: List.from(_contactPersons),
      updatedBy: context.employee?.fullName ?? 'unknown',
    );
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
        FormGroupCard(
          children: [
            DynamicTextFields(
              title: 'Supplier (Vendor) Details',
              initialData: [_serverSupplier.toMap()],
              fieldsConfig: _supplierFieldConfig,
              onChanged: (List<Map<String, dynamic>> data) {
                if (isFormValid) setState(() {});

                _suppliers
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map((e) => Supplier.fromMap(e)));
              },
            ),
          ],
        ),
        FormGroupCard(
          children: [
            DynamicTextFields(
              title: 'Contact Person Details',
              initialData: _serverSupplier.contactPersons
                  .map((e) => e.toMap())
                  .toList(),
              showButton: true,
              fieldsConfig: _contactPersonFieldConfig,
              onChanged: (List<Map<String, dynamic>> data) {
                if (isFormValid) setState(() {});

                _contactPersons
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(
                    data.asMap().entries.map((e) {
                      final index = (e.key) + 1;
                      final contactPerson = e.value;
                      return ContactPerson.fromMap(
                        contactPerson,
                        id: index.toString(),
                      );
                    }),
                  );
              },
            ),
          ],
        ),

        context.confirmableActionButton(onPressed: _onSubmit),
        const SizedBox(height: 20.0),
      ],
    );
  }

  final _supplierFieldConfig = [
    FieldGroupConfig(
      key: 'name',
      label: 'Company Name',
      type: TextInputType.text,
    ),
    FieldGroupConfig(
      key: 'email',
      label: 'Email',
      type: TextInputType.emailAddress,
    ),
    FieldGroupConfig(
      key: 'phone',
      label: 'Mobile Number',
      type: TextInputType.phone,
    ),
    FieldGroupConfig(
      key: 'businessType',
      label: 'Business type',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final parts = initialData?.toString().split('-') ?? [];

        final initialBusiness = parts.length >= 2 ? parts.first.trim() : '';
        final initialIndustry = parts.length >= 2 ? parts.last.trim() : '';

        return BusinessToIndustriesDropdown(
          initialBusiness: initialBusiness,
          initialIndustry: initialIndustry,
          onIndustryChanged: (String? business, String? industry) {
            if (business != null && industry != null) {
              onChanged('$business - $industry');
            }
          },
        );
      },
    ),
    FieldGroupConfig(
      key: 'address',
      label: 'Address info',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
    ),
    FieldGroupConfig(
      key: 'items',
      label: 'Products / services offered',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
    ),
    FieldGroupConfig(
      key: 'bankDetails',
      label: 'Bank Details',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      helperText:
          'Bank Name, Account Number, Account Holder Name, Swift Code, etc.',
    ),
    FieldGroupConfig(
      key: 'taxDetails',
      label: 'Tax Details',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      helperText: 'TIN or GST, etc.',
    ),
  ];

  final _contactPersonFieldConfig = [
    FieldGroupConfig(key: 'name', label: 'Name', type: TextInputType.text),
    FieldGroupConfig(
      key: 'email',
      label: 'Email',
      type: TextInputType.emailAddress,
    ),
    FieldGroupConfig(
      key: 'phone',
      label: 'Mobile Number',
      type: TextInputType.phone,
    ),
    FieldGroupConfig(
      key: 'position',
      label: 'Position',
      type: TextInputType.text,
      helperText: 'E.g., Manager, Procurement officer,...',
    ),
    FieldGroupConfig(
      key: 'department',
      label: 'Department',
      type: TextInputType.text,
      helperText: 'E.g., Sales, Purchasing,...',
    ),
  ];
}
