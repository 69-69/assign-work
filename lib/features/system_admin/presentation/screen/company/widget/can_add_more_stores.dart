import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/util/with_bloc.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/features/auth/data/data_sources/local/auth_cache_service.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/refresh_entire_app.dart';
import 'package:assign_erp/features/system_admin/data/models/company_store_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_stores_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:flutter/material.dart';

/*extension CompanyStoresBlocX on CompanyStoresBloc {
  int get totalStores {
    final state = this.state;
    if (state is! SetupsLoaded<CompanyStore>) return 0;
    return state.data.length;
  }
}*/

extension CompanyStoreBranches on BuildContext {
  /// Determines whether the company(Subscriber) can add additional branch stores (locations)
  /// based on the current Workspace subscription limits.
  ///
  /// Each workspace defines a maximum number of allowed stores (or devices).
  /// This method compares the current number of stores against that limit
  /// and returns both the allowance status and related metadata.
  ///
  /// Returns:
  /// - [addMore]: whether new stores can still be added
  /// - [maxAllowed]: maximum number of stores allowed by the workspace plan
  /// - [stores]: current list of existing stores
  ///
  /// [reactive] controls data access behavior:
  /// - true  → subscribes to store updates (UI reactive)
  /// - false → reads current state once (non-reactive)
  ({bool addMore, int maxAllowed, List<CompanyStore> stores}) canAddMoreStores({
    bool reactive = true,
  }) {
    final workspace = this.workspace;

    if (workspace == null) {
      // No active workspace → no store operations allowed
      return (addMore: false, maxAllowed: 0, stores: []);
    }

    final stores = getStores(reactive);

    return (
      addMore: stores.length < workspace.maxAllowedDevices,
      maxAllowed: workspace.maxAllowedDevices,
      stores: stores,
    );
  }

  /// [getStores] Returns the list of branch stores (or shops) created by the current company (subscriber).
  ///
  /// The data is sourced from `CompanyStoresBloc`, which is initialized at app startup
  /// (see `main.dart`) and holds the current store state for the session.
  ///
  /// This method supports both reactive and non-reactive access:
  /// - `listen = true`  → `subscribes` to bloc updates (triggers UI rebuilds)
  /// - `listen = false` → `reads` the current state once without subscribing
  List<CompanyStore> getStores(bool listen) {
    final stores = withBloc<CompanyStoresBloc, List<CompanyStore>>(
      this,
      listen: listen,
      builder: (bloc) {
        final state = bloc.state;
        if (state is! SetupsLoaded<CompanyStore>) return [];
        return state.data;
      },
    );

    return stores;
  }

  Future<bool> get _confirmUserSwitch async => await confirmAction<bool>(
    const Text(
      'Switching stores will hide data from the previous store.\n\nDo you want to switch?',
    ),
    title: 'Confirm Store Switch',
    onAcceptLabel: 'Switch',
    onRejectLabel: 'Cancel',
  );

  Future<void> onSwitchStore(String storeNumber, {String location = ''}) async {
    // Confirm the action
    final isConfirmed = await _confirmUserSwitch;

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
        'You can\'t add more stores (branches). Please extend your subscription license for additional stores.\nFor further assistance, kindly contact customer service.',
      ),
      onAcceptLabel: 'Got it',
      onRejectLabel: 'Cancel',
      title: 'Can\'t Add More',
    );
  }
}
