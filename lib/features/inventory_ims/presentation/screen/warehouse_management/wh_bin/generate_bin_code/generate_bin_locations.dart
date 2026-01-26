import 'package:assign_erp/core/util/debug_printify.dart';
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
import 'package:assign_erp/features/inventory_ims/data/data_sources/remote/get_wh_locations.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_bin_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/wh_bin_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/warehouse/widget/search_warehouse.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/warehouse_management/wh_bin/widget/wh_bin_form_fields.dart';
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
  List<Map<String, dynamic>>? _subLocations = [];
  List<String> _fullBinLocationCodes = <String>[];

  bool get _isFormValid => _formKey.currentState!.validate();

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  // String get _employeeStore => _employee!.storeNumber;

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

  void _onGenerate() async {
    if (_isGenerating) return;

    // Case 0: New Bin creation — return full bin location codes
    if (_isServerNull && _onCreateFullBinLocation != null) {
      _onCreateFullBinLocation?.call(_fullBinLocationCodes);
      return;
    }

    final isUpdate = _serverItem != null && _whBinData.isNullOrEmpty;
    setState(() => _isGenerating = true);

    // Case 1: Form validation or empty WHBin
    if (!_canGenerate || !_isFormValid || !isUpdate) {
      _showAlert(
        'Failed: Select warehouse and its corresponding sub-location ranges',
      );
      return;
    }

    // Case 2: Valid form and existing WHBin — update full bin locations
    if (_isFormValid && isUpdate) {
      _onUpdateFullBinLocations();
      return;
    }
  }

  void _onUpdateFullBinLocations() {
    final updated = _whBinData.copyWith(
      updatedBy: _employeeName,
      fullBinLocations: _fullBinLocationCodes.join(','),
    );

    _bloc.add(UpdateInventory<WHBin>(documentId: _whBinData.id, data: updated));
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
        _fullBinLocationCodes = [];
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
    setState(() => _isGenerating = false);
  }

  void _handleBlocState(BuildContext cxt, InventoryState<WHBin> state) {
    final note = _isServerNull ? 'Full Bin Locations created' : 'Changes saved';
    switch (state) {
      case InventoryAdded<WHBin>(message: var msg):
      case InventoryUpdated<WHBin>(message: var msg):
        _showAlert(msg ?? note);
      case InventoryError<WHBin>():
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
    return BlocListener<WHBinBloc, InventoryState<WHBin>>(
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
      'title': 'Generate Bin Locations',
      'subTitle':
          '\nGenerate fully qualified bin location codes for the selected warehouse.'
          '\ne.g., Z01-A01-R01-L01-S01',
      'children': [
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
        if (_subLocations.hasValue) ...[
          _buildBinInfo(),
          const SizedBox(height: 20),
          context.confirmableActionButton(
            onPressed: _onGenerate,
            isDisabled: _isGenerating,
            label: _isGenerating ? 'Generating...' : 'Generate Bin Locations',
          ),
        ],
      ],
    },

    if (_hasFullBinLoc)
      {
        'title': 'Edit Full Bin Locations',
        'subTitle': '\nManage bin locations.',
        'children': [_listSubLocationCodes()],
      },
  ];

  DynamicTextFields _buildBinInfo() {
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
          _fullBinLocationCodes = generateFullBinLocationCodes(
            map,
            _subLocations,
          );
          setState(() => _canGenerate = true);
          prettyPrint(
            'full-Bin-Locations-Codes',
            _fullBinLocationCodes,
          ); // debug output
        } catch (e) {
          // context.showAlertOverlay(e.toString()); // show validation error
        }
      },
    );
  }

  List<String> generateFullBinLocationCodes(
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
          'Invalid range for ${type.toString().toUpperAll}: $from - $to',
        );
      }

      // Generate the codes for this level
      levels.add(generateBinLocationsCode(from, to));
    }

    return combineLevels(levels);
  }

  /// Generates a list of codes between [from] and [to] (inclusive).
  List<String> generateBinLocationsCode(String from, String to) {
    // Example: from = "A01", to = "A03"
    final prefix = from.replaceAll(RegExp(r'\d+$'), '');
    final startNum = int.tryParse(from.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final endNum = int.tryParse(to.replaceAll(RegExp(r'\D'), '')) ?? 0;

    if (startNum > endNum) return [];

    return List.generate(
      endNum - startNum + 1,
      (i) => '$prefix${(startNum + i).toString().padLeft(2, '0')}',
    );
  }

  /// Combines multiple levels of codes into a cartesian product with "-" separator
  List<String> combineLevels(List<List<String>> lists, [String prefix = '']) {
    if (lists.isEmpty) return [prefix.substring(1)]; // remove leading '-'
    List<String> result = [];
    for (final item in lists.first) {
      result.addAll(combineLevels(lists.sublist(1), '$prefix-$item'));
    }
    return result;
  }

  SortableHistoryTable<String> _listSubLocationCodes() {
    final codes = _serverItem?.getFullBinLocations ?? [];

    return SortableHistoryTable<String>(
      items: codes,
      columnLabels: ['#', 'Description', 'Codes'],
      rowBuilder: (entry, index) {
        final i = index + 1;
        final isEditing = _editingIndex == index;
        final controller = _getController(index, entry);
        final desc = _whBinData.description.toSentence;

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
                    _onEditCode(isEditing, codes, index, controller),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onEditCode(
    bool isEditing,
    List<String> codes,
    int index,
    TextEditingController controller,
  ) {
    setState(() {
      if (isEditing) {
        // DONE pressed → save
        codes[index] = controller.text.toUpperAll;

        _whBinData = _whBinData.copyWith(fullBinLocations: codes.join(','));

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

/* Column _buildBody() {
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
