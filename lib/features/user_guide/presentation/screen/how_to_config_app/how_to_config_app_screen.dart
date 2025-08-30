import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/user_guide/data/models/user_guide_model.dart';
import 'package:assign_erp/features/user_guide/presentation/bloc/how_to/how_to_bloc.dart';
import 'package:assign_erp/features/user_guide/presentation/bloc/user_guide_bloc.dart';
import 'package:assign_erp/features/user_guide/presentation/screen/how_to_config_app/add/add_user_guide.dart';
import 'package:assign_erp/features/user_guide/presentation/screen/how_to_config_app/widgets/body.dart';
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
            ..add(LoadGuides<UserGuide>()),
      child: CustomScaffold(
        title: guideToScreenTitle,
        body: _buildBody(context, canAccessDev),
        floatingActionButton: _buildBuildFloatingBtn(context, canAccessDev),
      ),
    );
  }

  Widget? _buildBuildFloatingBtn(BuildContext context, bool canAccessDev) {
    return canAccessDev
        ? context.buildFloatingBtn(
            'New Guide',
            icon: Icons.note_add_outlined,
            onPressed: () async => await context.openAddGuide(),
          )
        : null;
  }

  CustomTab _buildBody(BuildContext context, bool canAccessDev) {
    // Check if the user has access to the Agent dashboard
    final canAccessAgent = WorkspaceRoleGuard.canAccessAgentDashboard(context);

    final openThisTab = int.tryParse(openTab) ?? 0;

    final guideCategories = _getFilterGuideCategories(canAccessAgent);

    final tabs = guideCategories.map((type) {
      final label = type[0].toUpperCaseAll + type.substring(1);
      final icon = _iconForType(type);
      return {'label': label, 'icon': icon};
    }).toList();

    final children = guideCategories
        .map((type) => Body(guideCategory: type, isDeveloper: canAccessDev))
        .toList();

    return CustomTab(
      isVerticalTab: true,
      openThisTab: openThisTab,
      length: guideCategories.length,
      tabs: tabs,
      children: children,
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'agent' => Icons.real_estate_agent,
      'setup' => Icons.settings,
      'pos' => Icons.point_of_sale,
      'crm' => Icons.group,
      'inventory' => Icons.inventory_sharp,
      'warehouse' => Icons.warehouse,
      _ => Icons.help_outline,
    };
  }

  List<String> _getFilterGuideCategories(bool canAccessAgent) {
    return canAccessAgent
        ? userGuideCategories
        : userGuideCategories.where((type) => type != 'agent').toList();
  }
}
