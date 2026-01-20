import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/extensions/line_item_type.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/data/models/item_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/item_master_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/item_master/widget/item_master_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension IMFormExtensions on BuildContext {
  Future<void> openItemMasterForm({
    ItemMaster? serverItem,
    String? itemType,
    void Function()? onBackPress,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      onBackPress: onBackPress,
      title: serverItem != null
          ? serverItem.name.toTitle
          : 'Create Item Master',
      body: _CreateItemMasterForm(itemType: itemType, serverItem: serverItem),
    ),
  );
}

class _CreateItemMasterForm extends StatefulWidget {
  final ItemMaster? serverItem;
  final String? itemType;

  const _CreateItemMasterForm({this.serverItem, this.itemType});

  @override
  State<_CreateItemMasterForm> createState() => _CreateItemMasterFormState();
}

class _CreateItemMasterFormState extends State<_CreateItemMasterForm> {
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();

  bool get _isFormValid => _formKey.currentState!.validate();

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;
  String get _employeeId => _employee!.employeeId;
  String get _employeeStore => _employee!.storeNumber;

  ItemMasterBloc get _bloc => context.read<ItemMasterBloc>();

  ItemMaster? get _serverItem => widget.serverItem;

  bool get _isServerNull => _serverItem == null;

  String get _itemType =>
      widget.itemType ?? _serverItem?.itemType.getLabel ?? '';

  // Basic fields
  String _imNumber = '';
  bool _isSubmitting = false;
  late ItemMaster _itemMaster = widget.serverItem ?? ItemMaster.empty;

  void _onSubmit() async {
    if (_isSubmitting) return;
    final isUpdate = _serverItem?.isNotEmpty == true;
    final isValid = _isFormValid;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing ItemMaster
    if (isValid && isUpdate) {
      _updatedItemMaster();
      return;
    }

    // Case 2: Form validation or empty ItemMaster
    if (!isValid && _itemMaster.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Add new ItemMaster
    _addNewItemMaster();
  }

  void _addNewItemMaster() {
    final newData = _itemMaster.copyWith(
      sku: _imNumber,
      storeNumber: _employeeStore,
      createdBy: _employeeName,
      history: history(),
    );

    _bloc.add(AddSetup<ItemMaster>(data: newData));
  }

  void _updatedItemMaster() {
    final updated = _itemMaster.copyWith(
      updatedBy: _employeeName,
      history: history(AuditAction.updated),
    );

    _bloc.add(
      UpdateSetup<ItemMaster>(documentId: _itemMaster.id, data: updated),
    );
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _itemMaster = ItemMaster.empty;
      });
      _generateIMNumber(); // fresh IM number
    }
  }

  void _generateIMNumber() async {
    await DocType.itemMaster.getShortUID(
      onChanged: (s) {
        if (mounted) setState(() => _imNumber = s);
      },
    );
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverItem!.history,
    AuditLog(action: action, actionBy: _employeeId),
  ];

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull ? _resetForm() : Navigator.pop(context),
    );
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<ItemMaster> state) {
    final note = _isServerNull ? 'Item created' : 'Changes saved';
    switch (state) {
      case SetupAdded<ItemMaster>(message: var msg):
      case SetupUpdated<ItemMaster>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<ItemMaster>():
        _showAlert('Error saving changes');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _generateIMNumber();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ItemMasterBloc, SetupState<ItemMaster>>(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: KeyedSubtree(key: _formResetKey, child: _buildBody()),
      ),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ItemMasterFormFields.buildIMNumber(
          context,
          _imNumber,
          _generateIMNumber,
        ),

        /// 1️⃣ Basic Item Information + 2️⃣ Classification & Type
        FormGroupCard(
          title: '1. Basic Item Information',
          subTitle:
              '\nKey identification details and description of the $_itemType.',
          children: [_buildNameAndDesc()],
        ),

        /// 3️⃣ Units & Stock Rules
        FormGroupCard(
          isExpanded: false,
          title: '3. Units & Stock Rules',
          subTitle: '\nBase unit of measure and Setup control rules.',
          children: [_baseUOM(), _buildUsageAndAvailability()],
        ),

        /// 4️⃣ Planning & Procurement
        FormGroupCard(
          isExpanded: false,
          title: '4. Planning & Procurement',
          subTitle:
              '\nDefault reorder settings, lead times, and procurement rules.',
          children: [_buildPlanningAndProcurement()],
        ),

        /// 5️⃣ Costing
        FormGroupCard(
          isExpanded: false,
          title: '5. Costing',
          subTitle: '\nStandard costing and valuation method.',
          children: [_buildCosting()],
        ),

        const SizedBox(height: 20),

        context.confirmableActionButton(
          onPressed: _onSubmit,
          isDisabled: _isSubmitting,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Item')
              : (_isSubmitting ? 'Updating...' : null),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNameAndDesc() {
    final itemType = LineItemTypeUtil.fromString(_itemType);

    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.nameAndDescFields(itemType: itemType),
      initialData: [_serverItem?.toMap() ?? {}],
      onChanged: (List<Map<String, dynamic>> data) {
        // if (_isFormValid) setState(() {});
        final i = ItemMaster.fromMap(data.first);

        _itemMaster = _itemMaster.copyWith(
          name: i.name,
          itemType: i.itemType,
          category: i.category,
          description: i.description,
        );
      },
    );
  }

  Widget _baseUOM() {
    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.baseUomFields,
      initialData: [
        {'baseUom': _serverItem?.baseUom.getName},
      ],
      onChanged: (List<Map<String, dynamic>> data) async {
        final i = ItemMaster.fromMap(data.first);

        _itemMaster = _itemMaster.copyWith(baseUom: i.baseUom);
      },
    );
  }

  Widget _buildUsageAndAvailability() {
    final itemType = LineItemTypeUtil.fromString(_itemType);

    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.unitRuleFields(
        initial: _serverItem?.toMap() ?? {},
        isService: itemType.isService,
      ),
      onChanged: (List<Map<String, dynamic>> data) async {
        final i = ItemMaster.fromMap(data.first);

        _itemMaster = _itemMaster.copyWith(
          isActive: i.isActive,
          isSellable: i.isSellable,
          isStockItem: i.isStockItem,
          isPurchasable: i.isPurchasable,
        );
      },
    );
  }

  Widget _buildPlanningAndProcurement() {
    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.planningFields,
      initialData: [_serverItem?.toMap() ?? {}],
      onChanged: (List<Map<String, dynamic>> data) {
        // if (_isFormValid) setState(() {});
        final i = ItemMaster.fromMap(data.first);

        // Add new item master
        _itemMaster = _itemMaster.copyWith(
          reorderPoint: i.reorderPoint,
          reorderQty: i.reorderQty,
          leadTimeDays: i.leadTimeDays,
        );
      },
    );
  }

  Widget _buildCosting() {
    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.costingFields,
      initialData: [
        _serverItem?.pickKeys({'standardCost', 'costingMethod'}) ?? {},
      ],
      onChanged: (List<Map<String, dynamic>> data) {
        // if (_isFormValid) setState(() {});
        final i = ItemMaster.fromMap(data.first);

        // Add new item master
        _itemMaster = _itemMaster.copyWith(
          standardCost: i.standardCost,
          costingMethod: i.costingMethod,
        );
      },
    );
  }
}
