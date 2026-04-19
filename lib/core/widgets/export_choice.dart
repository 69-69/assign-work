import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/extensions/doc_type_mode.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_dialog.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:flutter/material.dart';

extension ExportChoicePopUp on BuildContext {
  Future<ExportType?> openExportChoice(
    ExportMode exportMode, {
    Function(dynamic)? onCancel,
  }) async => await ExportChoice(exportMode: exportMode, onCancel: onCancel)
      .openCustomDialog<ExportType>(
        this,
        isScrollControlled: true,
        constraints: null,
      );
}

class ExportChoice extends StatefulWidget {
  final ExportMode exportMode;
  final Function(dynamic)? onCancel;

  const ExportChoice({super.key, required this.exportMode, this.onCancel});

  @override
  State<ExportChoice> createState() => _ExportChoiceState();
}

class _ExportChoiceState extends State<ExportChoice> {
  ExportType? _selectedFileType;

  ExportMode get _exportMode => widget.exportMode;

  String get _label =>
      _exportMode == ExportMode.data ? "Export Data" : "Download Template";

  @override
  Widget build(BuildContext context) {
    return _buildAlertDialog(context);
  }

  _buildAlertDialog(BuildContext context) {
    return CustomDialog(
      bgColor: context.scaffoldBgColor,
      title: DialogTitle(
        title: _label,
        subtitle: 'Choose a format for this $_exportMode (PDF, CSV, or Excel)',
      ),
      body: _buildBody(context),
      actions: [
        context.confirmableActionButton(
          label: _label,
          onPressed: _selectedFileType == null
              ? null
              : () => Navigator.pop(context, _selectedFileType),
          isDisabled: _selectedFileType == null,
          onCancelCallback: widget.onCancel,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      width: context.screenWidth,
      padding: EdgeInsets.only(bottom: context.bottomInsetPadding),
      margin: EdgeInsets.zero,
      child: AdaptiveLayout(
        children: ExportType.values.map((type) {
          final isSelected = _selectedFileType == type;

          final baseColor = _baseColor(type);

          final color = isSelected ? baseColor : context.outlineColor;

          final icon = _selectedIcon(type);

          return ChoiceChip(
            selected: isSelected,
            tooltip: 'Export as ${type.name.toSentence}',
            padding: EdgeInsets.all(20),
            selectedColor: baseColor.toAlpha(0.15),
            checkmarkColor: baseColor,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                  semanticLabel: 'file type: $type',
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    type.name.toUpperAll,
                    overflow: TextOverflow.fade,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            onSelected: (_) => setState(() => _selectedFileType = type),
          );
        }).toList(),
      ),
    );
  }

  IconData _selectedIcon(ExportType type) {
    return switch (type) {
      ExportType.pdf => Icons.picture_as_pdf,
      ExportType.excel => Icons.table_chart,
      ExportType.csv => Icons.grid_on,
    };
  }

  Color _baseColor(ExportType type) {
    return switch (type) {
      ExportType.pdf => kDangerColor,
      ExportType.excel => kDarkSuccessColor,
      ExportType.csv => kPrimaryAccentColor,
    };
  }
}
