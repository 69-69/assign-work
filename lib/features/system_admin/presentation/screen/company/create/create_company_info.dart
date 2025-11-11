import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/form_group_card.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:assign_erp/features/system_admin/data/models/company_info_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/form_inputs.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/upload_company_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AddCompanyInfo<T> on BuildContext {
  Future<void> openAddCompanyInfo({Widget? header}) => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(title: 'Setup Company', body: _AddCompanyInfoForm()),
  );
}

class _AddCompanyInfoForm extends StatefulWidget {
  const _AddCompanyInfoForm();

  @override
  State<_AddCompanyInfoForm> createState() => _AddCompanyInfoFormState();
}

class _AddCompanyInfoFormState extends State<_AddCompanyInfoForm> {
  String _uploadedLogoPath = '';
  final PrintoutSetupCacheService _printoutService =
      PrintoutSetupCacheService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _faxNumberController = TextEditingController();
  final _addressController = TextEditingController();

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
      /// Add Company Info
      final item = Company(
        name: _nameController.text,
        logo: _uploadedLogoPath,
        email: _emailController.text,
        phone: _phoneController.text,
        altPhone: _altPhoneController.text,
        address: _addressController.text,
        faxNumber: _faxNumberController.text,
        createdBy: context.employee!.fullName,
      );

      context.read<CompanyBloc>().add(AddSetup<Company>(data: item));
      await _saveToCache();

      _formKey.currentState!.reset();

      if (mounted) {
        context.showAlertOverlay(
          '${_nameController.text.toTitle} successfully created',
        );
        Navigator.pop(context);
      }
    }
  }

  // Save Company-info to cache
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
        FormGroupCard(
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
        ),
        context.confirmableActionButton(
          label: 'Create Info',
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}
