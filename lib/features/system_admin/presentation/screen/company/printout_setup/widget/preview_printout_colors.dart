import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/color_convention_util.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:flutter/material.dart';

enum _PreviewType { header, footer }

extension _PreviewTypeExtension on _PreviewType {
  String get label => switch (this) {
    _PreviewType.header => 'header',
    _PreviewType.footer => 'footer',
  };

  String get title => label.toTitle;
}

class PreviewPrintoutColors extends StatefulWidget {
  const PreviewPrintoutColors({super.key, required this.paletteColors});

  final List<Color> paletteColors;

  @override
  State<PreviewPrintoutColors> createState() => _PreviewPrintoutColorsState();
}

class _PreviewPrintoutColorsState extends State<PreviewPrintoutColors> {
  int? _selectedHeaderPreviewIndex;
  int? _selectedFooterPreviewIndex;
  final PrintSetupCacheService _printoutService = PrintSetupCacheService();

  List<Color> get paletteColors => widget.paletteColors;

  @override
  void initState() {
    super.initState();

    _loadSavedColors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _loadSavedColors();
  }

  void _loadSavedColors() async {
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

  Future<void> _handleSelection(_PreviewType type, int index) async {
    final preview = switch (type) {
      _PreviewType.header => _selectedHeaderPreviewIndex = index,
      _PreviewType.footer => _selectedFooterPreviewIndex = index,
    };
    setState(() => preview);
    await _saveSelection(type, index);
  }

  Future<void> _saveSelection(_PreviewType type, int index) async {
    final remote = await _printoutService.getSettings();
    if (remote == null) return;

    final updater = switch (type) {
      _PreviewType.header => remote.copyWith(
        headerColor: paletteColors[index].toHex(),
      ),
      _PreviewType.footer => remote.copyWith(
        footerColor: paletteColors[index].toHex(),
      ),
    };

    // Apply only the matching update
    await _printoutService.setSettings(updater);
    // prettyPrint(label, '${paletteColors[index].toHex()}');

    if (mounted) {
      context.showAlertOverlay(
        'You selected ${type.title} option ${index + 1}'.toTitle,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PreviewBody(
      paletteColors: paletteColors,
      selectedFooterIndex: _selectedFooterPreviewIndex,
      selectedHeaderIndex: _selectedHeaderPreviewIndex,
      onTapFooter: (i) async => await _handleSelection(_PreviewType.footer, i),
      onTapHeader: (i) async => await _handleSelection(_PreviewType.header, i),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.paletteColors,
    this.selectedFooterIndex,
    this.selectedHeaderIndex,
    this.onTapFooter,
    this.onTapHeader,
  });

  final int? selectedFooterIndex;
  final int? selectedHeaderIndex;
  final List<Color> paletteColors;
  final Function(int)? onTapFooter;
  final Function(int)? onTapHeader;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPreviewTitle(context),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: _buildText(context, 'Header Color:'.toUpperAll),
        ),
        _previewCard(
          'Header',
          previewIndex: selectedHeaderIndex,
          onTap: onTapHeader,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: _buildText(context, 'Footer Color:'.toUpperAll),
        ),
        _previewCard(
          'Footer',
          previewIndex: selectedFooterIndex,
          onTap: onTapFooter,
        ),
      ],
    );
  }

  ListTile _buildPreviewTitle(BuildContext context) {
    return ListTile(
      dense: true,
      titleAlignment: ListTileTitleAlignment.center,
      title: _buildText(context, 'Preview:', color: context.onSurfaceColor),
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

  _previewCard(String label, {int? previewIndex, Function(int)? onTap}) {
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
            showCheckmark: true,
            color: WidgetStatePropertyAll(fadeColor),
            selected: isSelected,
            backgroundColor: isSelected ? fadeColor : paletteColor,
            side: BorderSide(color: paletteColor),
            label: Text(
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
  }
}
