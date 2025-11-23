import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/color_convention_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/printout_setup/widget/preview_printout_colors.dart';
import 'package:flutter/material.dart';

// Define color palettes
final List<List<Color>> colorPalettes = [
  [Colors.blue, Colors.red, Colors.green, Colors.grey],
  [Colors.orange, Colors.purple, Colors.cyan, Colors.brown],
  [Colors.yellow, Colors.teal, Colors.pink, Colors.indigo],
  // [Colors.grey, Colors.brown, Colors.indigo],
];

class PrintoutColorPickerScreen extends StatefulWidget {
  const PrintoutColorPickerScreen({super.key});

  @override
  State<PrintoutColorPickerScreen> createState() =>
      _PrintoutColorPickerScreenState();
}

class _PrintoutColorPickerScreenState extends State<PrintoutColorPickerScreen> {
  int _selectedPaletteIndex = 0;
  List<Color> _selectedPalette = [];
  final PrintoutSetupCacheService _printoutService =
      PrintoutSetupCacheService();

  @override
  void initState() {
    super.initState();
    _loadSavedColors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _loadSelectedColors();
  }

  void _loadSavedColors() async {
    final settings = await _printoutService.getSettings();

    if (settings != null) {
      setState(() {
        // Convert the list of color strings to List<Color>
        final matchedPalette = stringListToColors(settings.paletteColor);

        final matchPalettes =
            _findMatchingColorPalette(matchedPalette) ?? colorPalettes.first;
        _selectedPalette = matchPalettes;
        // If colors are not in colorPalettes, indexOf will return -1
        _selectedPaletteIndex = colorPalettes.indexOf(matchPalettes);
      });
    }
  }

  // Find and return the matching colors palette
  List<Color>? _findMatchingColorPalette(List<Color> colors) {
    String selectedColorsString = colorsToString(colors);

    for (List<Color> palette in colorPalettes) {
      if (colorsToString(palette) == selectedColorsString) {
        return palette;
      }
    }
    return null; // If no match found
  }

  Future<void> _handleSelectedPalette(int index, String label) async {
    setState(() {
      _selectedPaletteIndex = index;
      _selectedPalette = colorPalettes[index];
    });

    await _saveSelectedPalette(label);
  }

  Future<void> _saveSelectedPalette(String label) async {
    final settings = (await _printoutService.getSettings())?.copyWith(
      paletteColor: _selectedPalette.map((color) => color.toHex()).toList(),
    );
    if (settings != null) {
      await _printoutService.setSettings(settings);
    }
    if (mounted) {
      context.showAlertOverlay('You Selected Palette option $label');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: _PaletteBody(
        selectedPalette: _selectedPalette,
        selectedPaletteIndex: _selectedPaletteIndex,
        onSelectedPalette: (i) async =>
            await _handleSelectedPalette(i, (i + 1).toString()),
        resetColors: _buildResetColorsButton(),
      ),
    );
  }

  RefreshButton _buildResetColorsButton() {
    return RefreshButton(
      tooltip: 'Reset Colors',
      callback: () async {
        final settings = await _printoutService.getSettings();
        if (settings != null) {
          await _printoutService.setSettings(
            settings.copyWith(
              paletteColor: [],
              headerColor: '',
              footerColor: '',
            ),
          );
          _loadSavedColors(); // Refresh the state after resetting
        }
      },
    );
  }
}

class _PaletteBody extends StatelessWidget {
  const _PaletteBody({
    required this.selectedPaletteIndex,
    required this.onSelectedPalette,
    required this.selectedPalette,
    required this.resetColors,
  });

  final int selectedPaletteIndex;
  final List<Color> selectedPalette;
  final Function(int) onSelectedPalette;
  final RefreshButton resetColors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPaletteTitle(context),
        _buildPalette(),
        HorizontalDivider(thickness: 8.0),
        if (selectedPalette.isNotEmpty) ...{
          PreviewPrintoutColors(paletteColors: selectedPalette),
        },
        const SizedBox(height: 50),
      ],
    );
  }

  ListTile _buildPaletteTitle(BuildContext context) {
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
            'Print Colors',
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          resetColors,
        ],
      ),
      subtitle: Text(
        "This color will be used for the header and footer of invoices, receipts, reports, etc...\nClick on any Palette to see various previews.",
        textAlign: TextAlign.center,
        style: context.textTheme.titleSmall,
      ),
    );
  }

  _buildPalette() {
    return GridView.builder(
      primary: false,
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: colorPalettes.length,
      itemBuilder: (context, index) => _buildCard(index),
    );
  }

  _buildCard(int index) {
    final i = index + 1;
    final paletteColor = colorPalettes[index].first;

    var isSelected = selectedPaletteIndex == index;
    var fadeColor = paletteColor.toAlpha(0.6);
    return Card(
      elevation: 20,
      color: paletteColor,
      child: ChoiceChip(
        tooltip: 'Palette $i',
        side: BorderSide(color: paletteColor),
        padding: EdgeInsets.zero,
        showCheckmark: true,
        color: WidgetStatePropertyAll(fadeColor),
        selected: isSelected,
        backgroundColor: isSelected ? fadeColor : paletteColor,
        label: Text('Palette $i', overflow: TextOverflow.ellipsis),
        onSelected: (b) {
          if (!isSelected) {
            onSelectedPalette(index);
          }
        },
      ),
    );
  }
}
