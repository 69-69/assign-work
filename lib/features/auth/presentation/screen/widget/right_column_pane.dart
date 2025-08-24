import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:flutter/material.dart';

import 'master_reset.dart';

class RightColumnPane extends StatelessWidget {
  final Widget? signOutButton;
  final List<Widget> children;

  const RightColumnPane({
    super.key,
    required this.children,
    this.signOutButton,
  });

  @override
  Widget build(BuildContext context) {
    return _buildRightColumn(context);
  }

  Container _buildRightColumn(BuildContext context) {
    return Container(
      color: kLightBlueColor.toAlpha(0.9),
      width: context.screenWidth,
      height: context.screenHeight,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Need Help?',
                  softWrap: false,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    overflow: TextOverflow.ellipsis,
                    color: context.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              // Sign out button
              signOutButton ?? MasterResetButton(),
            ],
          ),
          HorizontalDivider(thickness: 8.0),
          ...children,
        ],
      ),
    );
  }
}
