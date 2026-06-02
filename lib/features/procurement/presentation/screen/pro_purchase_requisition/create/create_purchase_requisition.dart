import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/form_group_card_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/extensions/erp_priority_enum.dart';
import 'package:assign_erp/core/util/extensions/form_validity.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/auto_id_field.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_requisition/pro_purchase_requisite_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_requisition/widget/pr_form_inputs.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_requisition/widget/pr_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreatePurchaseRequisitionForm on BuildContext {
  Future<void> openCreatePurchaseRequisite({
    PurchaseRequisition? serverRequisition,
    void Function()? onBackPress,
    required String lineType,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: 'New Purchase Requisition',
      onBackPress: onBackPress,
      body: _PurchaseRequisiteForm(
        lineType: lineType,
        serverRequisition: serverRequisition,
      ),
    ),
  );
}

class _PurchaseRequisiteForm extends StatefulWidget {
  final PurchaseRequisition? serverRequisition;
  final String lineType;

  const _PurchaseRequisiteForm({
    this.serverRequisition,
    required this.lineType,
  });

  @override
  State<_PurchaseRequisiteForm> createState() => _PurchaseRequisiteFormState();
}

class _PurchaseRequisiteFormState extends State<_PurchaseRequisiteForm> {
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();

  String get _lineItemType => widget.lineType;

  // Basic fields
  bool _isSubmitting = false;
  bool _autoConvertPr = true; // If approved, auto-convert PR to RFQ
  String _prNumber = '';
  String _requestedBy = '';
  String _costCenterCode = ''; // 47960533
  String _departmentCode = '';
  String? _priority;
  String? _prStatus;

  // Dates
  DateTime? _expectedDate;
  DateTime? _requestDate;

  /// Line Items & purpose/reason for PR
  final List<LineItem> _lineItems = [];
  final Map<String, dynamic> _purposeForPR = {};

  bool _isFormValid =false; // > _formKey.currentState!.validate();

  /// Current employee info
  String get _employeeId => context.employee!.employeeId;

  String get _employeeName => context.employee!.fullName;

  String get _employeeStore => context.employee!.storeNumber;

  ProPurchaseRequisiteBloc get _bloc =>
      context.read<ProPurchaseRequisiteBloc>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Construct PurchaseRequisite object
  PurchaseRequisition get _newPR => PurchaseRequisition(
    prNumber: _prNumber,
    storeNumber: _employeeStore,
    autoConvertPr: _autoConvertPr,
    priority: PriorityUtil.fromString(_priority ?? ''),
    status: WorkflowStatusUtil.fromString(_prStatus ?? ''),
    costCenterCode: _costCenterCode,
    departmentCode: _departmentCode,
    requestedBy: _requestedBy,
    expectedDate: _expectedDate,
    requestDate: _requestDate,
    purpose: _purposeForPR['purpose'],
    lineItems: List.from(_lineItems),
    createdBy: _employeeName,
    history: [
      AuditLog(
        action: AuditAction.created,
        actionBy: _employeeId,
        statusAfterAction: _prStatus,
      ),
    ],
  );

