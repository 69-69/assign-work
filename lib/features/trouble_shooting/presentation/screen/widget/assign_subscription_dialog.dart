import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_dialog.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/all_tenants/all_tenants_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/bloc/tenant_bloc.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AssignSubscriptionDialog on BuildContext {
  Future<void> assignSubscriptionToWorkspaceDialog({
    required String workspaceId,
    String? workspaceName,
    int? initialMaxDevices,
  }) async => await AssignSubscriptionWorkspace(
    workspaceId: workspaceId,
    workspaceName: workspaceName,
    initialMaxDevices: initialMaxDevices,
  ).openCustomDialog(this, isScrollControlled: true, constraints: null);
}

class AssignSubscriptionWorkspace extends StatelessWidget {
  final String workspaceId;
  final String? workspaceName;
  final int? initialMaxDevices;

  const AssignSubscriptionWorkspace({
    super.key,
    required this.workspaceId,
    this.workspaceName,
    this.initialMaxDevices,
  });

  String get _workspaceName => (workspaceName ?? 'Workspace').toTitle;

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: DialogTitle(
        title: 'Assign Subscription',
        subtitle: 'Assign subscription to: $_workspaceName',
      ),
      body: _buildBody(context),
      actions: [],
    );
  }

  Container _buildBody(BuildContext context) {
    return Container(
      width: context.screenWidth,
      padding: EdgeInsets.only(bottom: context.bottomInsetPadding),
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SubscriptionAndTotalDevicesDropdown(
              initialTotalDevices: initialMaxDevices?.toString(),
              onTotalDevicesChanged: (v) {
                _updateSpecificData(context, {
                  'maxAllowedDevices': int.tryParse(v ?? ''),
                }, title: 'Max-Allowed-Devices');
              },
              onChanged: (id, name, fee, effectiveFrom, expiresOn) {
                _updateSpecificData(context, {
                  'subscriptionId': id,
                  'subscriptionFee': fee,
                  'expiresOn': expiresOn?.millisecondsSinceEpoch,
                  'effectiveFrom': effectiveFrom?.millisecondsSinceEpoch,
                }, title: 'Subscription');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateSpecificData(
    BuildContext context,
    Map<String, dynamic> map, {
    String? title,
  }) {
    context.read<AllTenantsBloc>().add(
      UpdateTenant<Workspace>(documentId: workspaceId, mapData: map),
    );

    context.showAlertOverlay(
      '$_workspaceName $title successfully updated',
      onCallback: () => Navigator.of(context),
    );
  }
}
