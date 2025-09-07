import 'package:assign_erp/core/widgets/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/printout_setup/printout_color_picker.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/printout_setup/printout_layouts.dart';
import 'package:flutter/material.dart';

class PrintoutSetup extends StatelessWidget {
  const PrintoutSetup({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      noAppBar: true,
      body: CustomScrollBar(
        controller: ScrollController(),
        child: _buildBody(),
      ),
      bottomNavigationBar: const SizedBox.shrink(),
    );
  }

  _buildBody() {
    return const AdaptiveLayout(
      isSizedBox: false,
      mainAxisSize: MainAxisSize.min,
      children: [PrintoutLayouts(), PrintoutColorPickerScreen()],
    );
  }
}
