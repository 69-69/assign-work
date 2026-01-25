import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
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
          isDetailMode: true,
          title: 'Setup Sub-Location Codes',
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

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  WHLocationBloc get _bloc => context.read<WHLocationBloc>();

  WHLocation? get _serverItem => widget.serverItem;

  int? _editingIndex;
  bool _enableEdit = false;
  bool _canGenerate = false;
  bool _isSubmitting = false;
  late WHLocation _whLocationData;
  final Map<int, TextEditingController> _controllers = {};

  void _onGenerate() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Form validation or empty Location
    if (!_canGenerate || _serverItem?.isEmpty == true) {
      _showAlert('Failed: Enter range values to generate codes.');
      return;
    }

    // Case 2: Generate & Update Location code ranges
    _updatedLocation();
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
        _canGenerate = false;
        _enableEdit = false;
        _whLocationData = WHLocation.empty;
      });
    }
  }

  TextEditingController _getController(int index, String value) {
    return _controllers.putIfAbsent(
      index,
      () => TextEditingController(text: value),
    );
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => _resetForm());
  }

  void _handleBlocState(BuildContext cxt, InventoryState<WHLocation> state) {
    final note = _serverItem == null
        ? 'Warehouse Location Storage created'
        : 'Changes saved';
    switch (state) {
      case InventoryAdded<WHLocation>(message: var msg):
      case InventoryUpdated<WHLocation>(message: var msg):
        _showAlert(msg ?? note);
      case InventoryError<WHLocation>():
        _showAlert('Error saving changes');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _whLocationData = widget.serverItem ?? WHLocation.empty;
    _prefixController = TextEditingController(
      text: _serverItem?.getLocType.substring(0, 1).toUpperAll ?? '',
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WHLocationBloc, InventoryState<WHLocation>>(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: KeyedSubtree(
          key: _formResetKey,
          child: FormGroupTabView(contents: formGroupCards),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get formGroupCards => [
    {
      'title': 'Generate Code Segments',
      'subTitle':
          '\nGenerate rack, level, shelf, & other code ranges used to create full bin locations.',
      'children': [
        _buildHeader(),
        _buildGenerateCodes(),
        const SizedBox(height: 20),
        context.confirmableActionButton(
          onPressed: _onGenerate,
          isDisabled: _isSubmitting,
          label: _isSubmitting ? 'Generating...' : 'Generate',
        ),
      ],
    },

    if (_serverItem?.codeRanges.isNotEmpty == true)
      {
        'title': 'Edit Sub-Location Codes',
        'subTitle': '\nManage sub-location codes.',
        'children': [_listSubLocationCodes()],
      },
  ];

  AdaptiveLayout _buildHeader() {
    return AdaptiveLayout(
      children: [
        SearchWHLocation(
          initialValue: _serverItem?.getLocType,
          onChanged: (id, whCode, locType) => setState(() {
            _prefixController.text = locType.isNotEmpty
                ? locType[0].toUpperAll
                : '';

            if (_serverItem?.getLocType != locType) {
              // Update id if changed
              _whLocationData = _whLocationData.copyWith(id: id);
            }
          }),
        ),

        WhLocationFormFields.stackTextField(
          context,
          controller: _prefixController,
          enable: _enableEdit,
          label: 'Alphabetic Prefix',
          helperText: 'Prefix for code generation (e.g., A).',
          onPressed: () {
            setState(() => _enableEdit = !_enableEdit);
          },
        ),
      ],
    );
  }

  Widget _buildGenerateCodes() {
    return DynamicTextFields(
      fieldsConfig: WhLocationFormFields.whGenerateCodesFields(),
      onChanged: (List<Map<String, dynamic>> data) {
        final codeRange = CodeRange.fromMap(data.first);
        if (codeRange.isEmpty) _canGenerate = false;

        final codes = _prefixController.text.generateRange(
          codeRange.from,
          codeRange.to,
        );
        setState(
          () => _whLocationData = _whLocationData.copyWith(
            codeRanges: codes.map((e) => e).join(','),
          ),
        );
      },
    );
  }

  SortableHistoryTable<String> _listSubLocationCodes() {
    final codes = _serverItem?.getCodeRanges ?? [];

    return SortableHistoryTable<String>(
      title: 'Generation Preview',
      items: codes,
      columnLabels: ['#', 'Description', 'Codes'],
      rowBuilder: (entry, index) {
        final i = index + 1;
        final isEditing = _editingIndex == index;
        final controller = _getController(index, entry);
        final desc = _whLocationData.getLocType.toSentence;

        return DataRow(
          cells: [
            DataCell(Text('$i')),
            DataCell(Text('$desc $i')),
            DataCell(
              WhLocationFormFields.stackTextField(
                context,
                key: ValueKey('code-$index'),
                controller: controller,
                enable: isEditing,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  labelText: 'Code',
                ),
                onPressed: () =>
                    _onManageCode(isEditing, codes, index, controller),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onManageCode(
    bool isEditing,
    List<String> codes,
    int index,
    TextEditingController controller,
  ) {
    setState(() {
      if (isEditing) {
        // DONE pressed → save
        codes[index] = controller.text.toUpperAll;

        _whLocationData = _whLocationData.copyWith(codeRanges: codes.join(','));

        _editingIndex = null;
      } else {
        // EDIT pressed
        _editingIndex = index;
      }
    });

    // trigger submission after state updates
    if (isEditing) {
      _updatedLocation(); // Update specific Location code ranges
    }
  }
}
