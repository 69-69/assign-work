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
      tooltip: 'Delete manual',
      onPressed: () async {
        final isConfirmed = await confirmUserActionDialog();

        if (id != null && mounted && isConfirmed) {
          // Dispatch the delete event
          read<HowToBloc>().add(DeleteGuide<UserGuide>(documentId: id));
          showAlertOverlay(
            'Successfully deleted',
            popContext: () => Navigator.pop(this),
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
  Key _formResetKey = UniqueKey();
  final List<UserGuide> _userGuides = [];
  final _formKey = GlobalKey<FormState>();

  bool get _isFormValid => _formKey.currentState?.validate() ?? false;

  HowToBloc get _bloc => context.read<HowToBloc>();

  Employee? get _employee => context.employee;

  UserGuide? get _serverGuide => widget.serverGuide;

  bool get _nullServer => _serverGuide == null;

  void _onSubmit() {
    // Case 1: Update existing Guides/Manuals
    if (_serverGuide != null) {
      _updateManual();
      return;
    }

    // Case 2: Form validation or empty _userGuides
    if (!_isFormValid && _userGuides.isNotEmpty) {
      _showErrorAlert('Please enter all required fields', kDangerColor);
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
    _showSuccessAlert('Manual(s) successfully created');
  }

  void _updateManual() {
    final updated = _userGuides.first.copyWith(
      id: _serverGuide!.id,
      history: history(AuditAction.updated),
    );

    _bloc.add(UpdateGuide<UserGuide>(documentId: updated.id, data: updated));
    _showSuccessAlert('Changes successfully saved');
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    AuditLog(action: action, actionBy: _employee!.employeeId),
  ];

  void _showSuccessAlert(String message) {
    context.showAlertOverlay(
      message,
      popContext: () =>
          _serverGuide != null ? Navigator.pop(context) : _resetForm(),
    );
  }

  void _showErrorAlert(String message, Color bgColor) {
    context.showAlertOverlay(message, bgColor: bgColor);
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _formResetKey = UniqueKey(); // 💥 full rebuild
      _userGuides.clear();
    });
  }

  /*// load existing Guides/Manuals
  void _loadExistingManuals() {
    if (_serverGuide != null) {
      _userGuides
        ..clear()
        ..add(_serverGuide!);
    }
  }*/

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
        FormGroupCard(
          showCollapseButton: _nullServer,
          title: _serverGuide?.title.toTitle ?? 'User Manual',
          subTitle:
              '\nA guide to help users understand and use the ${_serverGuide?.category ?? 'software'}.',
          children: [_buildForm()],
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          label: _nullServer ? 'Create Manual' : null,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  DynamicTextFields _buildForm() {
    return DynamicTextFields(
      fullWidthKey: 'title',
      showButton: _nullServer,
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
