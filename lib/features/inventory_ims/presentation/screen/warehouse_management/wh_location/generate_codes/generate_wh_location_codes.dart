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
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_bin/widget/wh_bin_form_fields.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/widget/search_wh_locations.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_location/widget/wh_location_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension GenerateWhLocationCodesExt on BuildContext {
  Future<void> openGenerateWHLocCodesForm({
    WHLocation? serverItem,
    Function(List<String>)? onCreateCodeRanges,
  }) => openBottomSheet(
    isExpand: false,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetailMode: true,
      title: 'Manage Sub-Location Codes',
      body: _GenerateWHLocCodesForm(
        serverItem: serverItem,
        onCreateCodeRanges: onCreateCodeRanges,
      ),
    ),
  );
}

class _GenerateWHLocCodesForm extends StatefulWidget {
  final WHLocation? serverItem;
  final Function(List<String>)? onCreateCodeRanges;

  const _GenerateWHLocCodesForm({this.serverItem, this.onCreateCodeRanges});

  @override
  State<_GenerateWHLocCodesForm> createState() =>
      _GenerateWHLocCodesFormState();
}

class _GenerateWHLocCodesFormState extends State<_GenerateWHLocCodesForm> {
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prefixController;

  Function? get _onCreateFullBinLocation => widget.onCreateCodeRanges;

  WHLocationBloc get _bloc => context.read<WHLocationBloc>();

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  WHLocation? get _serverItem => widget.serverItem;

  bool get _isServerNull => _serverItem == null;

  String? get _desc => _serverItem?.description;

  bool get _hasCodeRanges => _serverItem?.codeRanges.isNotEmpty == true;

  int? _editingIndex;
  bool _editPrefix = false;
  bool _canGenerate = false;
  bool _isGenerating = false;
  bool _savingPerEdit = false;
  late WHLocation _whLocationData;
  final Map<int, TextEditingController> _controllers = {};

  void _onGenerate() {
    if (_isGenerating) return;

    if (!_canGenerate) {
      _showAlert('Please enter a valid code range.');
      return;
    }

    setState(() => _isGenerating = true);

    // Case 0: Form validation or empty Location
    if (_whLocationData.isEmpty) {
      _showAlert('Invalid range. Start and end values must be different');
      return;
    }

    // Case 1: New Bin creation — return full bin location codes
    if (_isServerNull && _onCreateFullBinLocation != null) {
      _onCreateFullBinLocation?.call(_whLocationData.getCodeRanges);
      _showAlert('Sub-Location codes created');
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
        if (_isGenerating) {
          _formResetKey = UniqueKey();
        }
        _editPrefix = false;
        _canGenerate = false;
        _isGenerating = false;
        _savingPerEdit = false;
        _whLocationData = WHLocation.empty;
      });
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => _resetForm());
  }

  void _handleBlocState(BuildContext cxt, InventoryState<WHLocation> state) {
    final note = _isServerNull
        ? 'Sub-Location Storage created'
        : 'Changes saved';
    switch (state) {
      case InventoryAdded<WHLocation>(message: var msg):
      case InventoryUpdated<WHLocation>(message: var msg):
        _showAlert(msg ?? note);
        _resetForm();
      case InventoryError<WHLocation>():
        _showAlert('Something went wrong! Please, try again');
        _resetForm();
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _whLocationData = widget.serverItem ?? WHLocation.empty;
    _prefixController = TextEditingController(
      text: _desc?.substring(0, 1).toUpperAll ?? '',
    );
  }

  @override
  void dispose() {
    _prefixController.dispose();
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
          child: Column(
            children: [
              FormGroupTabView(contents: formGroupCards),
              const SizedBox(height: 20),
              context.confirmableActionButton(
                onPressed: _canGenerate ? _onGenerate : null,
                isDisabled: _isGenerating || !_canGenerate,
                label: _isGenerating ? 'Generating...' : 'Generate Sub Location',
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get formGroupCards => [
    {
      'title': 'Generate Sub-Location Codes',
      'subTitle':
          '\nGenerate rack, level, shelf, & other code ranges used to create full bin locations.',
      'children': [
        _buildHeader(),
        _buildGenerateCodes(),
      ],
    },

    if (_hasCodeRanges)
      {
        'title': 'Edit Sub-Location Codes',
        'subTitle': '\nManage sub-location codes.',
        'children': [_listSubLocationCodes()],
      },
  ];

  AdaptiveLayout _buildHeader() {
    return AdaptiveLayout(
      children: [
        SearchWHSubLocations(
          enabled: !_hasCodeRanges,
          initialValue: _desc,
          onChanged: (id, whCode, locType, desc) => setState(() {
            _prefixController.text = desc.isNotEmpty ? desc[0].toUpperAll : '';

            if (_desc != desc) {
              // Update id if changed
              _whLocationData = _whLocationData.copyWith(id: id);
            }
          }),
        ),

        WhLocationFormFields.stackTextField(
          context,
          controller: _prefixController,
          enable: _editPrefix,
          label: 'Alphabetic Prefix',
          helperText: 'Prefix for code generation (e.g., A).',
          onPressed: () {
            setState(() => _editPrefix = !_editPrefix);
          },
        ),
      ],
    );
  }

  Widget _buildGenerateCodes() {
    return DynamicTextFields(
      fieldsConfig: WhLocationFormFields.whGenerateCodesFields(),
      onChanged: _validateCodeRange,
    );
  }

  void _validateCodeRange(List<Map<String, dynamic>> data) {
    if (data.isEmpty || data.first.isEmpty) return;

    final map = data.first;

    final codeRange = CodeRange.fromMap(map);
    final start = codeRange.from;
    final end = codeRange.to;

    if (start == end || start > end) {
      setState(() => _canGenerate = false);
      return;
    }

    final prefix = _prefixController.text.trim();
    if (prefix.isEmpty) return;

    final codes = prefix.generateRange(start, end);

    setState(() {
      _whLocationData =
          _whLocationData.copyWith(codeRanges: codes.join(','));
      _canGenerate = true;
    });
  }

  /// Showing the List of sub-location codes
  SortableHistoryTable<String> _listSubLocationCodes() {
    final codes = _serverItem?.getCodeRanges ?? [];
    final desc = _whLocationData.description.toSentence;
    return WHBinFormFields.listBinLocations(
      context: context,
      codes: codes,
      desc: desc,
      onEdit: (isEdit, index, controller) {
        _onEditPerSubLocation(isEdit, codes, index, controller);
      },
      controllers: _controllers,
      editingIndex: _editingIndex,
      savingPerEdit: _savingPerEdit,
    );
  }

  void _onEditPerSubLocation(
    bool isEditing,
    List<String> codes,
    int index,
    TextEditingController controller,
  ) {
    setState(() {
      if (isEditing) {
        // DONE pressed → save
        _savingPerEdit = true;
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

/*
  TextEditingController _getController(int index, String value) {
    return _controllers.putIfAbsent(
      index,
      () => TextEditingController(text: value),
    );
  }

return SortableHistoryTable<String>(
      items: codes,
      columnLabels: ['#', 'Description', 'Codes'],
      rowBuilder: (entry, index) {
        final i = index + 1;
        final isEditing = _editingIndex == index;
        final controller = _getController(index, entry);

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
                showProgress: _savingPerEdit,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  labelText: 'Code',
                ),
                onPressed: () =>
                    _onEditPerSubLocation(isEditing, codes, index, controller),
              ),
            ),
          ],
        );
      },
    );*/
