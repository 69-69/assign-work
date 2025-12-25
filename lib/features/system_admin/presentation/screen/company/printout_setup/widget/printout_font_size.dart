import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/local/setup_printout_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:flutter/material.dart';

class PrintoutFontSizeScreen extends StatefulWidget {
  const PrintoutFontSizeScreen({super.key});

  @override
  State<PrintoutFontSizeScreen> createState() => _PrintoutFontSizeScreenState();
}

class _PrintoutFontSizeScreenState extends State<PrintoutFontSizeScreen> {
  final PrintSetupCacheService _printoutService = PrintSetupCacheService();

  SetupPrintOut settings = SetupPrintOut.empty;

  @override
  void initState() {
    super.initState();
    _loadFontSizes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFontSizes();
  }

  Future<void> _loadFontSizes() async {
    final s = await _printoutService.getSettings();
    if (s != null) {
      setState(() => settings = s);
    }
  }

  Future<void> _saveFontSize(String label, double? size) async {
    final remote = await _printoutService.getSettings();
    if (remote == null) return;

    final updater = switch (label) {
      'header' => remote.copyWith(headerFontSize: size),
      'sub' => remote.copyWith(subHeaderFontSize: size),
      'table' => remote.copyWith(tableFontSize: size),
      'body' => remote.copyWith(bodyFontSize: size),
      _ => null,
    };

    // Apply only the matching update
    if (updater == null) return;
    await _printoutService.setSettings(updater);

    if (mounted) {
      context.showAlertOverlay('${label.toUpperFirst} Font Size $size saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: settings.isEmpty
          ? context.loader
          : Column(
              children: [
                _buildTitle(context),
                FormGroupCard(children: [_buildBody()]),
              ],
            ),
    );
  }

  AdaptiveLayout _buildBody() {
    return AdaptiveLayout(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FontSizeDropdown(
          label: 'Header',
          initialValue: settings.headerFontSize,
          onChanged: (v) => _saveFontSize('header', v),
        ),
        FontSizeDropdown(
          label: 'Sub-Header',
          initialValue: settings.subHeaderFontSize,
          onChanged: (v) => _saveFontSize('sub', v),
        ),
        FontSizeDropdown(
          label: 'Table',
          initialValue: settings.tableFontSize,
          onChanged: (v) => _saveFontSize('table', v),
        ),
        FontSizeDropdown(
          label: 'Body',
          initialValue: settings.bodyFontSize,
          onChanged: (v) => _saveFontSize('body', v),
        ),
      ],
    );
  }

  ListTile _buildTitle(BuildContext context) {
    return ListTile(
      dense: true,
      titleAlignment: ListTileTitleAlignment.center,
      title: Wrap(
        spacing: 5,
        direction: Axis.horizontal,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Print Font Sizes',
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildRefreshFontSizes(),
        ],
      ),
      subtitle: Text(
        'This font size will be used for all printout',
        textAlign: TextAlign.center,
        style: context.textTheme.titleSmall,
      ),
    );
  }

  RefreshButton _buildRefreshFontSizes() {
    return RefreshButton(
      tooltip: 'Reset & Refresh Font Sizes',
      callback: () async {
        final settings = (await _printoutService.getSettings())?.copyWith(
          headerFontSize: null,
          subHeaderFontSize: null,
          tableFontSize: null,
          bodyFontSize: null,
        );
        if (settings != null) {
          await _printoutService.setSettings(settings);
        }
        _loadFontSizes();
      },
    );
  }
}

class FontSizeDropdown extends StatelessWidget {
  final String label;
  final double? initialValue;
  final ValueChanged<double?> onChanged;

  const FontSizeDropdown({
    super.key,
    required this.label,
    this.initialValue,
    required this.onChanged,
  });

  static const List<double> _fontSizes = [8, 9, 10, 11, 12, 13, 14, 16, 18, 20];

  @override
  Widget build(BuildContext context) {
    return StaticDropdown<double>(
      label: label,
      items: _fontSizes,
      initialValue: initialValue,
      getDisplayText: (v) => v.toString(),
      onChanged: onChanged,
    );
  }
}
