import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/form_group_card.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/procurement/data/data_sources/remote/get_suppliers.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_link_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:flutter/material.dart';

extension ChooseSuppliersForRFQExtensions on BuildContext {
  /// [openRFQWithSuppliers] Opens List of Invited Suppliers
  Future<void> openRFQWithSuppliers({
    String subTitle = 'view their RFQ details',
    required List<SupplierLink> supplierLinks,
    required void Function(Supplier) onSelected,
  }) => openBottomSheet(
    isExpand: false,
    showZoomIcon: false,
    constraints: BoxConstraints(maxWidth: dynamicWidth(0.5)),
    child: BottomSheetScaffold(
      isDetails: true,
      initialSize: 0.7,
      title: 'Suppliers Invited to RFQ',
      body: FormGroupCard(
        title: 'RFQ Invited Suppliers: [${supplierLinks.length}]',
        subTitle: '\nSelect a supplier below to $subTitle\n',
        showCollapseButton: false,
        children: [
          _RfqInvitedSuppliers(
            supplierLinks: supplierLinks,
            onSelected: onSelected,
          ),
        ],
      ),
    ),
  );
}

class _RfqInvitedSuppliers extends StatefulWidget {
  final List<SupplierLink> supplierLinks;
  final void Function(Supplier) onSelected;

  const _RfqInvitedSuppliers({
    required this.supplierLinks,
    required this.onSelected,
  });

  @override
  State<_RfqInvitedSuppliers> createState() => _RfqInvitedSuppliersState();
}

class _RfqInvitedSuppliersState extends State<_RfqInvitedSuppliers> {
  final Map<String, Supplier?> _supplierCache = {};
  bool _isLoading = true;

  List<SupplierLink> get _supplierLinks => widget.supplierLinks;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    for (final link in _supplierLinks) {
      // Skip if supplier already loaded (prevents duplicates & re-fetch)
      if (_supplierCache.containsKey(link.supplierId)) continue;

      final supplier = await _getSupplier(link.supplierId);
      _supplierCache[link.supplierId] = supplier;
      /*prettyPrint(
        'Loading supplier ${link.supplierId}, ',
        'cached=${_supplierCache.containsKey(link.supplierId)}',
      );*/
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? context.loader : _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final maxVisibleHeight = context.getMaxVisibleHeight(
      itemCount: _supplierLinks.length,
    );

    return SizedBox(
      height: maxVisibleHeight,
      child: ListView.builder(
        itemCount: _supplierLinks.length,
        itemBuilder: (context, i) {
          final supplierId = _supplierLinks[i].supplierId;
          final supplier = _supplierCache[supplierId];

          if (supplier == null) {
            return const SizedBox.shrink();
          }

          return InkWell(
            onTap: () => widget.onSelected(supplier),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(supplier.name.toTitle),
                  subtitle: Wrap(
                    spacing: 5,
                    children: [
                      _buildMiniLabel(context, 'ID', supplier.code.toUpperAll),
                      _buildMiniLabel(
                        context,
                        ' | Email',
                        supplier.email.toLowerAll,
                      ),
                    ],
                  ),
                ),
                HorizontalDivider(),
              ],
            ),
          );
        },
      ),
    );
  }

  RichText _buildMiniLabel(BuildContext context, String label, String value) {
    return RichText(
      text: TextSpan(
        text: '$label: ',
        style: TextStyle(
          color: context.secondaryColor,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              color: context.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  static Future<Supplier?> _getSupplier(String supplierId) async {
    final supplier = await GetSuppliers.bySupplierId(supplierId);
    return supplier.isEmpty ? null : supplier;
  }
}
