import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:flutter/material.dart';

/// [BusinessToIndustriesDropdown] Business to industries dropdown
class BusinessToIndustriesDropdown extends StatefulWidget {
  const BusinessToIndustriesDropdown({
    super.key,
    this.initialBusiness,
    this.initialIndustry,
    this.onBusinessChanged,
    this.onIndustryChanged,
  });

  final String? initialIndustry;
  final String? initialBusiness;
  final void Function(String?)? onBusinessChanged;
  final void Function(String? business, String? industry)? onIndustryChanged;

  @override
  State<BusinessToIndustriesDropdown> createState() =>
      _BusinessToIndustriesDropdownState();
}

class _BusinessToIndustriesDropdownState
    extends State<BusinessToIndustriesDropdown> {
  String? _selectedBusinessType;
  String? _selectedIndustry;

  Map<String, List<String>> get _businessToIndustries =>
      businessTypeToIndustries;

  bool isValidBusinessType(String? value) {
    if (value.isNullOrEmpty) return false;

    final lower = value.toLowerAll;
    return !lower.contains('select') && !lower.contains('type');
  }

  @override
  void initState() {
    super.initState();
    _selectedBusinessType = widget.initialBusiness;
    _selectedIndustry = widget.initialIndustry;
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      children: [
        _buildBusinessTypeDropdown(context),
        if (isValidBusinessType(_selectedBusinessType)) ...{
          _buildIndustryDropdown(context),
        },
      ],
    );
  }

  Widget _buildBusinessTypeDropdown(BuildContext context) {
    // List of business types (keys of the map)
    final businessTypes = _businessToIndustries.keys.toList();

    return StaticDropdown<String>(
      initialValue: _selectedBusinessType,
      label: 'Business Type',
      items: businessTypes,
      getDisplayText: (type) => type,
      onChanged: (String? v) {
        if (v.isNotNullNorEmpty) {
          setState(() {
            _selectedBusinessType = v?.trim();
            // reset industry when business type changes
            _selectedIndustry = null;
          });
          widget.onBusinessChanged?.call(v?.trim());
        }
      },
      /*buttonDecoration: InputDecoration(
        errorText: _selectedBusinessType.isNullOrEmpty
            ? 'Select business type'
            : null,
      ),*/
    );
  }

  Widget _buildIndustryDropdown(BuildContext context) {
    final industries = _selectedBusinessType != null
        ? _businessToIndustries[_selectedBusinessType!] ?? []
        : [];

    return StaticDropdown<String>(
      initialValue: _selectedIndustry,
      label: 'Industry',
      items: List.from(['Select Industry', ...industries]),
      getDisplayText: (industry) => industry,
      onChanged: (String? v) {
        if (v.isNotNullNorEmpty) {
          setState(() => _selectedIndustry = v?.trim());
          widget.onIndustryChanged?.call(_selectedBusinessType, v?.trim());
        }
      },
    );
  }
}

/// Business to industries grid view [BusinessToIndustriesGrid]
class BusinessToIndustriesGrid extends StatefulWidget {
  final Widget? externalWidget;
  final void Function(String?)? onBusinessChanged;
  final void Function(String? business, String? industry)? onIndustryChanged;

  const BusinessToIndustriesGrid({
    super.key,
    this.externalWidget,
    this.onBusinessChanged,
    this.onIndustryChanged,
  });

  @override
  State<BusinessToIndustriesGrid> createState() =>
      _BusinessToIndustriesGridState();
}

class _BusinessToIndustriesGridState extends State<BusinessToIndustriesGrid> {
  late double maxCrossAxisExtent;
  late double childAspectRatio;

  String? _selectedBusiness;
  String? _selectedIndustry;
  // Map to track the selected business and industry states.
  String? _highlightedBusiness;
  String? _highlightedIndustry;

  Map<String, List<String>> get _businessToIndustries =>
      businessTypeToIndustries;

  bool get _isShowingIndustries =>
      _selectedBusiness != null && _selectedIndustry == null;

