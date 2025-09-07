import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:assign_erp/features/system_admin/data/models/company_info_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/form_inputs.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/upload_company_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateCompanyInfo<T> on BuildContext {
  Future<void> openUpdateCompanyInfo({required Company info}) =>
      openBottomSheet(
        isExpand: false,
        child: FormBottomSheet(
          title: 'Edit Company Info',
          subtitle: info.name.toTitle,
          body: _UpdateCompanyForm(info: info),
        ),
      );
}

class _UpdateCompanyForm extends StatefulWidget {
  final Company info;

  const _UpdateCompanyForm({required this.info});

  @override
  State<_UpdateCompanyForm> createState() => _UpdateCompanyFormState();
}

class _UpdateCompanyFormState extends State<_UpdateCompanyForm> {
  // final SetupPrintOut _setupPrintOut = SetupPrintOut();
  final PrintoutSetupCacheService _printoutService =
      PrintoutSetupCacheService();

  Company get _info => widget.info;
  late String? _uploadedLogoPath = _info.logo;

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: _info.name);
  late final _emailController = TextEditingController(text: _info.email);
  late final _phoneController = TextEditingController(text: _info.phone);
  late final _altPhoneController = TextEditingController(text: _info.altPhone);
  late final _faxNumberController = TextEditingController(
    text: _info.faxNumber,
  );
  late final _addressController = TextEditingController(text: _info.address);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _faxNumberController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      /// Update Company Info
      final item = _info.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        altPhone: _altPhoneController.text,
        address: _addressController.text,
        faxNumber: _faxNumberController.text,
        logo: _uploadedLogoPath ?? _info.logo,

        createdBy: _info.createdBy,
        updatedBy: context.employee!.fullName,
      );

      context.read<CompanyBloc>().add(
        UpdateSetup<Company>(documentId: _info.id, data: item),
      );

      await _saveToCache();

      if (mounted) {
        context.showAlertOverlay(
          '${_nameController.text.toTitle} successfully updated',
        );
        Navigator.pop(context);
      }
    }
  }

  // Update Company-info in cache
  Future<void> _saveToCache() async {
    final settings = (await _printoutService.getSettings())?.copyWith(
      companyLogo: _uploadedLogoPath,
      companyName: _nameController.text,
      companyEmail: _emailController.text,
      companyPhone: '${_phoneController.text} | ${_altPhoneController.text}',
      companyAddress: _addressController.text,
      companyFax: _faxNumberController.text,
    );
    if (settings != null) {
      await _printoutService.setSettings(settings);
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
          serverFilePath: _info.logo,
          uploadedFilePath: (s) {
            setState(() => _uploadedLogoPath = s);
          },
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(onPressed: _onSubmit),
      ],
    );
  }
}
