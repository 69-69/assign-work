import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///  [MasterResetButton] Is used to Reset/Logout from all Sessions in case of SignIn Issues.
/// Long Press to Reset/Logout from all Sessions
class MasterResetButton extends StatelessWidget {
  const MasterResetButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Master Reset',
      onLongPress: () {
        context.read<AuthBloc>().add(AuthSignOutRequested());
        context.showAlertOverlay(
          'Master Reset Successful',
          label: 'Done',
          duration: 10,
        );
      },
      icon: Icon(Icons.reset_tv, color: kGrayBlueColor.toAlpha(0.5), size: 20),
      onPressed: () {},
    );
  }
}
