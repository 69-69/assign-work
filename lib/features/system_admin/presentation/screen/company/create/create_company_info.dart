import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:assign_erp/features/system_admin/data/models/company_model.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/company_form_inputs.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/upload_company_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AddCompanyInfo<T> on BuildContext {
  Future<void> openAddCompanyInfo() => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: 'Company Setup',
      body: _AddCompanyInfoForm(),
    ),
  );
}

class _AddCompanyInfoForm extends StatefulWidget {
  const _AddCompanyInfoForm();

  @override
  State<_AddCompanyInfoForm> createState() => _AddCompanyInfoFormState();
}

class _AddCompanyInfoFormState extends State<_AddCompanyInfoForm> {
  bool _isSubmitting = false;
  String _uploadedLogoPath = '';
  final _companyInfo = <Company>[];
  final _addresses = <AddressInfo>[];
  final _formKey = GlobalKey<FormState>();

  Employee? get _employee => context.employee;
  bool get _isFormValid => _formKey.currentState!.validate();
  final PrintSetupCacheService _printoutService = PrintSetupCacheService();

  // Construct Company Info Object
  Company get _info => Company.create(
    logo: _uploadedLogoPath,
    company: _companyInfo.first,
    addresses: List.from(_addresses),
    createdBy: _employee!.fullName,
    history: [
      AuditLog(
        action: AuditAction.created,
        actionBy: _employee!.employeeId,
        statusAfterAction: AuditAction.unknown.getName,
      ),
    ],
  );

  void _onSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    if (!_isFormValid || _info.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    context.read<CompanyBloc>().add(AddSetup<Company>(data: _info));
    await _saveToCache();
  }

  // Save Company-info to cache
  Future<void> _saveToCache() async {
    final company = _companyInfo.first;

    final settings = (await _printoutService.getSettings())?.copyWith(
      companyLogo: _uploadedLogoPath,
      companyName: company.name,
      companyEmail: company.email,
      companyPhone: '${company.phone} | ${company.altPhone}',
      companyFax: company.faxNumber,
      companyAddresses: _addresses.map((e) => e.toMap()).toList(),
    );
    if (settings != null) {
      await _printoutService.setSettings(settings);
    }
  }

  void _resetForm() {
    setState(() {
      _isSubmitting = false;
      _formKey.currentState!.reset();
      _uploadedLogoPath = '';
      _companyInfo.clear();
      _addresses.clear();
    });
    Navigator.pop(context);
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => _resetForm());
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<Company> state) {
    switch (state) {
      case SetupAdded<Company>(message: var msg):
        _showAlert(msg ?? 'Info saved successfully');
      case SetupError<Company>():
        _showAlert('Error saving changes');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyBloc, SetupState<Company>>(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: _buildBody(context),
      ),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FormGroupCard(
          title: 'Company Information',
          subTitle: '\nEnter your company information to complete setup.',
          children: [_buildCompanyInfo()],
        ),
        FormGroupCard(
          title: 'Addresses',
          subTitle:
              '\nYou can add multiple addresses: Office, Billing, Shipping, etc.',
          children: [
            _buildAddresses(),
            const SizedBox(height: 20.0),
            UploadCompanyLogo(
              uploadedFilePath: (s) {
                setState(() => _uploadedLogoPath = s);
              },
            ),
          ],
        ),

        context.confirmableActionButton(
          label: _isSubmitting ? 'Creating...' : 'Create Info',
          isDisabled: _isSubmitting,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  DynamicTextFields _buildCompanyInfo() {
    return DynamicTextFields(
      initialData: [{}],
      fieldsConfig: CompanyFormInputs.companyFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        // Update the ProLineItem list
        CompanyFormInputs.updateListFromData<Company>(
          _companyInfo,
          map: data,
          fromMap: (map, id) => Company.fromMap(map, id: id),
        );
      },
    );
  }

  // Addresses (e.g., Office, Billing, Shipping Address)
  DynamicTextFields _buildAddresses() {
    return DynamicTextFields(
      showButton: true,
      initialData: [{}],
      fieldsConfig: CompanyFormInputs.addressFields(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        // Update the address list
        CompanyFormInputs.updateListFromData<AddressInfo>(
          _addresses,
          map: data,
          fromMap: (map, id) => AddressInfo.fromMap(map, id: id),
        );
      },
    );
  }
}

/*FormGroupCard(
          title: 'Company Info',
          children: [
            CompanyNameAndEmailInput(
              nameController: _nameController,
              emailController: _emailController,
              onNameChanged: (s) {
                if (_formKey.currentState!.validate()) setState(() {});
              },
              onEmailChanged: (s) => setState(() {}),
            ),
            const SizedBox(height: 20.0),
            PhoneAndAltPhoneInput(
              phoneController: _phoneController,
              altPhoneController: _altPhoneController,
              onPhoneChanged: (s) {
                if (_formKey.currentState!.validate()) setState(() {});
              },
              onAltPhoneChanged: (s) => setState(() {}),
            ),
            const SizedBox(height: 20.0),
            FaxAndAddressTextField(
              addressController: _addressController,
              faxController: _faxNumberController,
              onFaxChanged: (s) => setState(() {}),
              onAddressChanged: (s) => setState(() {}),
            ),
            const SizedBox(height: 20.0),
            UploadCompanyLogo(
              uploadedFilePath: (s) {
                setState(() => _uploadedLogoPath = s);
              },
            ),
            const SizedBox(height: 20.0),
          ],
        ),*/