  void _onSubmit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    if (!_isFormValid || _newPR.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    _bloc.add(AddProcurement<PurchaseRequisition>(data: _newPR));
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _autoConvertPr = false;
        _costCenterCode = '';
        _departmentCode = '';
        _requestedBy = '';
        _priority = null;
        _prStatus = null;
        _expectedDate = null;
        _requestDate = null;
        _lineItems.clear();
        _purposeForPR.clear();
        _isFormValid=false;
      });
    }
  }

  void _syncValidity() => _formKey.syncValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => _resetForm());
    setState(() => _isSubmitting = false);
  }

  Future<void> _handleBlocState(
    BuildContext cxt,
    ProcurementState<PurchaseRequisition> state,
  ) async {
    switch (state) {
      case ProcurementAdded<PurchaseRequisition>(message: var msg):
        _showAlert(msg ?? 'PR created successfully');
        await _confirmPrintoutDialog();
      case ProcurementError<PurchaseRequisition>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      ProPurchaseRequisiteBloc,
      ProcurementState<PurchaseRequisition>
    >(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: KeyedSubtree(key: _formResetKey, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    return FormGroupTabView(
      contents: formGroupCards,
      header: AutoIDField(
        label: 'PR Number',
        onGenerate: () async => await DocType.prs.getShortUID,
        onChanged: (id) {
          setState(() => _prNumber = id);
          _syncValidity();
        },
      ),
      footers: [
        context.confirmableActionButton(
          submitLabel: _isSubmitting ? 'Creating...' : 'Create PR',
          isDisabled: !_isFormValid || _isSubmitting,
          onDraft: (){},
          onSubmit: _onSubmit,
        ),
      ],
      visibleWhen: _isFormValid,
      showNavigationButtons: true,
    );
  }

  List<FormGroupCardModel> get formGroupCards => [
    FormGroupCardModel(
      isExpanded: true,
      title: 'Requisition Overview',
      subTitle:
      '\nRequisition details, requester information, & document status.',
      builder: () => [
        _buildRequesterAndDepartment(),
        _buildPriorityAndPRStatus(),
      ],
    ),
    FormGroupCardModel(
      title: 'Account Assignment & Sourcing',
      subTitle:
      '\nCost center assignment and RFQ creation settings.',
      builder: () => [
        _buildAutoCreateAndCostCenter(),
      ],
    ),
    FormGroupCardModel(
      title: '${_lineItemType.toSentence} Line Items',
      subTitle:
      '\nYou can add more ${_lineItemType}s to the Requisition (PR).',
      builder: () => [
        _buildLineItems(),
      ],
    ),
    FormGroupCardModel(
      title: 'Request & Delivery Dates',
      subTitle:
      '\nRequest-by and expected delivery timelines.',
      builder: () => [
        _buildDates(),
      ],
    ),
    FormGroupCardModel(
      title: 'PR Justification',
      subTitle:
      '\nBusiness justification or purpose of the request.',
      builder: () => [
        _buildJustification(),
      ],
    ),
  ];

  // -------------------------
  // Section Builders
  // -------------------------
  DynamicTextFields _buildJustification() {
    return DynamicTextFields(
      initialData: [{}],
      fieldsConfig: PRFormInputs.justificationFields,
      onChanged: (List<Map<String, dynamic>> data) {
        _purposeForPR
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(data.first);
        _syncValidity();
      },
    );
  }

  RequestAndExpectedDate _buildDates() {
    return RequestAndExpectedDate(
      labelRequest: "Request date",
      labelExpected: "Expected date",
      onRequestChanged: (date) {
        setState(() => _requestDate = date);
        _syncValidity();
      },
      onExpectedChanged: (date) {
        setState(() => _expectedDate = date);
        _syncValidity();
      },
    );
  }

  DynamicTextFields _buildLineItems() {
    return DynamicTextFields(
      initialData: [{}],
      isRepeatable: true,
      fullWidthKey: 'description',
      fieldsConfig: PRFormInputs.fields(
        _lineItemType,
        keysToExclude: ['limitAmount', 'limitQuantity'],
      ),
      onChanged: (List<Map<String, dynamic>> data) {
        // Update the ProLineItem list
        PRFormInputs.updateListFromData<LineItem>(
          _lineItems,
          map: data,
          fromMap: (map, id) =>
              LineItem.fromMap(map, id: id, lineType: _lineItemType),
        );
        _syncValidity();
      },
    );
  }

  PriorityAndPRStatusDropdown _buildPriorityAndPRStatus() {
    return PriorityAndPRStatusDropdown(
      onPriorityChanged: (s) {
        setState(() => _priority = s);
        _syncValidity();
      },
      onStatusChanged: (s) {
        setState(() => _prStatus = s);
        _syncValidity();
      },
    );
  }

  RequestedByAndDepartments _buildRequesterAndDepartment() {
    return RequestedByAndDepartments(
      onRequestedBy: (id, code, name) {
        setState(() => _requestedBy = name);
        _syncValidity();
      },
      onDepartmentChange: (id, code, name) {
        setState(() => _departmentCode = code);
        _syncValidity();
      },
    );
  }

  AutoAndCostCenterDepartment _buildAutoCreateAndCostCenter() {
    return AutoAndCostCenterDepartment(
      isSelected: _autoConvertPr,
      onAutoConvertChanged: (bool? v) {
        setState(() => _autoConvertPr = v ?? false);
        _syncValidity();
      },
      onCostCenterChange: (id, code, name) {
        setState(() => _costCenterCode = code);
        _syncValidity();
      },
    );
  }

  // -------------------------
  // Print & History Logic
  // -------------------------
  Future<void> _confirmPrintoutDialog() async {
    final isConfirmed = await context.confirmAction<bool>(
      const Text('Would you like to print the Purchase Requisition: PR?'),
      title: "Print PR",
      onAcceptLabel: "Print",
      onRejectLabel: "Cancel",
    );

    if (mounted && isConfirmed) {
      // Show progress dialog while loading data
      await context.progressBarDialog(
        request: _printout(),
        onSuccess: (_) => _showAlert('PR successfully created'),
        onError: (e) => _showAlert('PR printout failed'),
      );
    }
  }

  Future<dynamic> _printout() => Future.delayed(kRProgressDelay, () async {
    if (_newPR.isEmpty) return;

    final employee = await PRFormInputs.getEmployee(_newPR.requestedBy);
    if (employee.isEmpty) return;

    // Log that details were printed
    if (mounted &&
        AuditTracker.shouldLog(
          id: _newPR.id,
          type: DocType.prs,
          action: AuditAction.printed,
        )) {
      _updateHistory();
    }
    await PRPrinter(requisite: _newPR, employee: employee).printPR();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = PRFormInputs.updateHistory(
      action: action,
      pr: _newPR,
      empId: _employeeId,
    );
    _bloc.add(up);
  }
}

/*
  Column _buildBody2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // PRFormInputs.buildPRNumber(context, _prNumber, _generatePRNumber),
        AutoIDField(
          label: 'PR Number',
          onGenerate: () async => await DocType.prs.getShortUID,
          onChanged: (id) {
            setState(() => _prNumber = id);
            _syncValidity();
          },
        ),

        FormGroupCard(
          title: '1. Requisition Overview',
          subTitle:
              '\nRequisition details, requester information, & document status.',
          children: [
            _buildRequesterAndDepartment(),
            _buildPriorityAndPRStatus(),
          ],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '2. Account Assignment & Sourcing',
          subTitle: '\nCost center assignment and RFQ creation settings.',
          children: [_buildAutoCreateAndCostCenter()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '3. ${_lineItemType.toSentence} Line Items',
          subTitle:
              '\nYou can add more ${_lineItemType}s to the Requisition (PR).',
          children: [_buildLineItems()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '4. Request & Delivery Dates',
          subTitle: '\nRequest-by and expected delivery timelines.',
          children: [_buildDates()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '5. PR Justification',
          subTitle: '\nBusiness justification or purpose of the request.',
          children: [_buildJustification()],
        ),

        const SizedBox(height: 10.0),
        context.confirmableActionButton(
          label: _isSubmitting ? 'Creating...' : 'Create PR',
          isDisabled: !_isFormValid || _isSubmitting,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }*/