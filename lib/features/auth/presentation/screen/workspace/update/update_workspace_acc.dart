import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_dialog.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/auth/data/role/workspace_role.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/workspace_form_inputs.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/all_tenants/all_tenants_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/tenant_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateWorkspacePopUp on BuildContext {
  Future<void> openUpdateWorkspacePopUp({required Workspace workspace}) =>
      showModalBottomSheet(
        context: this,
        isDismissible: true,
        isScrollControlled: true,
        backgroundColor: kTransparentColor,
        builder: (_) => WorkspaceScreen(workspace: workspace),
      );
}

class WorkspaceScreen extends StatefulWidget {
  final Workspace workspace;

  const WorkspaceScreen({super.key, required this.workspace});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  late Workspace _workspace;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _workspace = widget.workspace;
  }

  void _toastMsg(String title) {
    context.showAlertOverlay(
      label: 'Success Message',
      '${_workspace.name.toTitle} $title updated',
    );
  }

  /// Update Specific Field [_modifySpecificField]
  void _modifySpecificField(Map<String, dynamic> data) {
    context.read<AllTenantsBloc>().add(
      UpdateTenant<Workspace>(documentId: _workspace.id, mapData: data),
    );
  }

  /// Update Workspace Role [_updateWorkspaceRole]
  void _updateWorkspaceRole(String role) {
    final obj = WorkspaceRoleHelper.fromString(role);

    _workspace.copyWith(role: obj);

    _modifySpecificField({'role': role});

    _toastMsg('role');
  }

  /// Dispatches an event to reset workspace authorized device IDs for Tenants workspace.
  ///
  /// If a specific [did] (device ID) is provided, it will be removed from the
  /// list of authorized devices. If [did] is null, the event will trigger
  /// removal of all authorized device IDs. [_revokeAuthorizedDeviceId]
  void _revokeAuthorizedDeviceId({String? did}) {
    context.read<AllTenantsBloc>().add(
      RevokeAuthorizedDeviceId<String>(documentId: _workspace.id, data: did),
    );

    setState(() {
      final updatedDeviceIds = did != null
          ? _workspace.authorizedDeviceIds.where((id) => id != did).toList()
          : <String>[];

      _workspace = _workspace.copyWith(authorizedDeviceIds: updatedDeviceIds);
    });

    _toastMsg(
      did != null
          ? 'Device ID "$did" has been removed.'
          : 'Authorized device IDs have been cleared.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: DialogTitle(
        title: _workspace.name.toTitle,
        subtitle: 'Workspace Role & Status',
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: _buildForm(context),
      ),
      actions: const [],
    );
  }

  _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkspaceRoleDropdown(
          key: const Key('edit-workspace-role'),
          initialValue: _workspace.role.name,
          onRoleChanged: (v) =>
              v.isNullOrEmpty ? null : _updateWorkspaceRole(v!),
        ),

        if (_workspace.authorizedDeviceIds.isNotEmpty) ...[
          const SizedBox(height: 10.0),
          Text(
            'Authorized Devices Ids',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge,
          ),
          SizedBox(height: 60, child: _buildAuthorizedDevicesChips()),
        ],
        /*divLine,
        _formBody(),*/
      ],
    );
  }

  /*ExpansionTile _formBody() {
    return ExpansionTile(
      dense: true,
      expandedAlignment: Alignment.center,
      title: Text(
        'Manage Workspace',
        textAlign: TextAlign.center,
        style: context.textTheme.titleLarge?.copyWith(
          color: kPrimaryLightColor,
        ),
      ),
      subtitle: Text(
        _workspace.name.toTitleCase,
        textAlign: TextAlign.center,
        style: context.textTheme.bodySmall,
      ),
      childrenPadding: const EdgeInsets.only(bottom: 20.0),
      children: <Widget>[
        const SizedBox(height: 20.0),
        context.confirmableActionButton(onPressed: null),
      ],
    );
  }*/

  /// Main widget that includes reset button and chips list
  Widget _buildAuthorizedDevicesChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _buildDeviceChips()),
        context.resetAuthorizedDevicesIdsButton(
          onPressed: () => _revokeAuthorizedDeviceId(),
        ),
      ],
    );
  }

  /// Builds the scrollable list of authorized device chips
  Widget _buildDeviceChips() {
    final deviceIds = _workspace.authorizedDeviceIds;

    return CustomScrollBar(
      showScrollUpButton: false,
      controller: ScrollController(),
      padding: EdgeInsets.only(top: 15),
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: deviceIds.asMap().entries.map((entry) {
          return _buildChipCard(index: entry.key, deviceId: entry.value);
        }).toList(),
      ),
    );
  }

  /// Builds a single chip with delete functionality
  Widget _buildChipCard({required int index, required String deviceId}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Chip(
        padding: EdgeInsets.zero,
        label: Text(
          deviceId,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        deleteButtonTooltipMessage: 'Remove',
        backgroundColor: randomBgColors[index].toAlpha(0.3),
        deleteIcon: const Icon(size: 16, Icons.clear, color: kTextColor),
        onDeleted: () async {
          final isConfirmed = await context.confirmUserActionDialog(
            onAccept: 'Remove IDs',
          );
          if (isConfirmed) _revokeAuthorizedDeviceId(did: deviceId);
        },
      ),
    );
  }
}
