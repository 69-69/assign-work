import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/form_group_card_model.dart';
import 'package:assign_erp/core/util/extensions/form_validity.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_wh_locations.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/wh_bin_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/wh_bin_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/warehouse/widget/search_warehouse.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/wh_bin/widget/wh_bin_form_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension WHBinLocationsExtensions on BuildContext {
  Future<void> openWHBinLocationsForm({
    WHBin? serverItem,
    Function(List<String>)? onCreateFullBinLocation,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: 'Generate Full Bin Locations',
      body: _CreateWHBinLocationsForm(
        serverItem: serverItem,
        onCreateFullBinLocation: onCreateFullBinLocation,
      ),
    ),
  );
}

class _CreateWHBinLocationsForm extends StatefulWidget {
  final WHBin? serverItem;
  final Function(List<String>)? onCreateFullBinLocation;

  const _CreateWHBinLocationsForm({
    this.serverItem,
    this.onCreateFullBinLocation,
  });

  @override
  State<_CreateWHBinLocationsForm> createState() =>
      _CreateWHBinLocationsFormState();
}

class _CreateWHBinLocationsFormState extends State<_CreateWHBinLocationsForm> {
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  List<String> _fullBinLocationCodes = [];
  List<Map<String, dynamic>>? _subLocations = [];

  bool _isFormValid = false;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  WHBinBloc get _bloc => context.read<WHBinBloc>();

  WHBin? get _serverItem => widget.serverItem;

  bool get _isServerNull => _serverItem == null;

  bool get _hasFullBinLoc => _serverItem?.fullBinLocations.isNotEmpty == true;

  // Basic fields
  bool _isGenerating = false;
  bool _canGenerate = false;
  int? _editingIndex;
  bool _savingPerEdit = false;
  final Map<int, TextEditingController> _controllers = {};
  late WHBin _whBinData = widget.serverItem ?? WHBin.empty;

  Function? get _onCreateFullBinLocation => widget.onCreateFullBinLocation;

  void _syncValidity() => _formKey.syncValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _onSavePressed() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    // Case 0: Form validation or empty WHBin
    if (!_canGenerate || !_isFormValid || _fullBinLocationCodes.isNullOrEmpty) {
      _showAlert(
        'Failed: Select warehouse and its corresponding sub-location ranges',
      );
      setState(() => _isGenerating = false);
      return;
    }

    // Case 1: New Bin creation — return full bin location codes
    if (_isServerNull) {
      _onCreateFullBinLocation?.call(_fullBinLocationCodes);
      _showAlert('Full Bin Locations created');
      return;
    }

