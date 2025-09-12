import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:flutter/material.dart';

///
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
      /*spacing: 10,
      runSpacing: 10,*/
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
    final businessTypes = businessTypeToIndustries.keys.toList();

    return StaticDropdown<String>(
      initialValue: _selectedBusinessType,
      label: 'Business Type',
      items: businessTypes,
      getValue: (type) => type,
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
        ? businessTypeToIndustries[_selectedBusinessType!] ?? []
        : [];

    return StaticDropdown<String>(
      initialValue: _selectedIndustry,
      label: 'Industry',
      items: List.from(['Select Industry', ...industries]),
      getValue: (industry) => industry,
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

class BusinessIndustryType extends StatefulWidget {
  final Widget? externalWidget;
  final void Function(String?)? onBusinessChanged;
  final void Function(String? business, String? industry)? onIndustryChanged;

  const BusinessIndustryType({
    super.key,
    this.externalWidget,
    this.onBusinessChanged,
    this.onIndustryChanged,
  });

  @override
  State<BusinessIndustryType> createState() => _BusinessIndustryTypeState();
}

class _BusinessIndustryTypeState extends State<BusinessIndustryType> {
  late double maxCrossAxisExtent;
  late double childAspectRatio;

  String? _selectedBusiness;
  String? _selectedIndustry;

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
        : isPortrait
        ? screenW / 2.2
        : screenW / 3.2;

    final cardWidth = maxCrossAxisExtent;
    final cardHeight = cardWidth * 0.5;
    childAspectRatio = cardWidth / cardHeight;
  }

  bool _isPlaceholder(String key) {
    final lower = key.toLowerAll;
    return lower.contains('select') || lower.contains('type');
  }

  List<String> get _items {
    return _selectedBusiness == null
        ? _businessToIndustries.keys
              .where((key) => !_isPlaceholder(key))
              .toList()
        : _businessToIndustries[_selectedBusiness!] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.screenHeight * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(context),

          if (_selectedBusiness != null || _selectedIndustry != null)
            _buildBackButtons(),

          if (_isShowingExternal && widget.externalWidget != null) ...[
            widget.externalWidget!,
          ] else ...[
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
        TextButton.icon(
          onPressed: () {
            setState(() {
              _selectedBusiness = null;
              _selectedIndustry = null;
            });
          },
          icon: Icon(Icons.adaptive.arrow_back),
          label: const Text("Change Business Type"),
        ),
        if (_isShowingExternal)
          TextButton.icon(
            onPressed: () => setState(() => _selectedIndustry = null),
            icon: Icon(Icons.adaptive.arrow_back),
            label: const Text('Change Industry'),
          ),
      ],
    );
  }

  Widget _buildStepHeader(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      titleAlignment: ListTileTitleAlignment.center,
      title: Text(
        _selectedBusiness?.toSentence ?? 'What kind of work do you do?',
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
            if (_selectedBusiness == null) {
              setState(() {
                _selectedBusiness = label;
                _selectedIndustry = null;
              });
              widget.onBusinessChanged?.call(label);
            } else {
              setState(() => _selectedIndustry = label);
              widget.onIndustryChanged?.call(_selectedBusiness, label);
            }
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
        ? _selectedBusiness == label
        : _selectedIndustry == label;
    final ranColor = randomBgColors[index % randomBgColors.length];

    return AnimatedContainer(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20.0),
      duration: kAnimateDuration,
      decoration: BoxDecoration(
        color: isSelected ? ranColor.toAlpha(0.6) : ranColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(
          color: isSelected ? ranColor : kTransparentColor,
          width: 3,
        ),
      ),
      child: _buildGridItemContent(label, context),
    );
  }

  Widget _buildGridItemContent(String label, BuildContext context) {
    final subTitle = _businessToIndustries[label]
        ?.map((e) => e.toTitle)
        .join(', ');

    return Column(
      children: [
        Text(
          label.toUpperAll,
          softWrap: true,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: kWhiteColor,
          ),
        ),
        if (subTitle.isNotNullNorEmpty) ...[
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              '$subTitle...',
              overflow: TextOverflow.fade,
              style: const TextStyle(color: kOffWhiteColor),
            ),
          ),
        ],
      ],
    );
  }
}

/*String selectedIndustry = 'Food & Beverage';

List<String> businessTypesForIndustry = businessTypeToIndustries.entries
    .where((entry) => entry.value.contains(selectedIndustry))
    .map((entry) => entry.key)
    .toList();

print(businessTypesForIndustry);
// Output example: ['Manufacturer', 'Distributor', 'Wholesaler', 'Retailer', ...]
*/
