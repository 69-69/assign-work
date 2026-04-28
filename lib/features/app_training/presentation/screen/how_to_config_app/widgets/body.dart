import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/app_training/data/models/user_guide_model.dart';
import 'package:assign_erp/features/app_training/presentation/bloc/how_to/how_to_bloc.dart';
import 'package:assign_erp/features/app_training/presentation/bloc/app_training_bloc.dart';
import 'package:assign_erp/features/app_training/presentation/screen/how_to_config_app/create/create_app_training.dart';
import 'package:assign_erp/features/app_training/presentation/screen/widget/training_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Body extends StatelessWidget {
  final String guideType;
  final bool isDeveloper;

  const Body({super.key, required this.guideType, this.isDeveloper = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HowToBloc, AppTrainingState<AppTraining>>(
      builder: (context, state) {
        return switch (state) {
          LoadingTrainings<AppTraining>() => context.loader,
          TrainingsLoaded<AppTraining>(data: var results) => _buildGuideList(
            context,
            results,
            isDeveloper,
          ),
          TrainingError<AppTraining>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildGuideList(
    BuildContext context,
    List<AppTraining> results,
    bool canAccessDev,
  ) {
    if (results.isEmpty) {
      return canAccessDev
          ? context.buildAddButton(
              'Create Training',
              onPressed: () => context.openCreateTraining(),
            )
          : _buildEmptyMessage(context);
    }
    final guides = results
        .where((AppTraining result) => result.category == guideType)
        .toList();

    return GuideCard(guides: guides, isEdit: canAccessDev);
  }

  Center _buildEmptyMessage(BuildContext context) {
    return Center(
      child: Text(
        '${guideType.toUpperAll}: No guides found.',
        textScaler: TextScaler.linear(context.textScaleFactor),
      ),
    );
  }
}
