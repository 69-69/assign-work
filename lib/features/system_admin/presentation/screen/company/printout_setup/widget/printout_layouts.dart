import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/form/custom_radio_tile.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/printout_setup/widget/preview_layout.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/printout_setup/widget/printout_font_size.dart';
import 'package:flutter/material.dart';

class PrintoutLayouts extends StatefulWidget {
  const PrintoutLayouts({super.key});

  @override
  State<PrintoutLayouts> createState() => _PrintoutLayoutsState();
}

class _PrintoutLayoutsState extends State<PrintoutLayouts> {
  int _selectedCardIndex = 0;

  // Assuming this list is defined somewhere in your code
  final List<String> printLayout = ['dense', 'loose'];
  final PrintSetupCacheService _printoutService = PrintSetupCacheService();

  @override
  void initState() {
    super.initState();
    _loadSavedLayout();
  }

  _loadSavedLayout() async {
    final settings = await _printoutService.getSettings();

    if (settings != null) {
      setState(() {
        // If settings.layout is not in printLayout, indexOf will return -1
        _selectedCardIndex = printLayout.indexOf(settings.layout);
      });
    }
  }

  Future<void> _handleCardSelection(int index, String label) async {
    setState(() => _selectedCardIndex = index);
    await _saveCardSelection(label);
  }

  Future<void> _saveCardSelection(String label) async {
    final settings = (await _printoutService.getSettings())?.copyWith(
      layout: label.toLowerAll,
    );
    if (settings != null) {
      await _printoutService.setSettings(settings);
    }

    if (mounted) {
      context.showAlertOverlay('You Selected $label Layout');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLayoutTitle(context),
        GridView.builder(
          primary: false,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: printLayout.length,
          physics: const RangeMaintainingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          itemBuilder: (context, i) => _LayoutBody(
            index: i,
            title: printLayout[i],
            groupValue: _selectedCardIndex,
            onChanged: _handleCardSelection,
          ),
        ),
        PrintoutFontSizeScreen(),
        const SizedBox(height: 50),
      ],
    );
  }

  ListTile _buildLayoutTitle(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.all(10.0),
      titleAlignment: ListTileTitleAlignment.center,
      title: Wrap(
        spacing: 5,
        direction: Axis.horizontal,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Print Layout',
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildRefreshColorsButton(),
        ],
      ),
      subtitle: Text(
        "This layout will be used for printing invoices, receipts, reports, etc...",
        textAlign: TextAlign.center,
        style: context.textTheme.titleSmall,
      ),
    );
  }

  RefreshButton _buildRefreshColorsButton() {
    return RefreshButton(
      tooltip: 'Reset & Refresh Layout',
      callback: () async {
        final settings = (await _printoutService.getSettings())?.copyWith(
          layout: '',
        );
        if (settings != null) {
          await _printoutService.setSettings(settings);
        }
        _loadSavedLayout();
      },
    );
  }
}

class _LayoutBody extends StatelessWidget {
  const _LayoutBody({
    required this.index,
    required this.title,
    required this.groupValue,
    required this.onChanged,
  });

  final int index;
  final String title;
  final int groupValue;
  final Future<void> Function(int, String) onChanged;

  @override
  Widget build(BuildContext context) {
    final assetName = index > 0 ? loosePrintLayout : densePrintLayout;
    final label = title.toLowerAll;

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 5,
      child: Container(
        decoration: BoxDecoration(
          color: kTextColor,
          image: DecorationImage(
            image: AssetImage(assetName),
            fit: BoxFit.contain,
          ),
        ),
        padding: EdgeInsets.zero,
        child: _buildRadioTile(context, label, assetName),
      ),
    );
  }

  CustomRadioList<int> _buildRadioTile(
    BuildContext context,
    String label,
    String assetName,
  ) {
    return CustomRadioList<int>(
      groupValue: groupValue,
      tileColor: kWarningColor.toAlpha(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onChanged: (value) async {
        if (value != null) {
          await onChanged(value, label);
        }
      },
      options: [
        CustomRadioModel<int>(
          value: index,
          title: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleSmall?.copyWith(
              color: kDangerColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          secondary: IconButton(
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: kWarningColor.toAlpha(0.5),
            ),
            onPressed: () =>
                context.previewLayout(img: assetName, layoutName: label),
            icon: const Icon(Icons.zoom_in, color: kWhiteColor),
          ),
        ),
      ],
    );
  }
}

/*class _LayoutBody extends StatelessWidget {
  const _LayoutBody({
    required this.index,
    required this.title,
    required this.selectedCardIndex,
    required this.onCardSelected,
  });

  final int index;
  final String title;
  final int selectedCardIndex;
  final Future<void> Function(int, String) onCardSelected;

  @override
  Widget build(BuildContext context) {
    final assetName = index > 0 ? loosePrintLayout : densePrintLayout;

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 5,
      child: Container(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: kTextColor,
          image: DecorationImage(
            image: AssetImage(assetName),
            fit: BoxFit.contain,
          ),
        ),
        child: _buildRadioTile(context, assetName),
      ),
    );
  }

  RadioListTile<int> _buildRadioTile(BuildContext context, String assetName) {
    final label = title.toLowerAll;

    return RadioListTile.adaptive(
      dense: true,
      value: index,
      groupValue: selectedCardIndex,
      fillColor: const WidgetStatePropertyAll(kWarningColor),
      onChanged: (int? v) async {
        if (v != null) {
          await onCardSelected(v, label);
        }
      },
      title: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.titleSmall?.copyWith(
          color: kDangerColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      secondary: IconButton(
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: kWarningColor.toAlpha(0.5),
        ),
        onPressed: () =>
            context.previewLayout(img: assetName, layoutName: label),
        icon: const Icon(Icons.zoom_in, color: kWhiteColor),
      ),
    );
  }
}
*/
