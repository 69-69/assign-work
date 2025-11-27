import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_status_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Request not found...we\'re working on new updates.\nOr You\'re not authorized!',
              textAlign: TextAlign.center,
              softWrap: true,
              style: context.textTheme.bodyLarge?.copyWith(
                color: kDangerColor,
                overflow: TextOverflow.visible,
              ),
              textScaler: TextScaler.linear(context.textScaleFactor),
            ),
            const SizedBox(height: 20),
            context.outlinedButton(
              'Go Back',
              tooltip: 'Back to initial screen',
              onPressed: () {
                final authBloc = context.read<AuthBloc>();
                if (authBloc.state.authStatus == AuthStatus.authenticated) {
                  context.goNamed(RouteNames.homeDashboard);
                } else {
                  context.go(RouteNames.initialScreen);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
