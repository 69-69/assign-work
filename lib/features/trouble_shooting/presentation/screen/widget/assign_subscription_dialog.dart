import 'package:assign_erp/core/constants/app_colors.dart';
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
  }) => showModalBottomSheet(
    context: this,
    isDismissible: false,
    isScrollControlled: true,
    backgroundColor: kTransparentColor,
    builder: (_) => AssignSubscriptionWorkspace(
      workspaceId: workspaceId,
      workspaceName: workspaceName,
    ),
  );
}

class AssignSubscriptionWorkspace extends StatelessWidget {
  final String workspaceId;
  final String? workspaceName;

  const AssignSubscriptionWorkspace({
    super.key,
    required this.workspaceId,
    this.workspaceName,
  });

  String get _workspaceName => (workspaceName ?? 'Workspace').toTitleCase;

  @override
  Widget build(BuildContext context) {
    return _buildAlertDialog(context);
  }

  _buildAlertDialog(BuildContext context) {
    return CustomDialog(
      title: DialogTitle(
        title: 'Assign Subscription',
        subtitle: 'Assign subscription to $_workspaceName',
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
              onTotalDevicesChanged: (v) {
                _updateSpecificData(context, {
                  'maxAllowedDevices': int.tryParse(v ?? ''),
                });

                context.showAlertOverlay(
                  "$_workspaceName's Max allowed devices updated successfully",
                );
              },
              onChanged: (id, name, fee, effectiveFrom, expiresOn) {
                _updateSpecificData(context, {
                  'subscriptionId': id,
                  'subscriptionFee': fee,
                  'expiresOn': expiresOn?.millisecondsSinceEpoch,
                  'effectiveFrom': effectiveFrom?.millisecondsSinceEpoch,
                });

                context.showAlertOverlay(
                  'Subscription successfully assigned to $_workspaceName',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateSpecificData(BuildContext context, Map<String, dynamic> map) {
    context.read<AllTenantsBloc>().add(
      UpdateTenant<Workspace>(documentId: workspaceId, mapData: map),
    );
  }
}
