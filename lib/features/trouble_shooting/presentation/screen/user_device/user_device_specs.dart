import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/device_info_service.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/data_backup_manager.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/file_doc_manager.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/layout/column_row_builder.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/refresh_entire_app.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/widget/restore_backup_preference_popup.dart';
import 'package:flutter/material.dart';

class UserDeviceSpec extends StatefulWidget {
  const UserDeviceSpec({super.key});

  @override
  State<UserDeviceSpec> createState() => _UserDeviceSpecState();
}

class _UserDeviceSpecState extends State<UserDeviceSpec> {
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic> _deviceInfo = {};

  @override
  void initState() {
    super.initState();
    _fetchDeviceInfo();
  }

  // Function to copy text to clipboard
  void _copyToClipboard(String textToCopy) async {
    await context.toClipboard(textToCopy);
    if (mounted) {
      context.showAlertOverlay('Copied to clipboard');
    }
  }

  // Fetch device info from the service
  Future<void> _fetchDeviceInfo() async {
    final deviceInfo = await DeviceInfoService.getDeviceInfo();
    setState(() => _deviceInfo = deviceInfo);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      noAppBar: true,
      body: CustomScrollBar(
        padding: const EdgeInsets.only(top: 28.0),
        controller: _scrollController,
        child: _buildBody(context),
      ),
      bottomNavigationBar: const SizedBox(),
      actions: [],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        Text(
          'Your Device Specs',
          semanticsLabel: 'user device specs',
          style: context.textTheme.titleLarge?.copyWith(
            color: kTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        HorizontalDivider(thickness: 8.0),
        _buildDeviceSpecs(context),
        Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: Text(
            'Data Manipulation',
            style: context.textTheme.titleLarge?.copyWith(
              color: kTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        HorizontalDivider(thickness: 8.0),
        _buildCopyAppDataDirectoryPath(context),
        _buildCopyLocalBackupPath(context),
        _buildDeleteDeviceInfo(context),
        _buildDeleteAppData(context),
        _buildRestoreAppDataLocally(context),
      ],
    );
  }

  _buildDeviceSpecs(BuildContext context) {
    return Container(
      color: kGrayColor.toAlpha(0.1 * 255),
      alignment: Alignment.bottomLeft,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: context.columnBuilder(
        isScrollable: false,
        itemCount: _deviceInfo.entries.length,
        crossAxisAlignment: CrossAxisAlignment.start,
        itemBuilder: (context, index) {
          final entry = _deviceInfo.entries.elementAt(index);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              '* ${(entry.key.separateWord).toTitle}: ${entry.value}',
              textAlign: TextAlign.start,
              style: context.textTheme.bodyLarge,
            ),
          );
        },
      ),
    );
  }

  // Widget to copy App-Data-Director path to clipboard
  Widget _buildCopyAppDataDirectoryPath(BuildContext context) {
    return context.optCardBuilder(
      buttonLabel: 'Copy Path',
      label: 'App Data Directory',
      borderColor: kGrayBlueColor,
      icon: Icons.file_copy_sharp,
      desc: 'Path to the app\'s cache directory on this device.',
      onPressed: () async {
        final dir = await FileDocManager.getLocalBackupDir();
        _copyToClipboard(dir.dirPath);
      },
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );
  }

  // Widget to copy Local-Backup-path to clipboard
  Widget _buildCopyLocalBackupPath(BuildContext context) {
    return context.optCardBuilder(
      buttonLabel: 'Copy Path',
      label: 'Local Backup Directory',
      borderColor: kPrimaryLightColor,
      icon: Icons.file_copy_sharp,
      desc: 'Path to the temporary backup directory on this device.',
      onPressed: () async {
        final dir = await FileDocManager.getTemporaryDir();
        _copyToClipboard(dir.path);
      },
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );
  }

  // Widget to reset user device info
  Widget _buildDeleteDeviceInfo(BuildContext context) {
    return context.optCardBuilder(
      icon: Icons.lock_reset,
      buttonLabel: 'Delete Info',
      borderColor: kWarningColor,
      label: 'Reset Device Info',
      desc: 'Clears all locally cached user\'s device information.',
      onPressed: () async {
        final isConfirmed = await context.confirmAction<bool>(
          const Text('Do you want to proceed with resetting the device info?'),
          onAcceptLabel: "Reset ID",
          onRejectLabel: "Cancel",
        );

        if (isConfirmed) {
          DeviceInfoService.resetCache();
          if (context.mounted) {
            RefreshEntireApp.restartApp(context);
          }
        }
      },
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );
  }

  Widget _buildDeleteAppData(BuildContext context) {
    return context.optCardBuilder(
      icon: Icons.reset_tv,
      buttonLabel: 'Factory Reset',
      borderColor: kDangerColor,
      label: 'Factory Reset App',
      desc: 'Deletes all locally cached app data from this device.',
      onPressed: () async {
        final isConfirmed = await context.confirmAction<bool>(
          const Text('Do you want to proceed with resetting the app and data?'),
          onAcceptLabel: "Factory Reset",
          onRejectLabel: "Cancel",
        );

        if (isConfirmed) {
          await DataBackupManager.deleteCache();
          if (context.mounted) {
            RefreshEntireApp.restartApp(context);
          }
        }
      },
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );
  }

  // Widget to locally restore app data from previous backups
  Widget _buildRestoreAppDataLocally(BuildContext context) {
    return context.optCardBuilder(
      label: 'Restore Data',
      borderColor: kSuccessColor,
      buttonLabel: 'Restore Backup',
      icon: Icons.settings_backup_restore,
      desc: 'Restore data from previously backed-up data (Local | Drive).',
      onPressed: () async {
        final isConfirmed = await context.confirmAction<bool>(
          const Text(
            'Do you want to proceed with unzipping and restoring the data?',
          ),
          onAcceptLabel: "Continue",
          onRejectLabel: "Cancel",
        );

        if (context.mounted && isConfirmed) {
          context.openRestoreBackupPreferencePopUp();
          // _confirmRestoreDialog('Internal');
        }
        // FileDocManager.unzipFile(zipFileName: 'in_app_data.zip');
      },
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );
  }
}
