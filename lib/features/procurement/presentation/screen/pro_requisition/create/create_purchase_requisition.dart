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

  String _newPRNumber = '';
  String _requestedBy = '';
  String _departmentCode = '';
  String? _selectedPriority;
  String? _selectedPRStatus;
  DateTime? _selectedRequiredDate;
  DateTime? _selectedRequestDate;

  // Add a list to manage line items
  final List<PRLineItem> _lineItems = [];
  final Map<String, dynamic> _purposeForPR = {};

  bool get isFormValid => _formKey.currentState!.validate();

  String get _currentEmployeeId => context.employee!.employeeId;

  ProPurchaseRequisiteBloc get _readBloc =>
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
        if (mounted) setState(() => _newPRNumber = s);
      },
    );
  }

  PurchaseRequisition get _newRequisition => PurchaseRequisition(
    storeNumber: context.employee!.storeNumber,
    prNumber: _newPRNumber,
    priority: PriorityHelper.fromString(_selectedPriority ?? ''),
    status: PRStatusHelper.fromString(_selectedPRStatus ?? ''),
    departmentCode: _departmentCode,
    requestedBy: _requestedBy,
    neededByDate: _selectedRequiredDate,
    requestDate: _selectedRequestDate,
    purpose: _purposeForPR['purpose'],
    lineItems: List.from(_lineItems),
    createdBy: context.employee!.fullName,
    history: [
      AuditLog(action: AuditAction.created, performedBy: _currentEmployeeId),
    ],
  );

  void _onSubmit() {
    if (!isFormValid || _newRequisition.isEmpty) {
      context.showAlertOverlay(
        'Please fill in all required fields',
        bgColor: kDangerColor,
      );
      return;
    }
    _readBloc.add(AddProcurement<PurchaseRequisition>(data: _newRequisition));

    _confirmPrintoutDialog().then((_) => _resetForm());
  }

  void _resetForm() {
    if (mounted) {
      _generatePRNumber(); // get a new PR number

      _formKey.currentState?.reset();
      setState(() {
        _departmentCode = '';
        _requestedBy = '';
        _selectedPriority = null;
        _selectedPRStatus = null;
        _selectedRequiredDate = null;
        _selectedRequestDate = null;
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
        _buildPRNumber(),
        FormGroupCard(
          title: 'Purchase Requisition',
          children: [
            RequestedByAndDepartments(
              onRequestedBy: (id, code, name) =>
                  setState(() => _requestedBy = name),
              onDepartmentChange: (id, code, name) =>
                  setState(() => _departmentCode = code),
            ),
            PriorityAndPRStatusDropdown(
              onPriorityChanged: (s) => setState(() => _selectedPriority = s),
              onStatusChanged: (s) => setState(() => _selectedPRStatus = s),
            ),
          ],
        ),

        FormGroupCard(
          children: [
            DynamicTextFields(
              title: 'Products / Services',
              initialData: [{}],
              showButton: true,
              fieldsConfig: _itemsFieldsConfig,
              onChanged: (List<Map<String, dynamic>> data) {
                if (isFormValid) setState(() {});

                _lineItems
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map((e) => PRLineItem.fromMap(e)));
              },
            ),
          ],
        ),

        FormGroupCard(
          title: 'Request & Required Dates',
          children: [
            RequestAndRequiredDateInput(
              labelRequest: "Required date",
              labelRequired: "Required date",
              onRequestChanged: (date) =>
                  setState(() => _selectedRequestDate = date),
              onRequiredChanged: (date) =>
                  setState(() => _selectedRequiredDate = date),
            ),
          ],
        ),

        FormGroupCard(
          children: [
            DynamicTextFields(
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
            ),
          ],
        ),

        context.confirmableActionButton(
          label: 'Create PR',
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  _buildPRNumber() => Align(
    alignment: Alignment.topLeft,
    child: FittedBox(
      child: context.actionInfoButton(
        'Refresh PR Number',
        count: _newPRNumber,
        bgColor: kPrimaryColor,
        isTotal: false,
        onPressed: _generatePRNumber,
      ),
    ),
  );

  Future _getEmployee(String empId) async {
    final employee = await GetEmployees.byEmployeeId(empId);
    return employee.isEmpty ? null : employee;
  }

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
    if (_newRequisition.isEmpty) return;

    final employee = await _getEmployee(_newRequisition.requestedBy);
    if (employee.isEmpty) return;

    // Log that details were printed
    if (mounted &&
        AuditTracker.shouldLog(
          id: _newRequisition.id,
          type: DocType.prs,
          action: AuditAction.printed,
        )) {
      _updateHistory();
    }
    await PRPrinter(requisite: _newRequisition, employee: employee).printPR();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = AuditProcurement<PurchaseRequisition>(
      documentId: _newRequisition.id,
      log: {
        'history': [
          ..._newRequisition.history.map((e) => e.toMap()), // keep old logs
          AuditLog(
            action: action,
            performedBy: _currentEmployeeId,
          ).toMap(), // new log
        ],
      },
    );
    _readBloc.add(up);
  }

  List<FieldGroupConfig> get _itemsFieldsConfig => [
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
