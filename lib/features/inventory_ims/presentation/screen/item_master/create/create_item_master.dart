import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/extensions/line_item_type.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_master_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/item_master/item_master_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/stock_management/item_master/widget/item_master_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension IMFormExtensions on BuildContext {
  Future<void> openItemMasterForm({ItemMaster? serverItem}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      initialSize: 0.94,
      title: '${serverItem != null ? 'Edit' : 'Create'} Item Master',
      subtitle: serverItem?.name.toTitle ?? '',
      body: _CreateItemMasterForm(serverItem: serverItem),
    ),
  );
}

class _CreateItemMasterForm extends StatefulWidget {
  final ItemMaster? serverItem;

  const _CreateItemMasterForm({this.serverItem});

  @override
  State<_CreateItemMasterForm> createState() => _CreateItemMasterFormState();
}

class _CreateItemMasterFormState extends State<_CreateItemMasterForm> {
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();

  bool get _isFormValid => _formKey.currentState!.validate();

  // Current employee info
  Employee? get _employee => context.employee;

  // String get _employeeId => _employee!.employeeId;
  String get _employeeName => _employee!.fullName;

  String get _employeeStore => _employee!.storeNumber;

  ItemMasterBloc get _bloc => context.read<ItemMasterBloc>();

  ItemMaster? get _serverItemMater => widget.serverItem;

  bool get _nullServer => _serverItemMater == null;

  // Basic fields
  String _itemMasterNumber = '';
  bool _isSubmitting = false;
  ItemMaster _newMaster = ItemMaster.empty;

  void _onSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing ItemMaster
    if (_serverItemMater != null) {
      _updateItemMaster();
      return;
    }

    // Case 2: Form validation or empty ItemMaster
    if (!_isFormValid && (_serverItemMater?.isNullOrEmpty ?? true)) {
      _showErrorAlert('Please enter all required fields', kDangerColor);
      return;
    }

