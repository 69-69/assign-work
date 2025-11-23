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

  String? _requestedBy;
  String? _departmentCode;
  String? _selectedPriority;
  String? _selectedPRStatus;
  DateTime? _selectedRequiredDate;
  DateTime? _selectedRequestDate;

  // Add a list to manage line items
  final List<PRLineItem> _lineItems = [];
  final Map<String, dynamic> _purposeForPR = {};

  PurchaseRequisition get _serverRequisite => widget.requisite;

  bool get isFormValid => _formKey.currentState?.validate() ?? false;

  String get _currentEmployeeId => context.employee!.employeeId;

  ProPurchaseRequisiteBloc get _readBloc =>
      context.read<ProPurchaseRequisiteBloc>();

  AuditAction get _action => _selectedPRStatus!.contains('approved')
      ? AuditAction.approved
      : AuditAction.updated;

  @override
  void initState() {
    super.initState();
    _purposeForPR.addAll({'purpose': _serverRequisite.purpose});
    _lineItems.addAll(_serverRequisite.lineItems);
  }

  @override
  void dispose() {
    super.dispose();
  }

  PurchaseRequisition get _updatedRequisite => _serverRequisite.copyWith(
    priority: PriorityHelper.fromString(
      _selectedPriority ?? _serverRequisite.priority.getValue,
    ),
    status: PRStatusHelper.fromString(
      _selectedPRStatus ?? _serverRequisite.status.getValue,
    ),
    requestedBy: _requestedBy ?? _serverRequisite.requestedBy,
    departmentCode: _departmentCode ?? _serverRequisite.departmentCode,
    neededByDate: _selectedRequiredDate ?? _serverRequisite.neededByDate,
    requestDate: _selectedRequestDate ?? _serverRequisite.requestDate,
    purpose: _purposeForPR['purpose'],
    lineItems: List.from(_lineItems),
    updatedBy: context.employee!.fullName,
    history: [
      ..._serverRequisite.history, // keep all old logs
      AuditLog(action: _action, performedBy: _currentEmployeeId),
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

    final bloc = _readBloc;
    bloc.add(
      UpdateProcurement<PurchaseRequisition>(
        documentId: _updatedRequisite.id,
        data: _updatedRequisite,
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
            RequestedByAndDepartments(
              initialDepartment: _serverRequisite.departmentCode,
              initialRequestedBy: _serverRequisite.requestedBy,
              onRequestedBy: (id, code, name) =>
                  setState(() => _requestedBy = name),
              onDepartmentChange: (id, code, name) =>
                  setState(() => _departmentCode = code),
            ),
            PriorityAndPRStatusDropdown(
              initialPriority: _serverRequisite.priority.getValue,
              initialStatus: _serverRequisite.status.getValue,
              onPriorityChanged: (s) => setState(() => _selectedPriority = s),
              onStatusChanged: (s) => setState(() => _selectedPRStatus = s),
            ),
          ],
        ),

        FormGroupCard(
          children: [
            DynamicTextFields(
              title: 'Products / Services',
              showButton: true,
              fieldsConfig: _itemsFieldsConfig,
              initialData: _serverRequisite.lineItems
                  .map((e) => e.toMap())
                  .toList(),
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
              initialRequiredDate: _serverRequisite.getNeededByDate,
              initialRequestDate: _serverRequisite.getRequestDate,
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
              initialData: [
                {'purpose': _serverRequisite.purpose},
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
            ),
          ],
        ),

        context.confirmableActionButton(onPressed: _onSubmit),
        const SizedBox(height: 20.0),
      ],
    );
  }

  Future _getEmployee(String empId) async {
    final employee = await GetEmployees.byEmployeeId(empId);
    return employee.isEmpty ? null : employee;
  }

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
    if (_updatedRequisite.isEmpty) return;

    final employee = await _getEmployee(_updatedRequisite.requestedBy);
    if (employee.isEmpty) return;

    _updateHistory();
    await PRPrinter(requisite: _updatedRequisite, employee: employee).printPR();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = AuditProcurement<PurchaseRequisition>(
      documentId: _updatedRequisite.id,
      log: {
        'history': [
          ..._updatedRequisite.history.map((e) => e.toMap()), // keep old logs
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
