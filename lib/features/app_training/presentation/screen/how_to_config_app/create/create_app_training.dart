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
import 'package:assign_erp/features/app_training/data/models/user_guide_model.dart';
import 'package:assign_erp/features/app_training/presentation/bloc/index.dart';
import 'package:assign_erp/features/app_training/presentation/bloc/app_training_bloc.dart';
import 'package:assign_erp/features/app_training/presentation/screen/how_to_config_app/widgets/training_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateTrainingForm<T> on BuildContext {
  Future<void> openCreateTraining({AppTraining? serverGuide}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverGuide != null
          ? 'Edit ${serverGuide.category} Training'
          : 'New Training',
      isDetailMode: true,
      secondaryWidget: _deleteButton(serverGuide?.id),
      body: _AppTrainingForm(serverGuide: serverGuide),
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
          read<HowToBloc>().add(DeleteTraining<String>(documentId: id));
          showAlertOverlay(
            'Successfully deleted',
            onCallback: () => Navigator.pop(this),
          );
        }
      },
    );
  }
}

class _AppTrainingForm extends StatefulWidget {
  final AppTraining? serverGuide;

  const _AppTrainingForm({this.serverGuide});

  @override
  State<_AppTrainingForm> createState() => _AppTrainingFormState();
}

class _AppTrainingFormState extends State<_AppTrainingForm> {
  bool _isSubmitting = false;
  Key _formResetKey = UniqueKey();
  final List<AppTraining> _appTrainings = [];
  final _formKey = GlobalKey<FormState>();

  bool get _isFormValid => _formKey.currentState?.validate() ?? false;

  HowToBloc get _bloc => context.read<HowToBloc>();

  Employee? get _employee => context.employee;

  AppTraining? get _serverGuide => widget.serverGuide;

  bool get _isServerNull => _serverGuide == null;

  void _onSubmit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Guides/Manuals
    if (_isFormValid && (_serverGuide?.isNotEmpty ?? false)) {
      _updateManual();
      return;
    }

    // Case 2: Form validation or empty _appTraining
    if (!_isFormValid && _appTrainings.isNotEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Add new Guides/Manuals
    _addNewDManual();
  }

  void _addNewDManual() {
    // Append history to each guide
    final manuals = _appTrainings
        .map((e) => e.copyWith(history: history()))
        .toList();

    _bloc.add(AddTraining<List<AppTraining>>(data: manuals));
  }

  void _updateManual() {
    final updated = _appTrainings.first.copyWith(
      id: _serverGuide!.id,
      history: history(AuditAction.updated),
    );

    _bloc.add(UpdateTraining<AppTraining>(documentId: updated.id, data: updated));
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverGuide!.history,
    AuditLog(action: action, actionBy: _employee!.employeeId),
  ];

  void _resetForm() {
    setState(() {
      _appTrainings.clear();
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

  void _handleBlocState(BuildContext cxt, AppTrainingState<AppTraining> state) {
    final note = _isServerNull ? 'Guides/Manuals created' : 'Changes saved';
    switch (state) {
      case TrainingAdded<AppTraining>(message: var msg):
      case TrainingUpdated<AppTraining>(message: var msg):
        _showAlert(msg ?? note);
      case TrainingError<AppTraining>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HowToBloc, AppTrainingState<AppTraining>>(
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
          title: _serverGuide?.title.toTitle ?? 'App training',
          subTitle:
              '\nA guide to help users understand and use the ${_serverGuide?.category ?? 'software'}.',
          children: [_buildForm()],
        ),
        const SizedBox(height: 10.0),
        context.confirmableActionButton(
          label: _isServerNull ? 'Create Training' : null,
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
      fieldsConfig: AppTrainingConfig.formFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        AppTrainingConfig.updateListFromData<AppTraining>(
          _appTrainings,
          map: data,
          fromMap: (map, id) => AppTraining.fromMap(map),
        );
      },
    );
  }
}
