import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/data/data_sources/local/auth_cache_service.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/refresh_entire_app.dart';
import 'package:assign_erp/features/system_admin/data/models/company_store_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_stores_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CompanyStoreBranches on BuildContext {
  /// Restricts multi-location (branch/store/shop) additions based on the workspace subscription.
  ///
  /// Limits the number of branch stores or shops a company (subscriber) can add, according to the
  /// maximum number of allowed devices defined in the current Workspace subscription license.
  /// [canAddMoreStores]
  ({bool addMore, int maxAllowed}) get canAddMoreStores {
    final workspace = this.workspace;
    if (workspace == null) {
      return (addMore: false, maxAllowed: 0); // no workspace, no action
    }
    // prettyPrint('workspace-maxAllowedDevices', workspace.maxAllowedDevices);
    return (
      addMore: totalStores < workspace.maxAllowedDevices,
      maxAllowed: workspace.maxAllowedDevices,
    );
  }

  /// [totalStores] Returns the total number of branch stores or shops a company (subscriber) has added.
  int get totalStores {
    final state = watch<CompanyStoresBloc>().state;
    if (state is! SetupsLoaded<CompanyStore>) return 0;
    return state.data.length;
  }

  Future<void> onSwitchStore(String storeNumber, {String location = ''}) async {
    // Confirm the action
    final isConfirmed = await confirmUserActionDialog(
      onAcceptLabel: 'Switch Store',
    );

    if (mounted && isConfirmed) {
      final msg =
          'Store Branch changed to ${location.toTitle} (Branch #$storeNumber)';
      // Show progress dialog while updating store number
      await progressBarDialog(
        child: const Text('Please wait while updating the store branch...'),
        request: _updateStoreNumber(
          msg,
          storeNumber: storeNumber,
          location: location,
        ),
        onSuccess: (_) => showAlertOverlay(msg),
        onError: (error) => showAlertOverlay('Failed to update store branch'),
      );
    }
  }

  /// Simulates updating the store number and navigates to the home page.
  ///
  /// This method demonstrates a delay to simulate a network request or some processing time,
  /// and then navigates to the home page.
  ///
  /// Returns:
  /// - A [Future] that completes after the navigation.
  Future<void> _updateStoreNumber(
    String msg, {
    String location = '',
    required String storeNumber,
  }) async {
    try {
      final authCacheService = AuthCacheService();
      bool isSwitched = await authCacheService.switchStores(storeNumber);
      await Future.delayed(kRProgressDelay);

      if (isSwitched) {
        if (mounted) {
          final isDone = await confirmDone(
            Text(msg),
            title: 'Business Location Changed',
            barrierDismissible: false,
          );
          if (isDone) {
            RefreshEntireApp.restartApp(this);
          }
        }
      } else {
        throw Exception("Switching Branch (Store) failed. Employee not found.");
      }
    } catch (e) {
      showAlertOverlay(
        'Error switching branch (store): ${e.toString()}',
        bgColor: kDangerColor,
      );
      rethrow;
    }
  }

  Future<dynamic> showUpgradeDialog() async {
    return await confirmAction(
      Text(
        'You can\'t add more stores (branches). Please extend your subscription license for additional stores.\nFor further assistance, kindly contact support.',
      ),
      onAcceptLabel: 'Done',
      onRejectLabel: 'Cancel',
      title: 'Can\'t Add More',
    );
  }
}
