import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:flutter/material.dart';

extension LiveSupportBottomSheet<T> on BuildContext {
  Future<void> openLiveSupportDialog() => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(title: 'Live Chat', body: _LiveSupport()),
  );
}

class _LiveSupport extends StatefulWidget {
  const _LiveSupport();

  @override
  State<_LiveSupport> createState() => _LiveSupportState();
}

class _LiveSupportState extends State<_LiveSupport> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildBody(context)],
    );
  }

  _buildBody(BuildContext context) {
    return Container(
      color: kGrayColor.toAlpha(0.2),
      alignment: Alignment.bottomLeft,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Text('chat message'),
    );
  }
}
