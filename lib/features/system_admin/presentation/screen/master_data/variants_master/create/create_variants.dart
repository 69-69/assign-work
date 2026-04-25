import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/variant_attr_ext.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/block_quote.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/layout/history_view.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/variant_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/attribute_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateVariants<T> on BuildContext {
  Future<void> openAddVariant({
    Attribute? serverVariant,
    Map<String, List<Attribute>>? groupedAttrs,
  }) => openBottomSheet(
    isExpand: true,
    showZoomIcon: false,
    child: BottomSheetScaffold(
      isDetailMode: true,
      title: serverVariant != null
          ? 'Edit ${serverVariant.type}'
          : 'Create Variant(s)',
      body: _AddAttributeForm(
        serverAttribute: serverVariant,
        groupedAttrs: groupedAttrs,
      ),
    ),
  );
}

class _AddAttributeForm extends StatefulWidget {
  final Attribute? serverAttribute;
  final Map<String, List<Attribute>>? groupedAttrs;

  const _AddAttributeForm({this.serverAttribute, this.groupedAttrs});

  @override
  State<_AddAttributeForm> createState() => _AddAttributeFormState();
}

class _AddAttributeFormState extends State<_AddAttributeForm> {
  bool _isSubmitting = false;
  final List<Attribute> _attributes = [];

  Attribute? get _serverAttribute => widget.serverAttribute;
  Map<String, Map<Attribute, bool>> _selectedAttributes = {};
  List<Map<String, Attribute>> _variants = [];

  bool get _isServerNull => _serverAttribute == null;

  Map<String, List<Attribute>>? get _groupedAttrs => widget.groupedAttrs;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  String get _employeeStore => _employee!.storeNumber;

  AttributeBloc get _bloc => context.read<AttributeBloc>();

  void _onSubmit() {
    if (!_isSubmitting) {
      final variantsToSave = Variant.buildVariants(
        itemCode: "TS-001",
        variants: _variants.map((v) => v.toCodeMap()).toList(),
      );
      prettyPrint('variants-To-Save', variantsToSave);

      // _bloc.add(AddSetup<List<Variant>>(data: variantsToSave));
      return;
    }

    setState(() => _isSubmitting = true);

    // Case 3: Create new Attributes
    _newAttributes();
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverAttribute!.history,
    AuditLog(action: action, actionBy: _employeeName),
  ];

  void _newAttributes() {
    final newAttributes = _attributes
        .map(
          (e) => e.copyWith(
            storeNumber: _employeeStore,
            createdBy: _employeeName,
            history: history(),
          ),
        )
        .toList();
    _bloc.add(AddSetup<List<Attribute>>(data: newAttributes));
  }

