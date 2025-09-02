import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/user_guide/data/models/user_guide_model.dart';
import 'package:assign_erp/features/user_guide/presentation/bloc/how_to/how_to_bloc.dart';
import 'package:assign_erp/features/user_guide/presentation/bloc/user_guide_bloc.dart';
import 'package:assign_erp/features/user_guide/presentation/screen/how_to_config_app/add/add_user_guide.dart';
import 'package:assign_erp/features/user_guide/presentation/screen/widget/guide_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Body extends StatelessWidget {
  final String guideCategory;
  final bool isDeveloper;

  const Body({
    super.key,
    required this.guideCategory,
    this.isDeveloper = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HowToBloc, GuideState<UserGuide>>(
      builder: (context, state) {
        return switch (state) {
          LoadingGuides<UserGuide>() => context.loader,
          GuidesLoaded<UserGuide>(data: var results) => _buildGuideList(
            context,
            results,
            isDeveloper,
          ),
          GuideError<UserGuide>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildGuideList(
    BuildContext context,
    List<UserGuide> results,
    bool canAccessDev,
  ) {
    if (results.isEmpty) {
      return canAccessDev
          ? context.buildAddButton(
              'Add New Guide',
              onPressed: () => context.openAddGuide(category: guideCategory),
            )
          : _buildEmptyMessage(context);
    }
    final guides = results
        .where((UserGuide result) => result.category == guideCategory)
        .toList();

    return GuideCard(guides: guides, isEdit: canAccessDev);
  }

  Center _buildEmptyMessage(BuildContext context) {
    return Center(
      child: Text(
        '${guideCategory.toUpperAll}: No guides found.',
        textScaler: TextScaler.linear(context.textScaleFactor),
      ),
    );
  }
}