    // Case 2: Valid form and existing WHBin — update full bin locations
    _onUpdateFullBinLocations();
  }

  void _onUpdateFullBinLocations() {
    final updated = _whBinData.copyWith(
      updatedBy: _employeeName,
      fullBinLocations: _fullBinLocationCodes.join(','),
    );

    _bloc.add(UpdateSetup<WHBin>(documentId: _whBinData.id, data: updated));
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isGenerating = false;
        _canGenerate = false;
        _whBinData = WHBin.empty;
        _subLocations = [];
        _fullBinLocationCodes.clear();
      });
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => _resetForm());
    setState(() => _isGenerating = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<WHBin> state) {
    final note = _isServerNull ? 'Full Bin Locations created' : 'Changes saved';
    switch (state) {
      case SetupAdded<WHBin>(message: var msg):
      case SetupUpdated<WHBin>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<WHBin>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void dispose() {
    // _bloc.close();
    _subLocations = null;
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WHBinBloc, SetupState<WHBin>>(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: KeyedSubtree(
          key: _formResetKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Title(
                color: kGrayBlueColor,
                child: Text.rich(
                  TextSpan(
                    text: ' Note: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text:
                            'Create sub-location codes before generating full bin-locations.',
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              ),
              FormGroupTabView(contents: formGroupCards),

              if (_subLocations.hasValue) ...[
                const SizedBox(height: 10),
                context.confirmableActionButton(
                  onSubmit: _onSavePressed,
                  isDisabled: _isGenerating || !_isFormValid,
                  submitLabel: _isGenerating
                      ? 'Generating...Please wait'
                      : 'Generate Bin Locations',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<FormGroupCardModel> get formGroupCards => [
    FormGroupCardModel(
      title: 'Create Full Bin Locations',
      subTitle:
          '\nGenerate fully qualified bin location codes for the selected warehouse.'
          '\ne.g., Z01-A01-R01-L01-S01',
      builder: () => [
        SizedBox(
          width: context.dynamicWidth(0.25),
          child: SearchWarehouses(
            onChanged: (id, whCode, locType) async {
              final subLevels = await GetWHLocations.subLocations(whCode);
              setState(() {
                _whBinData = _whBinData.copyWith(warehouseCode: whCode);
                _subLocations = subLevels;
              });
            },
          ),
        ),
        if (_subLocations.hasValue) ...{_fullBinLocFormFields()},
      ],
    ),

    if (_hasFullBinLoc)
      FormGroupCardModel(
        title: 'Edit Full Bin Locations',
        subTitle: '\nManage bin locations.',
        builder: () => [_listBinLocations()],
      ),
  ];

  DynamicTextFields _fullBinLocFormFields() {
    return DynamicTextFields(
      fieldsConfig: WHBinFormFields.whBinLocationCodesFields(
        subLocations: _subLocations,
      ),
      onChanged: (List<Map<String, dynamic>> data) {
        if (data.isEmpty || data.first.isEmpty || !_subLocations.hasValue) {
          return;
        }

        final map = data.first;

        try {
          _fullBinLocationCodes = generateFullBinLocations(map, _subLocations);
          setState(() => _canGenerate = true);
          _syncValidity();
        } catch (e) {
          // context.showAlertOverlay(e.toString()); // show validation error
        }
      },
    );
  }

  List<String> generateFullBinLocations(
    Map<String, dynamic> map,
    List<Map<String, dynamic>>? subLocations,
  ) {
    if (subLocations == null || subLocations.isEmpty) return [];

    List<List<String>> levels = [];

    for (final sub in subLocations) {
      final type = sub['type'];
      final from = map['${type}_from']?.toString();
      final to = map['${type}_to']?.toString();

      if (from == null || to == null) continue;

      // Validate range
      if (from.compareTo(to) > 0) {
        context.showAlertOverlay(
          'Invalid ${type.toString().toUpperAll} range. "$from" must be less than "$to".',
        );
      }

      // Generate the codes for this level
      levels.add(generateBinLocationsCode(from, to));
    }

    return combineLevels(levels);
  }

  /// Showing the List of full bin locations
  SortableHistoryTable<String> _listBinLocations() {
    final codes = _serverItem?.getFullBinLocations ?? [];
    final desc = _whBinData.description.toSentence;
    return WHBinFormFields.listBinLocations(
      context: context,
      codes: codes,
      desc: desc,
      title: 'Bin Locations',
      onEdit: (isEdit, index, controller) {
        _onEditPerBinLocation(isEdit, codes, index, controller);
      },
      controllers: _controllers,
      editingIndex: _editingIndex,
      savingPerEdit: _savingPerEdit,
    );
  }

  void _onEditPerBinLocation(
    bool isEditing,
    List<String> codes,
    int index,
    TextEditingController controller,
  ) {
    setState(() {
      if (isEditing) {
        // DONE pressed → save
        codes[index] = controller.text.toUpperAll;

        // Set the modified codes
        _fullBinLocationCodes = codes;

        _editingIndex = null;
      } else {
        // EDIT pressed
        _editingIndex = index;
      }
    });

    // trigger submission after state updates
    if (isEditing) {
      _savingPerEdit = true;
      _onUpdateFullBinLocations(); // Update specific Bin Locations
    }
  }
}

/* return SortableHistoryTable<String>(
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
              WHBinFormFields.stackTextField(
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
                    _onEditPerBinLocation(isEditing, codes, index, controller),
              ),
            ),
          ],
        );
      },
    );

Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FormGroupCard(
          title: 'Generate Bin Locations',
          subTitle:
              '\nGenerate fully qualified bin location codes for the selected warehouse.'
              '\ne.g., Z01-A01-R01-L01-S01',
          children: [
            SizedBox(
              width: context.dynamicWidth(0.25),
              child: SearchWarehouses(
                onChanged: (id, whCode, locType) async {
                  final subLevels = await GetWHLocations.subLocations(whCode);
                  setState(() {
                    _whBinData = _whBinData.copyWith(warehouseCode: whCode);
                    _subLocations = subLevels;
                  });
                },
              ),
            ),
            if (_subLocations.hasValue) ...{_buildBinInfo()},
          ],
        ),

        const SizedBox(height: 20),
        context.confirmableActionButton(
          onPressed: _onGenerate,
          isDisabled: _isSubmitting,
          label: _isServerNull
              ? (_isSubmitting ? 'Generating...' : 'Generate Bin Locations')
              : (_isSubmitting ? 'Updating...' : null),
        ),
        const SizedBox(height: 20),
      ],
    );
  }*/