    // Case 3: Add new ItemMaster
    _addNewItemMaster();
  }

  void _addNewItemMaster() {
    final newItemMaster = _newMaster.copyWith(
      storeNumber: _employeeStore,
      sku: _itemMasterNumber,
      createdBy: _employeeName,
      history: history(),
    );

    _bloc.add(AddInventory<ItemMaster>(data: newItemMaster));
    _showSuccessAlert('Item Master successfully created');
  }

  void _updateItemMaster() {
    final updated = _serverItemMater?.copyWith(
      id: _newMaster.id,
      updatedBy: _employee!.fullName,
      history: history(AuditAction.updated),
    );

    _bloc.add(
      UpdateInventory<ItemMaster>(documentId: updated!.id, data: updated),
    );
    _showSuccessAlert('Changes successfully saved');
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _newMaster = ItemMaster.empty;
      });
      _generateIMNumber(); // fresh IM number
    }
  }

  void _generateIMNumber() async {
    await DocType.itemMaster.getShortUID(
      onChanged: (s) {
        if (mounted) setState(() => _itemMasterNumber = s);
      },
    );
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    AuditLog(action: action, actionBy: _employee!.employeeId),
  ];

  void _showSuccessAlert(String message) {
    context.showAlertOverlay(
      message,
      onCallback: () =>
          _serverItemMater != null ? Navigator.pop(context) : _resetForm(),
    );
  }

  void _showErrorAlert(String message, Color bgColor) {
    context.showAlertOverlay(message, bgColor: bgColor);
    setState(() => _isSubmitting = false);
  }

  @override
  void initState() {
    super.initState();
    _generateIMNumber();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: KeyedSubtree(key: _formResetKey, child: _buildBody()),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ItemMasterFormFields.buildIMNumber(
          context,
          _itemMasterNumber,
          _generateIMNumber,
        ),

        /// 1️⃣ Basic Item Information
        FormGroupCard(
          title: '1. Basic Item Information',
          subTitle: '\nItem identity and description.',
          children: [_buildNameAndDesc()],
        ),

        /// 2️⃣ Classification & Type
        FormGroupCard(
          isExpanded: false,
          title: '2. Classification & Type',
          subTitle: '\nCategory and item behavior.',
          children: [_buildClassAndType()],
        ),

        /// 3️⃣ Units & Stock Rules
        FormGroupCard(
          isExpanded: false,
          title: '3. Units & Stock Rules',
          subTitle: '\nBase unit and stock control.',
          children: [_buildUsageAndAvailability()],
        ),

        /// 4️⃣ Planning & Procurement
        FormGroupCard(
          isExpanded: false,
          title: '4. Planning & Procurement',
          subTitle: '\nReordering and lead time defaults.',
          children: [_buildPlanningAndProcurement()],
        ),

        /// 5️⃣ Costing
        FormGroupCard(
          isExpanded: false,
          title: '5. Costing',
          subTitle: '\nDefault valuation settings.',
          children: [_buildCosting()],
        ),

        const SizedBox(height: 20),

        context.confirmableActionButton(
          label: _nullServer ? 'Create Item' : '',
          onPressed: _onSubmit,
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNameAndDesc() {
    return DynamicTextFields(
      fullWidthKey: 'category',
      fieldsConfig: ItemMasterFormFields.classifyFields(
        itemType: _newMaster.itemType,
      ),
      initialData: [
        {
          'category': _serverItemMater?.categoryId ?? '',
          ?_serverItemMater?.itemType.getName:
              _serverItemMater?.itemType.getName,
        },
      ],
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        // Add new item master
        _newMaster = _newMaster.copyWith(
          categoryId: data.first['category'] ?? '',
          itemType: data.first['itemType'] ?? '',
        );
      },
    );
  }

  Widget _buildClassAndType() {
    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.identifyFields,
      initialData: [
        {
          'name': _serverItemMater?.name ?? '',
          'description': _serverItemMater?.description ?? '',
        },
      ],
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        // Add new item master
        _newMaster = _newMaster.copyWith(
          name: data.first['name'] ?? '',
          description: data.first['description'] ?? '',
        );
      },
    );
  }

  Widget _buildUsageAndAvailability() {
    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.unitRuleFields(
        initial: _nullServer
            ? {}
            : _serverItemMater!.pickKeys({
                'isActive',
                'isService',
                'isSellable',
                'isStockItem',
                'isPurchasable',
              }),
      ),
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        // Add new item master
        _newMaster = _newMaster.copyWith(
          baseUom: data.first['baseUom'] ?? '',
          isActive: data.first['isActive'] ?? false,
          isSellable: data.first['isSellable'] ?? false,
          isPurchasable: data.first['isPurchasable'] ?? false,
        );
      },
    );
  }

  Widget _buildPlanningAndProcurement() {
    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.planningFields,
      initialData: [
        _serverItemMater!.pickKeys({
          'reorderPoint',
          'reorderQty',
          'leadTimeDays',
        }),
      ],
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        // Add new item master
        _newMaster = _newMaster.copyWith(
          reorderPoint: data.first['reorderPoint'],
          reorderQty: data.first['reorderQty'],
          leadTimeDays: data.first['leadTimeDays'],
        );
      },
    );
  }

  Widget _buildCosting() {
    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.costingFields,
      initialData: [
        _serverItemMater!.pickKeys({'standardCost', 'costingMethod'}),
      ],
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        // Add new item master
        _newMaster = _newMaster.copyWith(
          standardCost: data.first['standardCost'],
          costingMethod: data.first['costingMethod'],
        );
      },
    );
  }
}

/*


FormGroupCard(
  title: '1. Identification',
  children: [_buildSKU(), _buildName(), _buildDescription(), _buildItemType()],
),

FormGroupCard(
  title: '2. Inventory & Units',
  children: selectedItemType != LineItemType.service
      ? [_buildBaseUOM(), _buildIsStockItem(), _buildReorderPoint(), _buildReorderQty(), _buildLeadTimeDays(), _buildCostingMethod()]
      : [],
),

FormGroupCard(
  title: '3. Costing',
  children: [_buildStandardCost()],
),

FormGroupCard(
  title: '4. Classification',
  children: [_buildCategorySelector()],
),*/
