import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/printout_setup/preview_layout.dart';
import 'package:flutter/material.dart';

class PrintoutLayouts extends StatefulWidget {
  const PrintoutLayouts({super.key});

  @override
  State<PrintoutLayouts> createState() => _PrintoutLayoutsState();
}

class _PrintoutLayoutsState extends State<PrintoutLayouts> {
  int _selectedCardIndex = 0;
  // final SetupPrintOut _setupPrintOut = SetupPrintOut();

  // Assuming this list is defined somewhere in your code
  final List<String> printLayout = ['dense', 'loose'];
  final PrintoutSetupCacheService _printoutService =
      PrintoutSetupCacheService();

  @override
  void initState() {
    super.initState();
    _loadSelectedLayout();
  }

  _loadSelectedLayout() async {
    final settings = await _printoutService.getSettings();
    // debugPrint('layout:: ${settings?.layout}\ncompany-name: ${settings?.companyName}\npalette: ${settings?.paletteColor}\nhead: ${settings?.headerColor}\nfoot: ${settings?.footerColor}');

    if (settings != null) {
      setState(() {
        // If settings.layout is not in printLayout, indexOf will return -1
        _selectedCardIndex = printLayout.indexOf(settings.layout);
      });
    }
  }

  Future<void> _handleCardSelection(int index, String label) async {
    setState(() => _selectedCardIndex = index);

    // final settings = _setupPrintOut.copyWith(layout: label.toLowerCase());
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
    return _buildBody();
  }

  Widget _buildBody() {
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
          itemBuilder: (context, i) => _buildCard(i, printLayout[i]),
        ),
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
          _buildResetColorsButton(),
        ],
      ),
      subtitle: Text(
        "This layout will be used for printing invoices, receipts, reports, etc...",
        textAlign: TextAlign.center,
        style: context.textTheme.titleSmall,
      ),
    );
  }

  RefreshButton _buildResetColorsButton() {
    return RefreshButton(
      tooltip: 'Reset Layout',
      callback: () async {
        final settings = (await _printoutService.getSettings())?.copyWith(
          layout: '',
        );
        if (settings != null) {
          await _printoutService.setSettings(settings);
        }
        _loadSelectedLayout();
      },
    );
  }

  Widget _buildCard(int index, String label) {
    final assetName = index > 0 ? loosePrintLayout : densePrintLayout;
    label = label.toLowerAll;

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
        child: RadioListTile.adaptive(
          dense: true,
          value: index,
          groupValue: _selectedCardIndex,
          fillColor: const WidgetStatePropertyAll(kWarningColor),
          onChanged: (int? value) async {
            if (value != null) {
              await _handleCardSelection(value, label);
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
        ),
      ),
    );
  }
}
