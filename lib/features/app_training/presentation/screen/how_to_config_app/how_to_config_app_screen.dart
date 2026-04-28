import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/app_training/data/models/user_guide_model.dart';
import 'package:assign_erp/features/app_training/presentation/bloc/how_to/how_to_bloc.dart';
import 'package:assign_erp/features/app_training/presentation/bloc/app_training_bloc.dart';
import 'package:assign_erp/features/app_training/presentation/screen/how_to_config_app/create/create_app_training.dart';
import 'package:assign_erp/features/app_training/presentation/screen/how_to_config_app/widgets/body.dart';
import 'package:assign_erp/features/app_training/presentation/screen/how_to_config_app/widgets/training_form_inputs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HowToConfigAppScreen extends StatelessWidget {
  final String openTab;

  const HowToConfigAppScreen({super.key, this.openTab = '0'});

  @override
  Widget build(BuildContext context) {
    // Check if the user has access to the Developer dashboard
    final canAccessDev = WorkspaceRoleGuard.canAccessDeveloperDashboard(
      context,
    );

    return BlocProvider<HowToBloc>(
      create: (context) =>
          HowToBloc(firestore: FirebaseFirestore.instance)
            ..add(LoadTrainings<AppTraining>()),
      child: CustomScaffold(
        title: trainingToScreenTitle,
        body: _buildBody(context, canAccessDev),
        floatingActionButton: _buildFloatingBtn(context, canAccessDev),
      ),
    );
  }

  Widget? _buildFloatingBtn(BuildContext context, bool canAccessDev) {
    return canAccessDev
        ? FittedBox(
            child: context.toolbarButton(
              label: 'New Manual',
              icon: Icons.note_add_outlined,
              bgColor: kDangerColor,
              onPressed: () async => await context.openCreateTraining(),
            ),
          )
        : null;
  }

  CustomTab _buildBody(BuildContext context, bool canAccessDev) {
    // Check if the user has access to the Agent dashboard
    final canAccessAgent = WorkspaceRoleGuard.canAccessAgentDashboard(context);
    final guideTypes = AppTrainingConfig.tabContents(canAccessAgent);

    final children = guideTypes
        .map((type) => Body(guideType: type, isDeveloper: canAccessDev))
        .toList();
    // prettyPrint('total ${children.length}=', guideTypes.length);

    return CustomTab(
      isVertical: true,
      openThisTab: int.tryParse(openTab) ?? 0,
      length: guideTypes.length,
      tabs: AppTrainingConfig.sideTabs(canAccessAgent),
      children: children,
    );
  }
}
