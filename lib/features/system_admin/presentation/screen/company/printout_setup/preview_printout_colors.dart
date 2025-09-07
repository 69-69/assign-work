import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/color_convention_util.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:flutter/material.dart';

class PreviewPrintoutColors extends StatefulWidget {
  const PreviewPrintoutColors({super.key, required this.paletteColors});

  final List<Color> paletteColors;

  @override
  State<PreviewPrintoutColors> createState() => _PreviewPrintoutColorsState();
}

class _PreviewPrintoutColorsState extends State<PreviewPrintoutColors> {
  int? _selectedHeaderPreviewIndex;
  int? _selectedFooterPreviewIndex;
  final PrintoutSetupCacheService _printoutService =
      PrintoutSetupCacheService();

  List<Color> get paletteColors => widget.paletteColors;

  @override
  void initState() {
    super.initState();

    _loadSelectedColors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSelectedColors();
  }

  void _loadSelectedColors() async {
    final settings = await _printoutService.getSettings();
    if (settings != null) {
      setState(() {
        // Find the index of the palette that contains the header color
        _selectedHeaderPreviewIndex = _findColorIndex(settings.headerColor);
        _selectedFooterPreviewIndex = _findColorIndex(settings.footerColor);
      });
    }
  }

  // Find the index of the palette that matches the selected color index
  int _findColorIndex(String colorString) {
    return paletteColors.indexWhere((color) => color.toHex() == colorString);
  }

  /// Printout Header Color [_handleHeaderPreviewSelection]
  Future<void> _handleHeaderPreviewSelection(int index, String label) async {
    setState(() => _selectedHeaderPreviewIndex = index);

    // debugPrint('head: ${paletteColors[index].toHex()}');

    await _saveSelectedHeaderPrev(index, label);
  }

  /// Printout Footer Color [_handleFooterPreviewSelection]
  Future<void> _handleFooterPreviewSelection(int index, String label) async {
    setState(() => _selectedFooterPreviewIndex = index);

    // debugPrint('foot: ${paletteColors[index].toHex()}');

    await _saveSelectedFooterPrev(index, label);
  }

  Future<void> _saveSelectedHeaderPrev(int index, String label) async {
    final settings = (await _printoutService.getSettings())?.copyWith(
      headerColor: paletteColors[index].toHex(),
    );
    if (settings != null) {
      await _printoutService.setSettings(settings);
    }

    if (mounted) {
      context.showAlertOverlay('You Selected Header Preview option $label');
    }
  }

  Future<void> _saveSelectedFooterPrev(int index, String label) async {
    final settings = (await _printoutService.getSettings())?.copyWith(
      footerColor: paletteColors[index].toHex(),
    );
    if (settings != null) {
      await _printoutService.setSettings(settings);
    }

    if (mounted) {
      context.showAlertOverlay('You Selected Footer Preview option $label');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      // direction: Axis.vertical,
      // mainAxisSize: MainAxisSize.min,
      // alignment: WrapAlignment.center,
      // runAlignment: WrapAlignment.center,
      // crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildPreviewTitle(context),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: _buildText(context, 'Header Color:'.toUpperAll),
        ),
        _buildHeader(context),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: _buildText(context, 'Footer Color:'.toUpperAll),
        ),
        _buildFooter(context),
      ],
    );
  }

  ListTile _buildPreviewTitle(BuildContext context) {
    return ListTile(
      dense: true,
      titleAlignment: ListTileTitleAlignment.center,
      title: _buildText(context, 'Preview:', color: kDarkTextColor),
      subtitle: Text(
        'Choose one color for your print-out (PDFs)',
        textAlign: TextAlign.center,
        style: context.textTheme.titleSmall,
      ),
    );
  }

  Text _buildText(
    BuildContext context,
    String label, {
    Color color = kTextColor,
  }) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: context.textTheme.titleMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  _buildHeader(BuildContext context) {
    return _previewCard(
      'Header',
      previewIndex: _selectedHeaderPreviewIndex,
      onTap: (i) async => await _handleHeaderPreviewSelection(i, '${i + 1}'),
    );
  }

  _buildFooter(BuildContext context) {
    return _previewCard(
      'Footer',
      previewIndex: _selectedFooterPreviewIndex,
      onTap: (i) async => await _handleFooterPreviewSelection(i, '${i + 1}'),
    );
  }

  _previewCard(String label, {int? previewIndex, Function(int)? onTap}) {
    // var width = (context.screenWidth / 2) / 4;

    return GridView.builder(
      primary: false,
      shrinkWrap: true,
      itemCount: paletteColors.length,
      physics: const RangeMaintainingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2,
      ),
      itemBuilder: (context, index) {
        final paletteColor = paletteColors[index];

        var isSelected = previewIndex == index;

        var fadeColor = paletteColor.toAlpha(0.6);
        return Card(
          elevation: 20,
          color: paletteColor,
          child: ChoiceChip(
            tooltip: '$label ${index + 1}',
            padding: EdgeInsets.zero,
            // symmetric(horizontal: width / 5, vertical: width / 8),
            showCheckmark: true,
            color: WidgetStatePropertyAll(fadeColor),
            selected: isSelected,
            backgroundColor: isSelected ? fadeColor : paletteColor,
            side: BorderSide(color: paletteColor),
            label: Text(
              /*paletteColors[index].toHex(),*/
              '$label  ${index + 1}',
              overflow: TextOverflow.ellipsis,
            ),
            onSelected: (b) {
              if (previewIndex != null && !isSelected) {
                onTap?.call(index);
              }
            },
          ),
        );
      },
    );

    /*return Container(
      width: 100,
      height: 50,
      color: widget.paletteColors[index],
      alignment: Alignment.center,
      margin: const EdgeInsets.all(4),
      child: RadioListTile.adaptive(
        dense: true,
        value: index,
        fillColor: const WidgetStatePropertyAll(kLightColor),
        groupValue: groupValue,
        onChanged: (int? value) {
          if (value != null) {
            onTap?.call(value);
          }
        },
        title: Text('${i}'),
      ),
    ).addNeumorphism(offset: const Offset(-1, -1));*/
  }
}
