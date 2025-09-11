import 'package:assign_erp/core/constants/app_drop_options.dart';
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

/*String selectedIndustry = 'Food & Beverage';

List<String> businessTypesForIndustry = businessTypeToIndustries.entries
    .where((entry) => entry.value.contains(selectedIndustry))
    .map((entry) => entry.key)
    .toList();

print(businessTypesForIndustry);
// Output example: ['Manufacturer', 'Distributor', 'Wholesaler', 'Retailer', ...]
*/
