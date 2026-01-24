import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_location_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/wh_location_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/widget/search_wh_locations.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/widget/wh_location_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension GenerateWhLocationCodesExt on BuildContext {
  Future<void> openGenerateWHLocCodesForm({WHLocation? serverItem}) =>
      openBottomSheet(
        isExpand: false,
        showZoomIcon: false,
        child: BottomSheetScaffold(
          title: 'Generate Sub-Location Codes',
          body: _GenerateWHLocCodesForm(serverItem: serverItem),
        ),
      );
}

class _GenerateWHLocCodesForm extends StatefulWidget {
  final WHLocation? serverItem;

  const _GenerateWHLocCodesForm({this.serverItem});

  @override
  State<_GenerateWHLocCodesForm> createState() =>
      _GenerateWHLocCodesFormState();
}

class _GenerateWHLocCodesFormState extends State<_GenerateWHLocCodesForm> {
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prefixController;
  bool get _isFormValid => _formKey.currentState!.validate();

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  WHLocationBloc get _bloc => context.read<WHLocationBloc>();

  WHLocation? get _serverItem => widget.serverItem;

  bool get _isServerNull => _serverItem == null;

  List<String> get _existingCodes => _serverItem?.codeRanges ?? [];

  // Basic fields
  String _whLocationCode = '';
  bool _isSubmitting = false;
  bool _enableEdit = false;
  late WHLocation _whLocationData = widget.serverItem ?? WHLocation.empty;

  void _onSubmit() async {
    if (_isSubmitting) return;
    final isUpdate = _serverItem?.isNotEmpty == true;
    final isValid = _isFormValid;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Location
    if (isValid && isUpdate) {
      _updatedLocation();
      return;
    }

    // Case 2: Form validation or empty Location
    if (!isValid && _whLocationData.isNullOrEmpty) {
      prettyPrint('_whLocationData', _whLocationData.toMap());
      _showAlert('Please enter all required fields');
      return;
    }
  }

  void _updatedLocation() {
    final updated = _whLocationData.copyWith(updatedBy: _employeeName);

    _bloc.add(
      UpdateInventory<WHLocation>(
        documentId: _whLocationData.id,
        data: updated,
      ),
    );
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _whLocationData = WHLocation.empty;
      });
      _generateWHLocCode(); // fresh Warehouse location code
    }
  }

  void _generateWHLocCode([String? prefix]) {
    /*// Get existing codes, if any and add new prefix
    Set<String> newCodesList = {};
    if (prefix.hasValue) {
      newCodesList.add(prefix!);
    }

    List<String>? eCodes = [...newCodesList, ...?_existingCodes];*/
    // Get selected Location type
    final pref = _serverItem?.getLocType ?? prefix;

    var nextLocationCode = pref?.nextLocationCode(_existingCodes) ?? '';
    if (_whLocationCode != nextLocationCode) {
      setState(() => _whLocationCode = nextLocationCode);
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => _resetForm());
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, InventoryState<WHLocation> state) {
    final note = _isServerNull
        ? 'Warehouse Location Storage created'
        : 'Changes saved';
    switch (state) {
      case InventoryAdded<WHLocation>(message: var msg):
      case InventoryUpdated<WHLocation>(message: var msg):
        _showAlert(msg ?? note);
      case InventoryError<WHLocation>(error: var err):
        _showAlert('Error saving changes $err');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _prefixController = TextEditingController(
      text: _serverItem?.getLocType.substring(0, 1).toUpperAll ?? '',
    );
    // _generateWHLocCode();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WHLocationBloc, InventoryState<WHLocation>>(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: KeyedSubtree(key: _formResetKey, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    return FormGroupCard(
      title: 'Generate Code Segments',
      subTitle:
          '\nGenerate rack, level, shelf, & other code ranges used to create full bin locations.',
      children: [
        _buildHeader(),
        _buildGenerateCodes(),
        const SizedBox(height: 20),
        context.confirmableActionButton(
          onPressed: _onSubmit,
          isDisabled: _isSubmitting,
          label: _isSubmitting ? 'Generating...' : 'Generate',
        ),
        const SizedBox(height: 20),
        _listSubLocationCodes(),
      ],
    );
  }

  SortableHistoryTable<String> _listSubLocationCodes() {
    return SortableHistoryTable<String>(
      items: _serverItem?.codeRanges ?? [],
      columnLabels: ['Sub-Location', 'Codes'],
      rowBuilder: (entry) {
        return DataRow(
          cells: [
            DataCell(Text(_serverItem?.getLocType.toSentence ?? '')),
            DataCell(Text(entry.toUpperAll)),
          ],
        );
      },
    );
  }

  AdaptiveLayout _buildHeader() {
    return AdaptiveLayout(
      children: [
        SearchWHLocation(
          initialValue: _serverItem?.getLocType,
          onChanged: (id, whCode, locType) => setState(() {
            _prefixController.text = locType.isNotEmpty
                ? locType[0].toUpperAll
                : '';
          }),
        ),

        Stack(
          alignment: Alignment.topRight,
          children: <Widget>[
            CustomTextField(
              enable: _enableEdit,
              label: 'Alphabetic Prefix',
              controller: _prefixController,
              keyboardType: TextInputType.text,
              inputDecoration: const InputDecoration(
                helperText: 'Prefix for code generation (e.g., A).',
              ),
            ),

            Padding(
              padding: EdgeInsets.all(3),
              child: context.toolbarButton(
                label: 'Edit',
                icon: Icons.edit,
                bgColor: kPrimaryColor,
                onPressed: () {
                  setState(() => _enableEdit = !_enableEdit);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenerateCodes() {
    return DynamicTextFields(
      fieldsConfig: WhLocationFormFields.whGenerateCodesFields(),
      onChanged: (List<Map<String, dynamic>> data) {
        final map = data.first;
        int from = '${map['from']}'.asInt;
        int to = '${map['to']}'.asInt;

        final locCodeRange = _prefixController.text.generateRange(from, to);
        setState(
          () => _whLocationData = _whLocationData.copyWith(
            codeRange: locCodeRange.map((e) => e).join(','),
          ),
        );
      },
    );
  }
}
