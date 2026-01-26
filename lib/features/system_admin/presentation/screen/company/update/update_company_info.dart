import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
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

extension UpdateCompanyInfo on BuildContext {
  Future<void> openUpdateCompanyInfo({required Company serverInfo}) =>
      openBottomSheet(
        isExpand: false,
        child: BottomSheetScaffold(
          title: 'Edit Company Info',
          subtitle: serverInfo.name.toTitle,
          body: _UpdateCompanyForm(serverInfo: serverInfo),
        ),
      );
}

class _UpdateCompanyForm extends StatefulWidget {
  final Company serverInfo;

  const _UpdateCompanyForm({required this.serverInfo});

  @override
  State<_UpdateCompanyForm> createState() => _UpdateCompanyFormState();
}

class _UpdateCompanyFormState extends State<_UpdateCompanyForm> {
  bool _isSubmitting = false;
  final _companyInfo = <Company>[];
  final _addresses = <AddressInfo>[];
  final _formKey = GlobalKey<FormState>();
  late String? _uploadedLogoPath = _serverInfo.logo;
  bool get isFormValid => _formKey.currentState?.validate() ?? false;
  final PrintSetupCacheService _printoutService = PrintSetupCacheService();

  Employee? get _employee => context.employee;
  Company get _serverInfo => widget.serverInfo;

  @override
  void initState() {
    _addresses.addAll(_serverInfo.addresses);
    _companyInfo.add(_serverInfo);
    super.initState();
  }

  /// Construct the updated company info
  Company get _updatedCompany {
    final company = _companyInfo.first;

    return _serverInfo.copyWith(
      logo: _uploadedLogoPath,
      name: company.name,
      email: company.email,
      phone: company.phone,
      altPhone: company.altPhone,
      faxNumber: company.faxNumber,
      addresses: List.from(_addresses),
      updatedBy: _employee!.fullName,
      history: [
        AuditLog(
          action: AuditAction.updated,
          actionBy: _employee!.employeeId,
          statusAfterAction: AuditAction.updated.getName,
        ),
      ],
    );
  }

  void _onSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    if (!isFormValid || _addresses.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    context.read<CompanyBloc>().add(
      UpdateSetup<Company>(documentId: _serverInfo.id, data: _updatedCompany),
    );
    await _saveToCache();
  }

  // Update Company-info to cache
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
      prettyPrint('_addresses-2', _addresses);
      await _printoutService.setSettings(settings);
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => Navigator.pop(context));
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<Company> state) {
    switch (state) {
      case SetupUpdated<Company>(message: var msg):
        _showAlert(msg ?? 'Changes saved');
      case SetupError<Company>():
        _showAlert('Something went wrong! Please, try again');
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

  Widget _buildBody(BuildContext context) {
    return FormGroupTabView(
      contents: formGroupCards,
      footers: [
        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          onPressed: _onSubmit,
          isDisabled: _isSubmitting,
          label: _isSubmitting ? 'Updating...' : null,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  List<Map<String, dynamic>> get formGroupCards => [
    {
      'title': 'Company Information',
      'subTitle': '\nEnter your company information to complete setup.',
      'children': [_buildCompanyInfo()],
    },
    {
      'title': 'Addresses',
      'subTitle':
          '\nYou can add multiple addresses: Office, Billing, Shipping, etc.',
      'children': [
        _buildAddresses(),
        const SizedBox(height: 20.0),
        UploadCompanyLogo(
          serverFilePath: _serverInfo.logo,
          uploadedFilePath: (s) {
            setState(() => _uploadedLogoPath = s);
          },
        ),
      ],
    },
  ];

  DynamicTextFields _buildCompanyInfo() {
    return DynamicTextFields(
      initialData: [_serverInfo.toMap()],
      fieldsConfig: CompanyFormInputs.companyFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

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
      initialData: _serverInfo.addresses.map((e) => e.toMap()).toList(),
      fieldsConfig: CompanyFormInputs.addressFields(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

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
