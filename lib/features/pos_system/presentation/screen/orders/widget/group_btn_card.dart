import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/orders/create/create_pos_order.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/orders/scan_to_order/scan_to_add_pos_order.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/search_pos_product/search_pos_products.dart';
import 'package:flutter/material.dart';

extension GroupBtnCard on BuildContext {
  buildPOSGroupBtn() {
    return Card(
      elevation: 55,
      color: errorColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: FittedBox(
        child: Row(
          children: [
            const SearchPosProducts(),
            buildFloatingBtn(
              '',
              tooltip: 'Place an Order',
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              onPressed: () => openAddPOSOrder(),
            ),
            ScanToAddOrder(),
          ],
        ),
      ),
    );
  }

  /*Widget _groupBtn(BuildContext cxt) {
    return GroupButtons(
      borderRadius: 15.0,
      selectedColor: kLightColor,
      fillColor: cxt.ofTheme.primaryColor,
      children: [
        _iconButton(
          Icons.add,
          tooltip: 'Place an Order',
          onPressed: () => cxt.openAddPOSOrder(),
        ),
        const SearchPosProducts(),
        _iconButton(
          Icons.qr_code_scanner,
          tooltip: 'Scan Product',
          onPressed: () => cxt.openPosScan(),
        ),
      ],
    ).addNeumorphism(
      borderRadius: 15,
      bgColor: kLightColor,
      offset: const Offset(0, 0),
    );
  }

  IconButton _iconButton(IconData icon, {String tooltip = '', VoidCallback? onPressed}) {
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }*/
}
