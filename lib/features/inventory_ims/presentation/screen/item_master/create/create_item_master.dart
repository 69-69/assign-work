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
import 'package:assign_erp/features/inventory_ims/presentation/screen/item_master/widget/item_master_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
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
      title: '${serverItem != null ? 'Edit' : 'Create'} Item Master',
      subtitle: serverItem?.name.toTitle ?? '',
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

  // String get _employeeId => _employee!.employeeId;
  String get _employeeName => _employee!.fullName;

  String get _employeeStore => _employee!.storeNumber;

  ItemMasterBloc get _bloc => context.read<ItemMasterBloc>();

  ItemMaster? get _serverMater => widget.serverItem;

  bool get _nullServer => _serverMater == null;

  String get _itemType => widget.itemType ?? '';

  // Basic fields
  String _itemMasterNumber = '';
  bool _isSubmitting = false;
  ItemMaster _newMaster = ItemMaster.empty;

  void _onSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing ItemMaster
    if (_serverMater != null) {
      _updateItemMaster();
      return;
    }

    // Case 2: Form validation or empty ItemMaster
    if (!_isFormValid && (_serverMater?.isNullOrEmpty ?? true)) {
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
    final updated = _serverMater?.copyWith(
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
          _serverMater != null ? Navigator.pop(context) : _resetForm(),
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
          subTitle: '\nBase unit of measure and inventory control rules.',
          children: [_buildUsageAndAvailability()],
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
          label: _nullServer ? 'Create Item' : '',
          onPressed: _onSubmit,
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNameAndDesc() {
    final itemType =
        _serverMater?.itemType ?? LineItemTypeUtil.fromString(_itemType);

    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.nameAndDescFields(itemType: itemType),
      initialData: [_serverMater?.toMap() ?? {}],
      onChanged: (List<Map<String, dynamic>> data) {
        // if (_isFormValid) setState(() {});
        final i = ItemMaster.fromMap(data.first);

        _newMaster = _newMaster.copyWith(
          name: i.name,
          description: i.description,
        );
      },
    );
  }

  Widget _buildUsageAndAvailability() {
    return DynamicTextFields(
      fullWidthKey: 'baseUom',
      // initialData: [_serverMater?.toMap() ?? {}],
      fieldsConfig: ItemMasterFormFields.unitRuleFields(
        initial: _serverMater?.toMap() ?? {},
      ),
      onChanged: (List<Map<String, dynamic>> data) {
        // if (_isFormValid) setState(() {});
        final i = ItemMaster.fromMap(data.first);

        _newMaster = _newMaster.copyWith(
          baseUom: i.baseUom,
          isActive: i.isActive,
          isSellable: i.isSellable,
          isPurchasable: i.isPurchasable,
        );
      },
    );
  }

  Widget _buildPlanningAndProcurement() {
    return DynamicTextFields(
      fieldsConfig: ItemMasterFormFields.planningFields,
      initialData: [_serverMater?.toMap() ?? {}],
      onChanged: (List<Map<String, dynamic>> data) {
        // if (_isFormValid) setState(() {});
        final i = ItemMaster.fromMap(data.first);

        // Add new item master
        _newMaster = _newMaster.copyWith(
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
        _serverMater?.pickKeys({'standardCost', 'costingMethod'}) ?? {},
      ],
      onChanged: (List<Map<String, dynamic>> data) {
        // if (_isFormValid) setState(() {});
        final i = ItemMaster.fromMap(data.first);

        // Add new item master
        _newMaster = _newMaster.copyWith(
          standardCost: i.standardCost,
          costingMethod: i.costingMethod,
        );
      },
    );
  }
}
