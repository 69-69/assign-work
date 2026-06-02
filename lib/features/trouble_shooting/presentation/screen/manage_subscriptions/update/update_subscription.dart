import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/license_model.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/subscription_model.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/subscription/subscription_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/tenant_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/widget/license_card.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/widget/trouble_shoot_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateSubscription<T> on BuildContext {
  Future<void> openUpdateSubscription({
    required Subscription subscription,
    bool? isAssign,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: isAssign == true
          ? 'Assign Subscriptions'
          : 'Edit ${subscription.name}'.toTitle,
      subtitle:
          'NOTE: Subscriptions are specific to each workspace.\nNot shared or generic!',
      subTitleColor: kDangerColor,
      body: _UpdateSubscriptionForm(
        subscription: subscription,
        isAssign: isAssign,
      ),
    ),
  );
}

class _UpdateSubscriptionForm extends StatefulWidget {
  final Subscription subscription;
  final bool? isAssign;

  const _UpdateSubscriptionForm({required this.subscription, this.isAssign});

  @override
  State<_UpdateSubscriptionForm> createState() =>
      _UpdateSubscriptionFormState();
}

class _UpdateSubscriptionFormState extends State<_UpdateSubscriptionForm> {
  bool _isSubmitting = false;
  Subscription get _subscription => widget.subscription;
  DateTime? _selectedExpiryDate;
  DateTime? _selectedEffectiveDate;
  final _formKey = GlobalKey<FormState>();
  late Set<License> _assignedLicenses = {};
  late final _feeController = TextEditingController(
    text: '${_subscription.fee}',
  );
  late final _nameController = TextEditingController(text: _subscription.name);

  bool? get _isAssign => widget.isAssign;

  Future<void> _onSubmit() async {
    final isRemovingAllLicenses = _assignedLicenses.isEmpty;

    if (_isSubmitting) return;
    if (isRemovingAllLicenses) {
      bool result = await _warnUser();
      if (!result) return;
    }

    if (mounted && _formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      _updatedSubscription();
    }
  }

  void _updatedSubscription() {
    final updatedSubscription = _subscription.copyWith(
      fee: double.parse(_feeController.text),
      name: _nameController.text,
      licenses: _assignedLicenses,
      expiresOn: _selectedExpiryDate,
      effectiveFrom: _selectedEffectiveDate,
      updatedBy: context.employee?.fullName ?? 'unknown',
    );

    context.read<SubscriptionBloc>().add(
      OverrideTenant<Subscription>(
        documentId: _subscription.id,
        data: updatedSubscription,
      ),
    );
  }

  Future<bool> _warnUser() async {
    final result = await context.confirmAction<bool>(
      const Text('Are you sure you want to remove all licenses?'),
      title: 'Remove All Licenses',
    );
    return result;
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => Navigator.pop(context));
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, TenantState<Subscription> state) {
    switch (state) {
      case TenantUpdated<Subscription>(message: var msg):
        _showAlert(msg ?? 'Changes saved');
      case TenantError<Subscription>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    _assignedLicenses = Set.from(_subscription.licenses);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionBloc, TenantState<Subscription>>(
      listener: _handleBlocState,
      child: _buildBody(),
    );
  }

  BlocBuilder<SubscriptionBloc, TenantState<Subscription>> _buildBody() {
    return BlocBuilder<SubscriptionBloc, TenantState<Subscription>>(
      builder: (context, state) => Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: _buildCard(context),
      ),
    );
  }

  Column _buildCard(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_isAssign == null) ...[
          const SizedBox(height: 10.0),
          SubscriptionNameAndFee(
            nameController: _nameController,
            feeController: _feeController,
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
            initialExpiryDate: _subscription.getExpiresOn,
            initialEffectiveDate: _subscription.getEffectiveFrom,
            onExpiryChanged: (d) => setState(() => _selectedExpiryDate = d),
            onEffectiveChanged: (d) =>
                setState(() => _selectedEffectiveDate = d),
          ),
        ],

        LicenseCard(
          onSelectedFunc: _onSelectedFunc,
          initialLicenses: _assignedLicenses,
        ),
        const SizedBox(height: 10.0),

        context.confirmableActionButton(onSubmit: _onSubmit),
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
    _assignedLicenses.clear();
    super.dispose();
  }
}

/* RULE FOR WORKSPACE LICENSE:
match /workspace_auth_db/{workspaceId} {
  allow read: if request.auth != null &&
                 exists(/databases/$(database)/documents/workspace_auth_db/$(workspaceId)/$(request.auth.uid)) &&
                 get(/databases/$(database)/documents/workspace_auth_db/$(workspaceId)/$(workspace.subscriptionId)).data.licenses.hasAny(['pos']);
*/
