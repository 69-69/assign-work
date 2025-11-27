import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/erp_priority_enum.dart';
import 'package:assign_erp/core/constants/requisition_status.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_requisition/pro_purchase_requisite_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_requisition/widget/form_inputs.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_requisition/widget/pr_printer.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_employees.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdatePurchaseRequisiteForm on BuildContext {
  Future openUpdatePurchaseRequisite({
    required PurchaseRequisition requisite,
  }) async {
    if (requisite.id.isEmpty) return;

    return await openBottomSheet(
      isExpand: false,
      child: FormBottomSheet(
        title: 'Edit Purchase Requisition',
        subtitle: requisite.prNumber.toUpperAll,
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
  String? _requestedBy;
  String? _departmentCode;
  String? _priority;
  String? _prStatus;
  // Dates
  DateTime? _expectedDate;
  DateTime? _requestDate;

  /// Line Items & purpose/reason for PR
  final List<PRLineItem> _lineItems = [];
  final Map<String, dynamic> _purposeForPR = {};

  PurchaseRequisition get _serverPR => widget.requisite;

  bool get isFormValid => _formKey.currentState?.validate() ?? false;

  /// Current employee info
  String get _employeeId => context.employee!.employeeId;
  String get _employeeName => context.employee!.fullName;

  ProPurchaseRequisiteBloc get _bloc =>
      context.read<ProPurchaseRequisiteBloc>();

  AuditAction get _action => _prStatus!.contains('approved')
      ? AuditAction.approved
      : AuditAction.updated;

  @override
  void initState() {
    super.initState();
    _purposeForPR.addAll({'purpose': _serverPR.purpose});
    _lineItems.addAll(_serverPR.lineItems);
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Construct Purchase Requisite object
  PurchaseRequisition get _updatedPR => _serverPR.copyWith(
    priority: PriorityHelper.fromString(
      _priority ?? _serverPR.priority.getValue,
    ),
    status: PRStatusHelper.fromString(_prStatus ?? _serverPR.status.getValue),
    requestedBy: _requestedBy ?? _serverPR.requestedBy,
    departmentCode: _departmentCode ?? _serverPR.departmentCode,
    expectedDate: _expectedDate ?? _serverPR.expectedDate,
    requestDate: _requestDate ?? _serverPR.requestDate,
    purpose: _purposeForPR['purpose'],
    lineItems: List.from(_lineItems),
    updatedBy: _employeeName,
    history: [
      ..._serverPR.history, // keep all old logs
      AuditLog(action: _action, performedBy: _employeeId),
    ],
  );

  void _onSubmit() {
    if (!isFormValid || _lineItems.isNullOrEmpty) {
      context.showAlertOverlay(
        'Please enter all required fields',
        bgColor: kDangerColor,
      );
      return;
    }

    final bloc = _bloc;
    bloc.add(
      UpdateProcurement<PurchaseRequisition>(
        documentId: _updatedPR.id,
        data: _updatedPR,
      ),
    );

    context.showAlertOverlay('Changes successfully saved');

    _confirmPrintoutDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FormGroupCard(
          title: 'Purchase Requisition',
          children: [
            _buildRequesterAndDepartment(),
            _buildPriorityAndPRStatus(),
          ],
        ),

        FormGroupCard(children: [_buildLineItems()]),

        FormGroupCard(
          title: 'Request & Required Dates',
          children: [_buildDates()],
        ),

        FormGroupCard(children: [_buildJustification()]),

        context.confirmableActionButton(onPressed: _onSubmit),
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
      initialPriority: _serverPR.priority.getValue,
      initialStatus: _serverPR.status.getValue,
      onPriorityChanged: (s) => setState(() => _priority = s),
      onStatusChanged: (s) => setState(() => _prStatus = s),
    );
  }

  DynamicTextFields _buildLineItems() {
    return DynamicTextFields(
      title: 'Products / Services',
      showButton: true,
      fieldsConfig: _PRFormConfig.itemsFields(),
      initialData: _serverPR.lineItems.map((e) => e.toMap()).toList(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _lineItems
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(data.map((e) => PRLineItem.fromMap(e)));
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
      title: 'PR Justification',
      initialData: [
        {'purpose': _serverPR.purpose},
      ],
      fieldsConfig: [
        FieldGroupConfig(
          key: 'purpose',
          label: 'Purpose / Reason for PR',
          type: TextInputType.multiline,
          isTextArea: true,
          isAutoGrow: true,
          minLines: null,
        ),
      ],
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _purposeForPR
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(data.first);
      },
    );
  }

  // -------------------------
  // Print & History Logic
  // -------------------------
  Future<void> _confirmPrintoutDialog() async {
    final isConfirmed = await context.confirmAction<bool>(
      const Text('Would you like to print the request for quotation: PR?'),
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

    final employee = await _PRFormConfig.getEmployee(_updatedPR.requestedBy);
    if (employee.isEmpty) return;

    _updateHistory();
    await PRPrinter(requisite: _updatedPR, employee: employee).printPR();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = _PRFormConfig.updateHistory(
      action: action,
      pr: _updatedPR,
      empId: _employeeId,
    );
    _bloc.add(up);
  }
}

class _PRFormConfig {
  static Future getEmployee(String empId) async {
    final employee = await GetEmployees.byEmployeeId(empId);
    return employee.isEmpty ? null : employee;
  }

  /// Audit Log Entry (Tracking actions)
  static AuditProcurement<PurchaseRequisition> updateHistory({
    required String empId,
    required AuditAction action,
    required PurchaseRequisition pr,
  }) {
    final up = AuditProcurement<PurchaseRequisition>(
      documentId: pr.id,
      log: {
        'history': [
          ...pr.history.map((e) => e.toMap()), // keep old logs
          AuditLog(action: action, performedBy: empId).toMap(), // new log
        ],
      },
    );
    return up;
  }

  /// Products / Services
  static List<FieldGroupConfig> itemsFields() {
    return [
      FieldGroupConfig(
        key: 'itemName',
        label: 'Item Name',
        type: TextInputType.text,
      ),
      FieldGroupConfig(
        key: 'quantity',
        label: 'Quantity',
        type: TextInputType.number,
      ),
      FieldGroupConfig(
        key: 'category',
        label: 'Item Group (e.g. Office Supplies, IT)',
        type: TextInputType.text,
        widgetType: FieldWidgetType.custom,
        customBuilder: ({required initialData, required onChanged}) {
          return ItemCategoryDropdown(
            initialValue: initialData,
            onChanged: (String? selected) => onChanged(selected),
          );
        },
      ),
      FieldGroupConfig(
        key: 'unitOfMeasure',
        label: 'Unit of Measure (e.g. box, kg)',
        type: TextInputType.text,
        widgetType: FieldWidgetType.custom,
        customBuilder: ({required initialData, required onChanged}) {
          return UnitOfMeasureDropdown(
            initialValue: initialData,
            onChanged: (String? selected) => onChanged(selected),
          );
        },
      ),
      FieldGroupConfig(
        key: 'notes',
        label: 'Additional Notes (if any)...',
        type: TextInputType.multiline,
        isTextArea: true,
        isAutoGrow: true,
        minLines: null,
        validator: (_) => null,
      ),
    ];
  }
}