  bool get _isShowingExternal =>
      _selectedBusiness != null && _selectedIndustry != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateGridLayout();
  }

  void _calculateGridLayout() {
    final screenW = context.screenWidth;
    final isPortrait = context.isPortraitMode;

    maxCrossAxisExtent = context.isMobile
        ? screenW
        : (isPortrait ? screenW / 2.2 : screenW / 3.2);

    final cardWidth = maxCrossAxisExtent;
    final cardHeight = cardWidth * 0.5;
    childAspectRatio = cardWidth / cardHeight;
  }

  bool _isPlaceholder(String key) {
    final lower = key.toLowerAll;
    return lower.contains('select') || lower.contains('type');
  }

  List<String> get _items {
    var items = _selectedBusiness == null
        ? _businessToIndustries.keys
              .where((key) => !_isPlaceholder(key))
              .toList()
        : _businessToIndustries[_selectedBusiness!] ?? [];
    items.sort();
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.screenHeight * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(context),

          if (_selectedBusiness != null || _selectedIndustry != null)
            _buildBackButtons(),
          if (_isShowingExternal && widget.externalWidget != null) ...[
            Expanded(child: widget.externalWidget!),
          ] else ...[
            const SizedBox(height: 10),
            Expanded(child: _buildSelectionGrid(context)),
          ],
        ],
      ),
    );
  }

  Wrap _buildBackButtons() {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        _buildTextButton("Change Business", () {
          setState(() {
            _selectedBusiness = null;
            _selectedIndustry = null;
          });
        }),

        if (_isShowingExternal)
          _buildTextButton('Change Industry', () {
            setState(() => _selectedIndustry = null);
          }),
      ],
    );
  }

  TextButton _buildTextButton(String label, void Function()? onPressed) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: context.onPrimaryContainer.toAlpha(0.1),
      ),
      onPressed: onPressed,
      icon: Icon(
        size: 14,
        Icons.adaptive.arrow_back,
        color: context.onSurfaceColor,
      ),
      label: Text(label, style: TextStyle(color: context.onSurfaceColor)),
    );
  }

  Widget _buildStepHeader(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      titleAlignment: ListTileTitleAlignment.center,
      title: Text(
        _selectedIndustry?.toSentence ??
            'What kind of ${_selectedBusiness?.toSentence ?? 'work do you do'}?',
        textAlign: TextAlign.center,
        style: context.textTheme.bodyLarge?.copyWith(
          color: context.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _isShowingIndustries
            ? 'Choose an industry under this business type'
            : 'This helps us personalize your Workspace experience',
        textAlign: TextAlign.center,
      ),
    );
  }

  GridView _buildSelectionGrid(BuildContext context) {
    return GridView.builder(
      primary: false,
      itemCount: _items.length,
      padding: const EdgeInsets.fromLTRB(0, 2.0, 2.0, 2.0),
      physics: const RangeMaintainingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final label = _items[index];

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedBusiness == null) {
                _selectedBusiness = label;
                _highlightedBusiness = label;
                _selectedIndustry = null;
                _highlightedIndustry = null;
                widget.onBusinessChanged?.call(label);
              } else {
                _selectedIndustry = label;
                _highlightedIndustry = label;
                widget.onIndustryChanged?.call(_selectedBusiness, label);
              }
            });
          },

          child: _buildGridItemCard(context, label: label, index: index),
        );
      },
    );
  }

  Widget _buildGridItemCard(
    BuildContext context, {
    required String label,
    required int index,
  }) {
    final isSelected = _selectedBusiness == null
        ? _highlightedBusiness == label
        : _highlightedIndustry == label;

    final ranColor = randomBgColors[index % randomBgColors.length];

    return AnimatedContainer(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20.0),
      duration: kAnimateDuration,
      decoration: BoxDecoration(
        color: isSelected ? ranColor.toAlpha(0.6) : context.onSecondaryColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: ranColor, width: 5),
      ),
      child: Tooltip(
        message: label,
        child: _buildGridItemContent(label, context),
      ),
    );
  }

  Widget _buildGridItemContent(String label, BuildContext context) {
    final subTitle = _businessToIndustries[label]
        ?.map((e) => e.toTitle)
        .join(', ');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label.toUpperAll,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            overflow: TextOverflow.ellipsis,
            color: context.onSurfaceColor,
          ),
        ),

        if (subTitle.isNotNullNorEmpty) ...[
          const SizedBox(height: 8),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              '$subTitle...',
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              style: TextStyle(color: context.onSurfaceColor),
            ),
          ),
        ],
      ],
    );
  }
}

/* String selectedIndustry = 'Food & Beverage';

List<String> businessTypesForIndustry = businessTypeToIndustries.entries
    .where((entry) => entry.value.contains(selectedIndustry))
    .map((entry) => entry.key)
    .toList();

print(businessTypesForIndustry);
// Output example: ['Manufacturer', 'Distributor', 'Wholesaler', 'Retailer', ...]
*/
