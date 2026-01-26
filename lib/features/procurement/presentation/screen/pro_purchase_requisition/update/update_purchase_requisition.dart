import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/extensions/erp_priority_enum.dart';
import 'package:assign_erp/core/util/extensions/line_item_type.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
import 'package:assign_erp/core/util/str_util.dart';
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
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdatePurchaseRequisiteForm on BuildContext {
  Future openUpdatePurchaseRequisite({
    required PurchaseRequisition requisite,
  }) async {
    if (requisite.id.isEmpty) return;

    return await openBottomSheet(
      isExpand: false,
      child: BottomSheetScaffold(
        title: 'Edit Purchase Requisition',
        subtitle:
            '${requisite.prNumber.toUpperAll} (${requisite.lineItems.first.getType})',
        body: _PurchaseRequisite(requisite: requisite),
      ),
    );
  }
}

class _PurchaseRequisite extends StatefulWidget {
  final PurchaseRequisition requisite;

  const _PurchaseRequisite({required this.requisite});

  @override
  State<_PurchaseRequisite> createState() => _PurchaseRequisiteState();
}

class _PurchaseRequisiteState extends State<_PurchaseRequisite> {
  final _formKey = GlobalKey<FormState>();

  // Basic fields
  String? _priority;
  String? _prStatus;
  bool? _autoConvertPr;
  String? _requestedBy;
  String? _costCenterCode;
  String? _departmentCode;
  // Dates
  DateTime? _requestDate;
  DateTime? _expectedDate;
  bool _isSubmitting = false;

  /// Line Items & purpose/reason for PR
  final List<LineItem> _lineItems = [];
  final Map<String, dynamic> _purposeForPR = {};
  bool get isFormValid => _formKey.currentState?.validate() ?? false;

  PurchaseRequisition get _serverPR => widget.requisite;
  String get _lineItemType => _serverPR.lineItems.first.getType;

  /// Current employee info
  Employee? get _employee => context.employee;
  String get _employeeId => _employee!.employeeId;
  String get _employeeName => _employee!.fullName;

  ProPurchaseRequisiteBloc get _bloc =>
      context.read<ProPurchaseRequisiteBloc>();

  AuditAction get _action => AuditActionUtil.isApproved(_prStatus)
      ? AuditAction.approved
      : AuditAction.updated;

  /// Construct Purchase Requisite object
  PurchaseRequisition get _updatedPR {
    final status = _prStatus ?? _serverPR.getPRStatus;

    return _serverPR.copyWith(
      autoConvertPr: _autoConvertPr,
      priority: PriorityUtil.fromString(
        _priority ?? _serverPR.priority.getName,
      ),
      status: WorkflowStatusUtil.fromString(status),
      requestedBy: _requestedBy ?? _serverPR.requestedBy,
      costCenterCode: _costCenterCode ?? _serverPR.costCenterCode,
      departmentCode: _departmentCode ?? _serverPR.departmentCode,
      expectedDate: _expectedDate ?? _serverPR.expectedDate,
      requestDate: _requestDate ?? _serverPR.requestDate,
      purpose: _purposeForPR['purpose'],
      lineItems: List.from(_lineItems),
      updatedBy: _employeeName,
      history: [
        ..._serverPR.history, // keep all old logs
        AuditLog(
          action: _action,
          actionBy: _employeeId,
          statusAfterAction: status,
        ),
      ],
    );
  }

