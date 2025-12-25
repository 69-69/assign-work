import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/system_admin/data/models/company_stores_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_stores_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/can_add_more_stores.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/company_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add Company Stores or Branches
extension AddStoreLocations<T> on BuildContext {
  Future<void> openAddStoreLocations({
    CompanyStores? serverStore,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title:
          '${serverStore == null ? 'Add Stores (Branches)' : 'Edit ${serverStore.name.toTitle}'} ',
      body: _AddStoreFormBody(serverStore: serverStore),
    ),
  );
}

class _AddStoreFormBody extends StatefulWidget {
  final CompanyStores? serverStore;

  const _AddStoreFormBody({this.serverStore});

  @override
  State<_AddStoreFormBody> createState() => _AddStoreFormBodyState();
}

class _AddStoreFormBodyState extends State<_AddStoreFormBody> {
  final _formKey = GlobalKey<FormState>();
  final List<CompanyStores> _storeList = [];
  CompanyStores? get _serverStore => widget.serverStore;
  bool get _isValid => _formKey.currentState?.validate() ?? false;

  void _onSubmit() {
    if (_isValid && _storeList.isNotEmpty) {
      final bloc = context.read<CompanyStoresBloc>();

      if (_serverStore != null) {
        final updated = _storeList.first.copyWith(
          id: _serverStore!.id,
          storeNumber: _serverStore!.storeNumber,
        );
        bloc.add(
          UpdateSetup<CompanyStores>(documentId: updated.id, data: updated),
        );
      } else {
        final newStores = _prepareNewStores();
        bloc.add(AddSetup<List<CompanyStores>>(data: newStores));
      }

      _formKey.currentState!.reset();

      context.showAlertOverlay('Store (Branch) Location created');
      Navigator.pop(context);
    }
  }

  List<CompanyStores> _prepareNewStores() {
    // append store number to each stores/branches
    final newStores = _storeList
        .map(
          (e) => e.copyWith(
            storeNumber: '${e.name}${e.location}'.generateUniqueCode(),
          ),
        )
        .toList();
    return newStores;
  }

  // load existing stores/branches
  void _loadExisting() {
    if (_serverStore != null) {
      prettyPrint('_serverStores', _serverStore?.toMap());
      _storeList.clear();
      _storeList.add(_serverStore!);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final canAddStore = context.canAddMoreStores;
    final title = _serverStore?.name ?? 'Stores (Branches)';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FormGroupCard(
          children: [
            DynamicTextFields(
              title: title,
              fieldsConfig: CompanyFormInputs.addStoresFields,
              initialData: [?_serverStore?.toMap()],
              showButton: canAddStore.addMore || _serverStore != null,
              fieldGroupsLimit: canAddStore.maxAllowed,
              onLimitReached: () async => await context.showUpgradeDialog(),
              onChanged: (List<Map<String, dynamic>> data) {
                if (_isValid) setState(() {});

                // Create a new line item
                _storeList
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map((e) => CompanyStores.fromMap(e)));
              },
            ),
          ],
        ),
        context.confirmableActionButton(
          label: _serverStore == null ? 'Add Store (Branch)' : null,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}
