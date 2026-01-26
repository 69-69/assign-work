import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/user_guide/data/models/user_guide_model.dart';
import 'package:assign_erp/features/user_guide/presentation/bloc/index.dart';
import 'package:assign_erp/features/user_guide/presentation/bloc/user_guide_bloc.dart';
import 'package:assign_erp/features/user_guide/presentation/screen/how_to_config_app/widgets/user_guide_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateGuideForm<T> on BuildContext {
  Future<void> openCreateGuide({UserGuide? serverGuide}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverGuide != null
          ? 'Edit ${serverGuide.category} Manual'
          : 'Create User Manual',
      isDetailMode: true,
      secondaryWidget: _deleteButton(serverGuide?.id),
      body: _GuideForm(serverGuide: serverGuide),
    ),
  );

  Widget _deleteButton(String? id) {
    return iconButton(
      Icons.delete,
      iconColor: kDangerColor,
      bgColor: kDangerColor.toAlpha(0.1),
      borderColor: kTransparentColor,
      tooltip: 'Delete manual',
      onPressed: () async {
        final isConfirmed = await confirmUserActionDialog();

        if (id != null && mounted && isConfirmed) {
          // Dispatch the delete event
          read<HowToBloc>().add(DeleteGuide<String>(documentId: id));
          showAlertOverlay(
            'Successfully deleted',
            onCallback: () => Navigator.pop(this),
          );
        }
      },
    );
  }
}

class _GuideForm extends StatefulWidget {
  final UserGuide? serverGuide;

  const _GuideForm({this.serverGuide});

  @override
  State<_GuideForm> createState() => _GuideFormState();
}

class _GuideFormState extends State<_GuideForm> {
  bool _isSubmitting = false;
  Key _formResetKey = UniqueKey();
  final List<UserGuide> _userGuides = [];
  final _formKey = GlobalKey<FormState>();

  bool get _isFormValid => _formKey.currentState?.validate() ?? false;

  HowToBloc get _bloc => context.read<HowToBloc>();

  Employee? get _employee => context.employee;

  UserGuide? get _serverGuide => widget.serverGuide;

  bool get _isServerNull => _serverGuide == null;

  void _onSubmit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Guides/Manuals
    if (_isFormValid && (_serverGuide?.isNotEmpty ?? false)) {
      _updateManual();
      return;
    }

    // Case 2: Form validation or empty _userGuides
    if (!_isFormValid && _userGuides.isNotEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Add new Guides/Manuals
    _addNewDManual();
  }

  void _addNewDManual() {
    // Append history to each guide
    final manuals = _userGuides
        .map((e) => e.copyWith(history: history()))
        .toList();

    _bloc.add(AddGuide<List<UserGuide>>(data: manuals));
  }

  void _updateManual() {
    final updated = _userGuides.first.copyWith(
      id: _serverGuide!.id,
      history: history(AuditAction.updated),
    );

    _bloc.add(UpdateGuide<UserGuide>(documentId: updated.id, data: updated));
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverGuide!.history,
    AuditLog(action: action, actionBy: _employee!.employeeId),
  ];

  void _resetForm() {
    setState(() {
      _userGuides.clear();
      _isSubmitting = false;
      _formKey.currentState?.reset();
      _formResetKey = UniqueKey(); // 💥 full rebuild
    });
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull ? _resetForm() : Navigator.pop(context),
    );
  }

  void _handleBlocState(BuildContext cxt, GuideState<UserGuide> state) {
    final note = _isServerNull ? 'Guides/Manuals created' : 'Changes saved';
    switch (state) {
      case GuideAdded<UserGuide>(message: var msg):
      case GuideUpdated<UserGuide>(message: var msg):
        _showAlert(msg ?? note);
      case GuideError<UserGuide>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HowToBloc, GuideState<UserGuide>>(
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
        FormGroupCard(
          showCollapseButton: _isServerNull,
          title: _serverGuide?.title.toTitle ?? 'User Manual',
          subTitle:
              '\nA guide to help users understand and use the ${_serverGuide?.category ?? 'software'}.',
          children: [_buildForm()],
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          label: _isServerNull ? 'Create Manual' : null,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  DynamicTextFields _buildForm() {
    return DynamicTextFields(
      fullWidthKey: 'title',
      showButton: _isServerNull,
      initialData: [?_serverGuide?.toMap()],
      fieldsConfig: UserGuideConfig.formFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        UserGuideConfig.updateListFromData<UserGuide>(
          _userGuides,
          map: data,
          fromMap: (map, id) => UserGuide.fromMap(map),
        );
      },
    );
  }
}