  // load existing Attributes
  void _loadExistingAttributes() {
    if (_serverAttribute != null) {
      _attributes
        ..clear()
        ..add(_serverAttribute!);
    }
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _attributes.clear();
      });
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull ? _resetForm() : Navigator.pop(context),
    );
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<Attribute> state) {
    final note = _isServerNull ? 'Variants created' : 'Changes saved';
    switch (state) {
      case SetupAdded<Attribute>(message: var msg):
      case SetupUpdated<Attribute>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<Attribute>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  // Initialize selection from grouped data
  void _initSelection(Map<String, List<Attribute>> grouped) {
    _selectedAttributes = {};

    grouped.forEach((key, values) {
      _selectedAttributes[key] = {for (final v in values) v: values.first == v};
    });

    _generateFromSelection();
    /*grouped.forEach((key, values) {
      _selectedAttributes[key] = {for (final v in values) v: false};
    });

    setState(() {});*/
  }

  @override
  void initState() {
    super.initState();
    _loadExistingAttributes();

    if (!_groupedAttrs.isNullOrEmpty) {
      // prettyPrint('widget-groupedAttrs', widget.groupedAttrs);
      _initSelection(_groupedAttrs!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttributeBloc, SetupState<Attribute>>(
      listener: _handleBlocState,
      child: _buildBody(context),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      children: [
        AdaptiveLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VariantPreview(variants: _variants),
            _AttributeSelector(
              selectedAttrs: _selectedAttributes,
              onChanged: ({checked, required key, required name}) {
                _selectedAttributes[name]![key] = checked ?? false;
                _generateFromSelection();
              },
            ),
          ],
        ),

        context.confirmableActionButton(
          isDisabled: _isSubmitting || _variants.first.isEmpty,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Variant')
              : (_isSubmitting ? 'Updating...' : null),
          onPressed: _onSubmit,
        ),
      ],
    );
  }

  // Cry Freedom Movie
  // Generate variants ONLY from selected values
  List<Map<String, Attribute>> _generateFromSelection() {
    final Map<String, List<Attribute>> filtered = {};

    _selectedAttributes.forEach((attr, values) {
      final selectedValues = values.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toList();

      if (selectedValues.isNotEmpty) {
        filtered[attr] = selectedValues;
      }
    });

    final variants = _generateCartesian(filtered);

    setState(() => _variants = variants);

    return variants;
  }

  // Cartesian generator
  List<Map<String, Attribute>> _generateCartesian(
    Map<String, List<Attribute>> attributes,
  ) {
    List<Map<String, Attribute>> result = [{}];

    attributes.forEach((key, values) {
      final temp = <Map<String, Attribute>>[];

      for (final existing in result) {
        for (final value in values) {
          final map = Map<String, Attribute>.from(existing);
          map[key] = value;
          temp.add(map);
        }
      }

      result = temp;
    });

    return result;
  }
}


typedef AttributeChanged =
    void Function({
      required bool? checked,
      required Attribute key,
      required String name,
    });

class _AttributeSelector extends StatelessWidget {
  final AttributeChanged? onChanged;
  final Map<String, Map<Attribute, bool>> selectedAttrs;

  const _AttributeSelector({
    required this.onChanged,
    required this.selectedAttrs,
  });

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    return FormGroupCard(
        title: 'Attribute Set',
        showCollapseButton: false,
        contentPadding: EdgeInsets.all(10),
        helperText:
        '\nSelect attribute values (e.g., Red, Blue, Large) to generate product variants.',
        children: _buildChildren(context),
    );
  }

  List<FormGroupCard> _buildChildren(BuildContext context) {
    return selectedAttrs.entries.map((entry) {
      final attributeName = entry.key;
      final values = entry.value.entries.toList();
      final maxCross = context.screenWidth / (context.isMobile ? 1 : 8);

      return FormGroupCard(
        isExpanded: false,
        title: attributeName.toTitle,
        contentMargin: EdgeInsets.zero,
        cardElevation: 0.5,
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: values.length,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxCross,
              mainAxisExtent: 50,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, i) =>
                _itemBuilder(values[i], attributeName),
          ),
        ],
      );
    }).toList();
  }

  Widget _itemBuilder(MapEntry<Attribute, bool> val, String attributeName) {
    return Tooltip(
      message: val.key.value.toTitle,
      child: CustomCheckboxTile(
        title: Text(val.key.value.toTitle, overflow: TextOverflow.ellipsis),
        value: val.value,
        onChanged: (bool? checked) => onChanged?.call(
          key: val.key,
          checked: checked,
          name: attributeName,
        ),
      ),
    );
  }

  /*Widget _buildBody2(BuildContext context) {
    return Column(
      children: selectedAttrs.entries.map((entry) {
        final attributeName = entry.key;
        final values = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${attributeName.toTitle}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            ...values.entries.map((v) {
              return CustomCheckboxTile(
                title: Text(v.key.value.toTitle,
                  overflow: TextOverflow.ellipsis,),
                value: v.value,
                onChanged: (bool? checked) {
                  onChanged?.call(
                    checked: checked,
                    key: v.key,
                    name: attributeName,
                  );
                },
              );
            }),
          ],
        );
      }).toList(),
    );
  }*/
}

class _VariantPreview extends StatelessWidget {
  final List<Map<String, Attribute>> variants;

  const _VariantPreview({required this.variants});

  @override
  Widget build(BuildContext context) {
    return FormGroupCard(
      title: 'Variant Preview',
      subTitle:
          '\nAutomatically generated combinations based on your selections.',
      showCollapseButton: false,
      contentPadding: EdgeInsets.all(20),
      children: [_buildBody()],
    );
  }

  StatelessWidget _buildBody() {
    if (variants.isEmpty) {
      return BlockQuote(
        child: Text('Select attributes to preview generated variants here.'),
      );
    }

    final keyList = variants.first.keys.toList()
      ..sortByComparable((e) => attributePriorities[e] ?? 999);

    final columnLabels = [...keyList.map((k) => k.toTitle), 'SKU'];

    return StaticHistoryTable<Map<String, Attribute>>(
      columnLabels: columnLabels,
      items: variants,
      rowBuilder: (entry, index) {
        const itemCode = 'TS-001';

        final sku = Variant.buildVariantSKU(itemCode, entry.toCodeMap());

        final cells = <DataCell>[
          ...keyList.map((k) => DataCell(Text(entry[k]?.value.toTitle ?? ""))),
          DataCell(Text(sku.toUpperAll)),
        ];

        return DataRow(cells: cells);
      },
    );
  }

  /*return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DataTable(
          columns: [
            ...keyList.map((k) => DataColumn(label: Text(k.toTitle))),
            const DataColumn(label: Text("SKU")),
          ],
          rows: _variants.map((variant) {
            final itemSKU = 'TS-001';
            final sku = Variant.buildSku(itemSKU, variant);


            return DataRow(
              cells: [
                ...keyList.map(
                  (k) => DataCell(Text(variant[k]?.toUpperAll ?? "")),
                ),
                DataCell(Text(sku.toUpperAll)),
              ],
            );
          }).toList(),
        ),
      ],
    );*/
}
