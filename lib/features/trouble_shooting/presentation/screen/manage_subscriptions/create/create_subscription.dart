import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/license_model.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/subscription_model.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/subscription/subscription_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/tenant_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/widget/form_inputs.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/widget/license_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateNewSubscription<T> on BuildContext {
  Future<void> openCreateNewSubscription() => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(
      title: 'Create Subscription',
      subtitle:
          'NOTE: Subscriptions are specific to each workspaces.\nNot shared or generic!',
      subTitleColor: kDangerColor,
      body: _CreateNewSubscriptionForm(),
    ),
  );
}

class _CreateNewSubscriptionForm extends StatefulWidget {
  const _CreateNewSubscriptionForm();

  @override
  State<_CreateNewSubscriptionForm> createState() =>
      _CreateNewSubscriptionFormState();
}

class _CreateNewSubscriptionFormState
    extends State<_CreateNewSubscriptionForm> {
  DateTime? _selectedExpiryDate;
  DateTime? _selectedEffectiveDate;
  final _formKey = GlobalKey<FormState>();
  final _feeController = TextEditingController(); // Subscription fee
  final _nameController = TextEditingController(); // Subscription name
  final Set<License> _assignedLicenses = {};

  Subscription get _newLicense => Subscription(
    fee: double.parse(_feeController.text),
    name: _nameController.text,
    licenses: _assignedLicenses,
    expiresOn: _selectedExpiryDate,
    effectiveFrom: _selectedEffectiveDate,
    createdBy: context.employee?.fullName ?? 'unknown',
  );

  Future<void> _onSubmit() async {
    final noLicensesSelected = _assignedLicenses.isEmpty;

    if (noLicensesSelected) {
      final result = await context.confirmAction<bool>(
        const Text('Licenses are required to create a subscription.'),
        title: 'Assign Licenses',
      );
      if (!result) return;
    }

    if (mounted && _formKey.currentState!.validate()) {
      /// Create New Subscription
      final item = _newLicense;
      context.read<SubscriptionBloc>().add(
        AddSubscription<Subscription>(data: item),
      );

      _formKey.currentState!.reset();

      context.showAlertOverlay(
        '${_nameController.text.toTitle} subscription created',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    /*return BlocBuilder<SubscriptionBloc, SetupState<Subscription>>(
      builder: (context, state) => Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: _buildBody(context),
      ),
    );*/
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
        const SizedBox(height: 10.0),
        SubscriptionNameAndFee(
          feeController: _feeController,
          nameController: _nameController,
          onFeeChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onNameChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 10.0),
        EffectiveAndExpiryDateInput(
          labelExpiry: "Expiry date",
          labelManufacture: "Effective date",
          onExpiryChanged: (d) => setState(() => _selectedExpiryDate = d),
          onEffectiveChanged: (d) => setState(() => _selectedEffectiveDate = d),
        ),
        LicenseCard(onSelectedFunc: _onSelectedFunc),
        const SizedBox(height: 10.0),

        context.confirmableActionButton(
          label: 'Create Subscription',
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  void _onSelectedFunc(Set<License> licenses, String module) {
    /*// Find all modules involved in this license set
    final touchedModules = licenses.map((l) => l.module).toSet();
    // Remove all licenses that belong to any of these modules
    _assignedLicenses.removeWhere((l) => touchedModules.contains(l.module));*/

    _assignedLicenses.removeWhere((f) => f.module == module);

    // Add newly selected licenses (can be empty if all toggled off)
    if (licenses.isNotEmpty) {
      _assignedLicenses.addAll(licenses);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    // _assignedLicenses.clear();
    super.dispose();
  }
}
