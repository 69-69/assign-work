import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/contact_person_model.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/form/business_to_industries_dropdown.dart';
import 'package:assign_erp/core/widgets/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_vendor/suppliers_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AddSuppliers on BuildContext {
  Future openAddSuppliers({Widget? header}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: 'Add Supplier',
      body: _AddSuppliersForm(),
    ),
  );
}

class _AddSuppliersForm extends StatefulWidget {
  const _AddSuppliersForm();

  @override
  State<_AddSuppliersForm> createState() => _AddSuppliersFormState();
}

class _AddSuppliersFormState extends State<_AddSuppliersForm> {
  final _formKey = GlobalKey<FormState>();
  final List<Supplier> _suppliers = [];
  final List<ContactPerson> _contactPersons = [];

  String get _employeeName => context.employee!.fullName;
  bool get isFormValid => _formKey.currentState!.validate();

  @override
  void dispose() {
    super.dispose();
  }

  /*Supplier get _supplierData {
    final supplier = _suppliers.first;

    return Supplier(
      code: supplier.code,
      name: supplier.name,
      phone: supplier.phone,
      email: supplier.email,
      address: supplier.address,
      items: supplier.items,
      businessType: supplier.businessType,
      bankDetails: supplier.bankDetails,
      taxDetails: supplier.taxDetails,
      contactPersons: List.from(_contactPersons),
      createdBy: context.employee?.fullName ?? 'unknown',
    );
  }*/

  Supplier _prepareNewSupplier() {
    final supplier = _suppliers.first;

    // Append supplier-code & contact person names
    return supplier.copyWith(
      code: supplier.name.generateUniqueCode(),
      contactPersons: List.from(_contactPersons),
      createdBy: _employeeName,
    );
  }

  void _onSubmit() {
    if (!isFormValid || _suppliers.isEmpty || _contactPersons.isEmpty) {
      context.showAlertOverlay(
        'Please fill in all required fields',
        bgColor: kDangerColor,
      );
      return;
    }
    final newSupplier = _prepareNewSupplier();
    context.read<SupplierBloc>().add(
      AddProcurement<Supplier>(data: newSupplier),
    );

    context.showAlertOverlay(
      'Stores successfully created',
      popContext: () => _resetForm(),
    );
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _suppliers.clear();
      _contactPersons.clear();
    });
    Navigator.pop(context);
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
              initialData: [{}],
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
              initialData: [{}],
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

        context.confirmableActionButton(
          label: 'Create Supplier',
          onPressed: _onSubmit,
        ),
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
        return BusinessToIndustriesDropdown(
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
