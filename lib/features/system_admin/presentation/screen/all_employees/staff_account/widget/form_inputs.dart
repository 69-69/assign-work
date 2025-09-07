import 'package:assign_erp/core/constants/account_status.dart';
import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/staff_account/widget/search_role.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/search_departments.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/search_stores.dart';
import 'package:flutter/material.dart';

/// FullName And Mobile number TextField [NameAndMobile]
class NameAndMobile extends StatelessWidget {
  const NameAndMobile({
    super.key,
    required this.mobileController,
    required this.nameController,
    this.onMobileChanged,
    this.onNameChanged,
  });

  final TextEditingController mobileController;
  final TextEditingController nameController;
  final ValueChanged? onMobileChanged;
  final ValueChanged? onNameChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextField(
          label: 'Full name',
          onChanged: onNameChanged,
          controller: nameController,
          keyboardType: TextInputType.name,
        ),
        CustomTextField(
          label: 'Mobile number',
          onChanged: onMobileChanged,
          controller: mobileController,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

/// Employee Roles [EmployeeRoleDropdown]
class EmployeeRoleDropdown extends StatelessWidget {
  const EmployeeRoleDropdown({
    super.key,
    required this.onRoleChanged,
    this.serverRole,
  });

  final Function(String?, String?) onRoleChanged;
  final String? serverRole;

  @override
  Widget build(BuildContext context) {
    return SearchRole(
      key: Key('key-emp-role'),
      initialValue: serverRole,
      onChanged: (id, role) => onRoleChanged(id, role),
    );
  }
}

/// Employee Temporal passCode & Email [EmailAndPasscode]
class EmailAndPasscode extends StatelessWidget {
  const EmailAndPasscode({
    super.key,
    required this.emailController,
    this.onEmailChanged,
    this.passcodeController,
    this.onPasscodeChanged,
  });

  final TextEditingController emailController;
  final ValueChanged? onEmailChanged;
  final TextEditingController? passcodeController;
  final Function(String?)? onPasscodeChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextField(
          label: 'Employee email',
          onChanged: onEmailChanged,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        if (passcodeController != null) ...{
          TemporaryPasscode(
            controller: passcodeController!,
            onChanged: onPasscodeChanged!,
          ),
        },
      ],
    );
  }
}

/// Passcode & Store locations Dropdown [StoreLocationsAndDepartment]
class StoreLocationsAndDepartment extends StatelessWidget {
  final Function(String, String) onStoresChange;
  final String? initialStore;
  final Function(String, String, String) onDepartChanged;
  final String? initialValue;

  const StoreLocationsAndDepartment({
    super.key,
    this.initialStore,
    this.initialValue,
    required this.onStoresChange,
    required this.onDepartChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DepartmentDropdown(
          initialValue: initialValue,
          onChanged: onDepartChanged,
        ),
        StoreLocationsDropdown(
          onChange: onStoresChange,
          initialValue: initialValue,
        ),
      ],
    );
  }
}

/// Generate Temporary Passcode [TemporaryPasscode]
/// Temporary passcode required during employee sign-in process,
/// after the organization's workspace sign-in.
class TemporaryPasscode extends StatefulWidget {
  const TemporaryPasscode({
    super.key,
    required this.onChanged,
    required this.controller,
  });

  final TextEditingController controller;
  final Function(String?) onChanged;

  @override
  State<TemporaryPasscode> createState() => _TemporaryPasscodeState();
}

class _TemporaryPasscodeState extends State<TemporaryPasscode> {
  bool _secureText = true;
  get _controller => widget.controller;
  get helperText =>
      'Generate temporary passcode for employee access to the organization\'s workspace.';

  void showHide() => setState(() => _secureText = !_secureText);

  @override
  void initState() {
    super.initState();
    _controller.text = _generateTemporaryPasscode();
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      key: const Key('temp_pass_code_textField'),
      controller: _controller,
      obscureText: _secureText,
      onChanged: widget.onChanged,
      maxLines: 1,
      maxLength: 20,
      autofillHints: const [AutofillHints.password],
      keyboardType: TextInputType.visiblePassword,
      inputDecoration: InputDecoration(
        isDense: true,
        alignLabelWithHint: true,
        prefixIcon: Icon(Icons.lock),
        labelText: 'Temporary Passcode',
        contentPadding: const EdgeInsets.all(1.0),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: FittedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _toggleVisibility(),
              const SizedBox(width: 4),
              _generateButton(context),
              const SizedBox(width: 4),
            ],
          ),
        ),
        helperText: helperText,
      ),
    );
  }

  Widget _generateButton(BuildContext context) {
    return context.elevatedButton(
      'Generate',
      tooltip: helperText,
      txtColor: kWhiteColor,
      bgColor: kDangerColor,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      onPressed: () => _controller.text = _generateTemporaryPasscode(),
    );
  }

  IconButton _toggleVisibility() {
    return IconButton(
      onPressed: showHide,
      icon: Icon(
        _secureText ? Icons.visibility_off : Icons.visibility,
        color: _secureText ? kGrayColor : kTextColor,
        semanticLabel: 'visibility icon',
      ),
    );
  }

  /// Generates a new Temporary passcode prefixed with [kTemporaryPasscodePrefix].
  String _generateTemporaryPasscode() {
    final tempCode = '$kTemporaryPasscodeLength'.generateUID(
      type: UIDType.numeric,
    );
    return '$kTemporaryPasscodePrefix$tempCode';
  }
}

/// Store locations Dropdown [StoreLocationsDropdown]
class StoreLocationsDropdown extends StatelessWidget {
  final String? initialValue;
  final Function(String, String) onChange;

  const StoreLocationsDropdown({
    super.key,
    required this.onChange,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return SearchStores(
      initialValue: initialValue,
      onChanged: (id, store) => onChange(id, store),
    );
  }
}

/// Account Status Dropdown [AccountStatusDropdown]
class AccountStatusDropdown extends StatelessWidget {
  const AccountStatusDropdown({
    super.key,
    this.initialValue,
    required this.onStatusChanged,
  });

  final Function(String?) onStatusChanged;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    final strList = AccountStatusHelper.toStringList();

    return StaticDropdown<String>(
      key: key,
      initialValue: initialValue,
      items: strList,
      label: strList.first,
      getValue: (status) => status,
      getDisplayText: (status) => status,
      onChanged: (String? v) => onStatusChanged(v),
    );
  }
}

/// Company's Departments [DepartmentDropdown]
class DepartmentDropdown extends StatelessWidget {
  final String? initialValue;
  final Function(String, String, String) onChanged;

  const DepartmentDropdown({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SearchDepartments(
      initialValue: initialValue,
      onChanged: (id, code, name) => onChanged(id, code, name),
    );
  }
}

/*
/// Role & Email [RoleAndStores]
class RoleAndStores extends StatelessWidget {
  const RoleAndStores({
    super.key,
    required this.onStoreChanged,
    required this.emailController,
    this.onEmailChanged,
    this.serverStore,
  });

  final TextEditingController emailController;
  final ValueChanged? onEmailChanged;
  final String? serverStore;
  final Function(String, String) onStoreChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextField(
          labelText: 'Email address',
          onChanged: onEmailChanged,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        SearchStores(
          initialValue: serverStore,
          onChanged: (id, store) => onStoreChanged(id, store),
        ),
      ],
    );
  }
}
*/
