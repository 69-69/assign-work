import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:flutter/material.dart';

extension ScreenHelper on BuildContext {
  FloatingActionButton buildFloatingBtn(
    String label, {
    IconData? icon,
    Color? bgColor,
    String? tooltip,
    ShapeBorder? shape,
    void Function()? onPressed,
  }) {
    return FloatingActionButton.extended(
      heroTag: Key(tooltip ?? label),
      isExtended: label.isNotEmpty,
      backgroundColor: bgColor ?? errorColor,
      tooltip: (tooltip ?? label).toTitle,
      shape: shape,
      label: label.isEmpty
          ? const SizedBox.shrink()
          : Text(label.toTitle, style: const TextStyle(color: kWhiteColor)),
      icon: Icon(icon ?? Icons.add, color: kWhiteColor),
      onPressed: onPressed,
    );
  }

  /// Reusable icon button for critical actions like reload or sign out.
  actionIconButton({
    required IconData icon,
    required String confirmMessage,
    VoidCallback? onConfirmed,
    EdgeInsetsGeometry? padding,
    double? size,
  }) {
    return Tooltip(
      message: confirmMessage,
      child: MaterialButton(
        onPressed: () async {
          final isConfirmed = await confirmUserActionDialog(
            onAccept: confirmMessage,
          );
          if (isConfirmed) {
            onConfirmed?.call();
          }
        },
        color: kDangerColor,
        padding: padding ?? const EdgeInsets.all(14),
        shape: const CircleBorder(),
        child: Icon(icon, color: kWhiteColor, size: size),
      ),
    );
  }

  /// Icon button for full app reload [reloadAppIconButton]
  reloadAppIconButton({VoidCallback? onPressed}) {
    return actionIconButton(
      icon: Icons.refresh,
      confirmMessage: 'Refresh Workspace',
      onConfirmed: onPressed,
      padding: const EdgeInsets.all(1),
      size: 18,
    );
  }

  /// Icon button for Authorized Device IDs [resetAuthorizedDevicesIdsButton]
  resetAuthorizedDevicesIdsButton({VoidCallback? onPressed}) {
    return actionIconButton(
      icon: Icons.reset_tv,
      confirmMessage: 'Remove IDs',
      onConfirmed: onPressed,
      padding: EdgeInsets.all(15),
      size: 18,
    );
  }

  /// Icon button for sign out [SignOutIconButton]
  signOutIconButton({VoidCallback? onPressed}) {
    return actionIconButton(
      icon: Icons.logout,
      confirmMessage: 'Sign Out',
      onConfirmed: onPressed,
    );
  }

