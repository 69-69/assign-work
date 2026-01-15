import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/company_stores_model.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_stores_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/can_add_more_stores.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/company_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add Company Stores or Branches
extension AddStoreLocations<T> on BuildContext {
  Future<void> openAddStoreLocations({
    CompanyStores? serverStore,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title:
          '${serverStore == null ? 'Add Stores (Branches)' : 'Edit ${serverStore.name.toTitle}'} ',
      body: _AddStoreFormBody(serverStore: serverStore),
    ),
  );
}

class _AddStoreFormBody extends StatefulWidget {
  final CompanyStores? serverStore;

  const _AddStoreFormBody({this.serverStore});

  @override
  State<_AddStoreFormBody> createState() => _AddStoreFormBodyState();
}

class _AddStoreFormBodyState extends State<_AddStoreFormBody> {
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final List<CompanyStores> _storeList = [];
  CompanyStores? get _serverStore => widget.serverStore;
  bool get _isFormValid => _formKey.currentState?.validate() ?? false;
  bool get _isServerNull => _serverStore == null;

  Employee? get _employee => context.employee;
  String get _employeeName => _employee!.fullName;
  String get _employeeId => _employee!.employeeId;
  CompanyStoresBloc get _bloc => context.read<CompanyStoresBloc>();

  void _onSubmit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Stores/Branch
    if (_serverStore?.isNotEmpty ?? false) {
      _updateStore();
      return;
    }

    // Case 2: Form validation or empty Stores/Branch
    if (!_isFormValid && (_serverStore?.isNullOrEmpty ?? true)) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Create new Stores/Branch
    _createNewStores();
  }

  void _createNewStores() {
    // append store number to each stores/branches
    final newStores = _storeList
        .map(
          (e) => e.copyWith(
            storeNumber: '${e.name}${e.location}'.generateUniqueCode(),
            createdBy: _employeeName,
            history: history(),
          ),
        )
        .toList();
    _bloc.add(AddSetup<List<CompanyStores>>(data: newStores));
  }

  void _updateStore() {
    final updated = _storeList.first.copyWith(
      id: _serverStore!.id,
      storeNumber: _serverStore!.storeNumber,
      updatedBy: _employeeName,
      history: history(AuditAction.updated),
    );
    _bloc.add(
      UpdateSetup<CompanyStores>(documentId: updated.id, data: updated),
    );
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    AuditLog(action: action, actionBy: _employeeId),
  ];

  // load existing stores/branches
  void _loadExisting() {
    if (_serverStore != null) {
      _storeList.clear();
      _storeList.add(_serverStore!);
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull
          ? _formKey.currentState!.reset()
          : Navigator.pop(context),
    );
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<CompanyStores> state) {
    final note = _isServerNull ? 'Stores created' : 'Changes saved';

    switch (state) {
      case SetupAdded<CompanyStores>(message: var msg):
      case SetupUpdated<CompanyStores>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<CompanyStores>():
        _showAlert('Error saving changes');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyStoresBloc, SetupState<CompanyStores>>(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FormGroupCard(children: [_buildStoresFields()]),
        context.confirmableActionButton(
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Add Store (Branch)')
              : (_isSubmitting ? 'Updating...' : null),
          isDisabled: _isSubmitting,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  DynamicTextFields _buildStoresFields() {
    ({bool addMore, int maxAllowed}) canAdd = context.canAddMoreStores;

    return DynamicTextFields(
      title: _serverStore?.name ?? 'Stores (Branches)',
      fieldsConfig: CompanyFormInputs.addStoresFields,
      initialData: [?_serverStore?.toMap()],
      showButton: canAdd.addMore || _serverStore != null,
      fieldGroupsLimit: canAdd.maxAllowed,
      onLimitReached: () async => await context.showUpgradeDialog(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        // Create a new line item
        _storeList
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(data.map((e) => CompanyStores.fromMap(e)));
      },
    );
  }
}