  void _onSubmit() {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    if (!isFormValid || _lineItems.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    _bloc.add(
      UpdateProcurement<PurchaseRequisition>(
        documentId: _updatedPR.id,
        data: _updatedPR,
      ),
    );
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
    setState(() => _isSubmitting = false);
  }

  Future<void> _handleBlocState(
    BuildContext cxt,
    ProcurementState<PurchaseRequisition> state,
  ) async {
    switch (state) {
      case ProcurementUpdated<PurchaseRequisition>(message: var msg):
        _showAlert(msg ?? 'Changes saved successfully');
        await _confirmPrintoutDialog();
      case ProcurementError<PurchaseRequisition>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _purposeForPR.addAll({'purpose': _serverPR.purpose});
    _lineItems.addAll(_serverPR.lineItems);
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
        child: _buildBody(),
      ),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
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
          title: '3. $_lineItemType Line Items',
          subTitle:
              '\nYou can add more ${_lineItemType}s to the Requisition (PR).',
          children: [_buildLineItems(_lineItemType)],
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

  // -------------------------
  // Section Builders
  // -------------------------
  RequestedByAndDepartments _buildRequesterAndDepartment() {
    return RequestedByAndDepartments(
      initialDepartment: _serverPR.departmentCode,
      initialRequestedBy: _serverPR.requestedBy,
      onRequestedBy: (id, code, name) => setState(() => _requestedBy = name),
      onDepartmentChange: (id, code, name) =>
          setState(() => _departmentCode = code),
    );
  }

  PriorityAndPRStatusDropdown _buildPriorityAndPRStatus() {
    return PriorityAndPRStatusDropdown(
      initialPriority: _serverPR.priority.getName,
      initialStatus: _serverPR.status.getName,
      onPriorityChanged: (s) => setState(() => _priority = s),
      onStatusChanged: (s) => setState(() => _prStatus = s),
    );
  }

  DynamicTextFields _buildLineItems(String lineItemType) {
    final fwk = LineItemTypeUtil.isMaterial(lineItemType)
        ? 'description'
        : null;

    return DynamicTextFields(
      showButton: true,
      fullWidthKey: fwk,
      fieldsConfig: PRFormInputs.fields(lineItemType),
      initialData: _serverPR.lineItems.map((e) => e.toMap(true)).toList(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        // Update the LineItem list
        PRFormInputs.updateListFromData<LineItem>(
          _lineItems,
          map: data,
          fromMap: (map, id) => LineItem.fromMap(map),
        );
      },
    );
  }

  RequestAndExpectedDate _buildDates() {
    return RequestAndExpectedDate(
      labelRequest: "Request date",
      labelExpected: "Expected date",
      initialExpectedDate: _serverPR.getExpectedDate,
      initialRequestDate: _serverPR.getRequestDate,
      onRequestChanged: (date) => setState(() => _requestDate = date),
      onExpectedChanged: (date) => setState(() => _expectedDate = date),
    );
  }

  DynamicTextFields _buildJustification() {
    return DynamicTextFields(
      initialData: [
        {'purpose': _serverPR.purpose},
      ],
      fieldsConfig: PRFormInputs.justificationFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _purposeForPR
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(data.first);
      },
    );
  }

  AutoAndCostCenterDepartment _buildAutoCreateAndCostCenter() {
    return AutoAndCostCenterDepartment(
      isSelected: _autoConvertPr ?? _serverPR.autoConvertPr,
      onAutoConvertChanged: (bool? v) {
        setState(() => _autoConvertPr = v ?? false);
      },
      initialCostCenter: _serverPR.costCenterCode,
      onCostCenterChange: (id, code, name) =>
          setState(() => _costCenterCode = code),
    );
  }

  // -------------------------
  // Print & History Logic
  // -------------------------
  Future<void> _confirmPrintoutDialog() async {
    final isConfirmed = await context.confirmAction<bool>(
      const Text('Would you like to print this Purchase Requisition (PR)?'),
      title: "Print PR",
      onAcceptLabel: "Print",
      onRejectLabel: "Cancel",
    );

    if (mounted) {
      if (!isConfirmed) return;

      // Show progress dialog while loading data
      await context.progressBarDialog(
        request: _printout(),
        onSuccess: (_) {
          context.showAlertOverlay('PR Printout successful');
          Navigator.pop(context);
        },
        onError: (e) => context.showAlertOverlay(
          'PR printout failed',
          bgColor: kDangerColor,
        ),
      );
    }
  }

  Future<dynamic> _printout() => Future.delayed(kRProgressDelay, () async {
    if (_updatedPR.isEmpty) return;

    final employee = await PRFormInputs.getEmployee(_updatedPR.requestedBy);
    if (employee.isEmpty) return;

    _updateHistory();
    await PRPrinter(requisite: _updatedPR, employee: employee).printPR();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = PRFormInputs.updateHistory(
      action: action,
      pr: _updatedPR,
      empId: _employeeId,
    );
    _bloc.add(up);
  }
}