  /// sign out button [signOutButton]
  FilledButton signOutButton({VoidCallback? onPressed}) {
    return FilledButton(
      onPressed: () async {
        final isConfirmed = await confirmUserActionDialog(onAccept: 'Sign Out');
        if (isConfirmed) {
          onPressed?.call();
        }
      },
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        backgroundColor: errorColor,
      ),
      child: Text('Sign out', style: TextStyle(color: kWhiteColor)),
    );
  }

  Future<bool> confirmUserActionDialog({
    String onAccept = 'Delete',
    String? msg,
  }) async => await confirmAction<bool>(
    Text(msg ?? 'Would you like to proceed?'),
    title: "Confirm $onAccept",
    onAccept: onAccept,
    onReject: "Cancel",
  );

  /// Order-Numbers Mis-Match Warning
  Future<void> orderNumberMisMatchWarningDialog(String id) async {
    await confirmDone(
      barrierDismissible: false,
      title: "Reference Number Mismatch",
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text:
              'Selected items are unrelated. Multiple items MUST have the same Reference number: ',
          style: const TextStyle(color: kDarkTextColor),
          children: [
            TextSpan(
              text: id,
              style: const TextStyle(
                color: kDangerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Missing or InComplete Sales information Warning
  Future<void> incompleteSalesDataWarningDialog(String id) async {
    await confirmDone(
      barrierDismissible: false,
      title: "Incomplete information",
      RichText(
        text: TextSpan(
          text:
              'Some of the selected sales have incomplete information. Please uncheck or deselect those fields with missing details.',
          style: const TextStyle(color: kDarkTextColor),
          children: [
            TextSpan(
              text: '\nReceipt Number: $id',
              style: const TextStyle(
                color: kDangerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Image Size Warning
  Future<void> showImgSizeWarningDialog() async {
    await confirmDone(
      barrierDismissible: false,
      title: "Image Size Warning",
      const Text(
        'The image exceeds the maximum allowed size of 300px x 320px.',
        style: TextStyle(color: kDarkTextColor),
      ),
    );
  }

  /// Image Extension Warning
  Future<void> showImgExtensionWarningDialog() async {
    await confirmDone(
      barrierDismissible: false,
      title: "Image Type Warning",
      const Text(
        'Only the following image formats are allowed: .PNG, .JPG, .JPEG.',
        style: TextStyle(color: kDarkTextColor),
      ),
    );
  }

  /// Product/Item Scan Warning
  Future<void> showItemScanWarningDialog() async {
    await confirmDone(
      barrierDismissible: false,
      title: "Scan Warning",
      const Text(
        'Item Scan is accessible only on mobile devices.',
        style: TextStyle(color: kDarkTextColor),
      ),
    );
  }

  /// Total item counts & refresh/sync button [actionInfoButton]
  actionInfoButton(
    String tooltip, {
    String label = '',
    dynamic count = 0,
    Color? bgColor,
    Color? txtColor,
    bool isTotal = true,
    VoidCallback? onPressed,
  }) {
    final total = isTotal ? 'Total $count'.toUpperAll : count;

    return FilledButton.icon(
      icon: RefreshButton(
        tooltip: tooltip,
        callback: onPressed,
        bgColor: bgColor,
        txtColor: txtColor,
      ),
      onPressed: null,
      style: OutlinedButton.styleFrom(
        elevation: 30,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.fromLTRB(1, 1, 10, 1),
        backgroundColor: (bgColor ?? kDangerColor).toAlpha(0.7),
      ),
      label: Text(
        total,
        style: ofTheme.textTheme.titleSmall?.copyWith(color: kWhiteColor),
      ),
    );
  }

  buildRefreshButton(String tooltip, {VoidCallback? onPressed}) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: RefreshButton(tooltip: tooltip, callback: onPressed),
  );

  Center buildAddButton(String label, {required void Function()? onPressed}) =>
      Center(
        child: SizedBox(
          width: (screenWidth - 160),
          child: elevatedButton(label, onPressed: onPressed),
        ),
      );

  Center get loader =>
      Center(child: AsyncProgressBarDialog(null, isDialog: false));

  Center buildError(String error) => Center(child: Text('Error: $error'));

  buildNoResult() => const Center(child: Text('No results found'));

  optCardBuilder({
    Color? borderColor,
    String label = '',
    String? buttonLabel,
    String desc = '',
    VoidCallback? onPressed,
    IconData? icon,
    EdgeInsetsGeometry? margin,
  }) {
    return Card(
      margin: margin ?? const EdgeInsets.all(10.0),
      elevation: 7.0,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: AdaptiveLayout(
          isFormBuilder: true,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc.toTitle),
                Text(
                  label.toTitle,
                  style: const TextStyle(color: kGrayBlueColor),
                ),
              ],
            ),
            elevatedIconBtn(
              Icon(icon, color: kWhiteColor),
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(backgroundColor: borderColor),
              label: Text(
                (buttonLabel ?? label).toUpperAll,
                style: const TextStyle(color: kWhiteColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RefreshButton extends StatefulWidget {
  const RefreshButton({
    super.key,
    this.bgColor,
    this.txtColor,
    this.callback,
    this.tooltip = 'refresh',
  });

  final VoidCallback? callback;
  final String tooltip;
  final Color? bgColor;
  final Color? txtColor;

  @override
  State<RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<RefreshButton>
    with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> futureItems;
  late AnimationController controller;
  late Animation colorAnimation;
  late Animation<double> rotateAnimation;

  @override
  void initState() {
    super.initState();
    _initIconAnimation();
  }

  void _initIconAnimation() {
    controller = AnimationController(vsync: this, duration: kAnimateDuration);
    rotateAnimation = Tween<double>(begin: 0.0, end: 360.0).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSync(
      widget.tooltip,
      bgColor: widget.bgColor,
      txtColor: widget.txtColor,
      animation: rotateAnimation,
      callback: () async {
        controller.forward();
        // alert user
        context.showAlertOverlay(
          bgColor: kPrimaryAccentColor,
          duration: 3,
          '${widget.tooltip.replaceAll('Refresh', 'Refreshing')}...',
        );
        // delay & run callback function(refresh data)
        await Future.delayed(kRProgressDelay, () => widget.callback?.call());
        controller.stop();
        controller.reset();
        if (context.mounted) {
          context.showAlertOverlay(
            '${widget.tooltip.replaceAll('Refresh', '')} Successful Refreshed...',
          );
        }
      },
    );
  }
}

class AnimatedSync extends AnimatedWidget {
  final String tooltip;
  final VoidCallback callback;
  final Animation<double> animation;
  final Color? bgColor;
  final Color? txtColor;

  const AnimatedSync(
    this.tooltip, {
    super.key,
    required this.animation,
    required this.callback,
    this.bgColor,
    this.txtColor,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    // final Listenable animation = listenable;

    return Transform.rotate(
      angle: animation.value,
      child: IconButton(
        color: txtColor ?? kWhiteColor,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          elevation: 30,
          minimumSize: const Size(35, 35),
          padding: EdgeInsets.zero,
          backgroundColor: bgColor ?? kDangerColor,
        ),
        icon: Icon(Icons.sync, color: kWhiteColor, semanticLabel: tooltip),
        onPressed: () => callback(),
      ),
    );
  }
}

class GenericCard extends StatelessWidget {
  final String headTitle;
  final String title;
  final String subTitle;
  final List<Map<String, dynamic>>? extra;

  const GenericCard({
    super.key,
    required this.headTitle,
    required this.title,
    required this.subTitle,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  _buildBody(BuildContext context) {
    var textStyle = context.textTheme.titleLarge;

    return Column(
      children: [
        Text(
          headTitle,
          textAlign: TextAlign.center,
          overflow: TextOverflow.fade,
          style: textStyle?.copyWith(fontSize: 18),
          textScaler: TextScaler.linear(context.textScaleFactor),
        ),
        ListTile(
          dense: true,
          title: Text(
            title.toTitle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: textStyle?.copyWith(fontSize: 15, color: kTextColor),
            textScaler: TextScaler.linear(context.textScaleFactor),
          ),
          subtitle: Text(
            subTitle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleSmall?.copyWith(
              color: kTextColor,
              fontSize: 12,
            ),
            textScaler: TextScaler.linear(context.textScaleFactor),
          ),
        ),

        if (extra != null) ...{
          ...extra!.map((item) {
            final title = item['title'] ?? '';
            final value = item['value'] ?? '';
            return _buildRichText(context, label: title, text: value);
          }),
        },
      ],
    );
  }

  Widget _buildRichText(
    BuildContext context, {
    String label = '',
    String text = '',
  }) {
    var textStyle = context.textTheme.titleMedium;
    return Padding(
      padding: EdgeInsets.zero,
      child: RichText(
        overflow: TextOverflow.ellipsis,
        textScaler: TextScaler.linear(context.textScaleFactor),

        text: TextSpan(
          text: '$label: ',
          style: textStyle?.copyWith(fontSize: 14, color: kTextColor),
          children: [
            TextSpan(
              text: text.toTitle,
              style: textStyle?.copyWith(fontSize: 14, color: kDarkTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
