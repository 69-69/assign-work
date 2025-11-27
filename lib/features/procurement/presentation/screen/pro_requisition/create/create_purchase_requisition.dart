import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/erp_priority_enum.dart';
import 'package:assign_erp/core/constants/requisition_status.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/form_group_card.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
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

extension CreatePurchaseRequisitionForm on BuildContext {
  Future<void> openAddPurchaseRequisite({
    PurchaseRequisition? serverRequisition,
  }) => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(
      title: 'Create Purchase Requisition',
      body: _PurchaseRequisiteForm(serverRequisition: serverRequisition),
    ),
  );
}

class _PurchaseRequisiteForm extends StatefulWidget {
  final PurchaseRequisition? serverRequisition;

  const _PurchaseRequisiteForm({this.serverRequisition});

  @override
  State<_PurchaseRequisiteForm> createState() => _PurchaseRequisiteFormState();
}

class _PurchaseRequisiteFormState extends State<_PurchaseRequisiteForm> {
  final _formKey = GlobalKey<FormState>();

  // Basic fields
  String _prNumber = '';
  String _requestedBy = '';
  String _departmentCode = '';
  String? _priority;
  String? _prStatus;
  // Dates
  DateTime? _expectedDate;
  DateTime? _requestDate;

  /// Line Items & purpose/reason for PR
  final List<PRLineItem> _lineItems = [];
  final Map<String, dynamic> _purposeForPR = {};

  bool get isFormValid => _formKey.currentState!.validate();

  /// Current employee info
  String get _employeeId => context.employee!.employeeId;
  String get _employeeName => context.employee!.fullName;
  String get _employeeStore => context.employee!.storeNumber;

  ProPurchaseRequisiteBloc get _bloc =>
      context.read<ProPurchaseRequisiteBloc>();

  @override
  void initState() {
    super.initState();
    _generatePRNumber();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _generatePRNumber() async {
    await DocType.prs.getShortUID(
      onChanged: (s) {
        if (mounted) setState(() => _prNumber = s);
      },
    );
  }

  /// Construct PurchaseRequisite object
  PurchaseRequisition get _newPR => PurchaseRequisition(
    prNumber: _prNumber,
    storeNumber: _employeeStore,
    priority: PriorityHelper.fromString(_priority ?? ''),
    status: PRStatusHelper.fromString(_prStatus ?? ''),
    departmentCode: _departmentCode,
    requestedBy: _requestedBy,
    expectedDate: _expectedDate,
    requestDate: _requestDate,
    purpose: _purposeForPR['purpose'],
    lineItems: List.from(_lineItems),
    createdBy: _employeeName,
    history: [AuditLog(action: AuditAction.created, performedBy: _employeeId)],
  );

  void _onSubmit() {
    if (!isFormValid || _newPR.isEmpty) {
      context.showAlertOverlay(
        'Please fill in all required fields',
        bgColor: kDangerColor,
      );
      return;
    }
    _bloc.add(AddProcurement<PurchaseRequisition>(data: _newPR));

    _confirmPrintoutDialog().then((_) => _resetForm());
  }

  void _resetForm() {
    if (mounted) {
      _generatePRNumber(); // fresh RFQ number

      _formKey.currentState?.reset();
      setState(() {
        _departmentCode = '';
        _requestedBy = '';
        _priority = null;
        _prStatus = null;
        _expectedDate = null;
        _requestDate = null;
        _lineItems.clear();
        _purposeForPR.clear();
      });
    }
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
        _PRFormConfig.buildPRNumber(context, _prNumber, _generatePRNumber),
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

        context.confirmableActionButton(
          label: 'Create PR',
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  // -------------------------
  // Section Builders
  // -------------------------
  DynamicTextFields _buildJustification() {
    return DynamicTextFields(
      title: 'PR Justification',
      initialData: [{}],
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

  RequestAndExpectedDate _buildDates() {
    return RequestAndExpectedDate(
      labelRequest: "Request date",
      labelExpected: "Expected date",
      onRequestChanged: (date) => setState(() => _requestDate = date),
      onExpectedChanged: (date) => setState(() => _expectedDate = date),
    );
  }

  DynamicTextFields _buildLineItems() {
    return DynamicTextFields(
      title: 'Products / Services',
      initialData: [{}],
      showButton: true,
      fieldsConfig: _PRFormConfig.itemsFields(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _lineItems
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(data.map((e) => PRLineItem.fromMap(e)));
      },
    );
  }

  PriorityAndPRStatusDropdown _buildPriorityAndPRStatus() {
    return PriorityAndPRStatusDropdown(
      onPriorityChanged: (s) => setState(() => _priority = s),
      onStatusChanged: (s) => setState(() => _prStatus = s),
    );
  }

  RequestedByAndDepartments _buildRequesterAndDepartment() {
    return RequestedByAndDepartments(
      onRequestedBy: (id, code, name) => setState(() => _requestedBy = name),
      onDepartmentChange: (id, code, name) =>
          setState(() => _departmentCode = code),
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
        onSuccess: (_) => context.showAlertOverlay('PR successfully created'),
        onError: (e) => context.showAlertOverlay(
          'PR printout failed',
          bgColor: kDangerColor,
        ),
      );
    }
  }

  Future<dynamic> _printout() => Future.delayed(kRProgressDelay, () async {
    if (_newPR.isEmpty) return;

    final employee = await _PRFormConfig.getEmployee(_newPR.requestedBy);
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
    final up = _PRFormConfig.updateHistory(
      action: action,
      pr: _newPR,
      empId: _employeeId,
    );
    _bloc.add(up);
  }
}

class _PRFormConfig {
  static Widget buildPRNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => Align(
    alignment: Alignment.topLeft,
    child: FittedBox(
      child: context.actionInfoButton(
        'Refresh PR Number',
        count: count,
        bgColor: kPrimaryColor,
        isTotal: false,
        onPressed: onPressed,
      ),
    ),
  );

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
