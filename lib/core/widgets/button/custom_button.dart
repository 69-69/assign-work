import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:flutter/material.dart';

extension Custombutton on BuildContext {
  BorderRadius get _borderRadius => const BorderRadius.all(Radius.circular(10));

  /// [confirmableActionButton] A customizable elevated button widget that optionally shows a confirmation dialog
  /// before executing an action. Ideal for form submissions or critical updates.
  ///
  /// Parameters:
  /// - [label]: The text shown on the button. If empty, a confirmation dialog will be shown before proceeding.
  /// - [onPressed]: The callback function to execute when the button is pressed.
  /// - [isDisabled]: Whether the button should appear disabled.
  ///
  /// Behavior:
  /// - If the [label] is empty, the button shows a confirmation dialog before running [onPressed].
  /// - If [isDisabled] is true, the button becomes non-interactive and lowers its opacity.
  Widget confirmableActionButton({
    String? label,
    VoidCallback? onPressed,
    bool isDisabled = false,
    String? tooltip,
    ButtonStyle? style,
  }) {
    final labelText = label ?? 'Save Changes';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: label == null
                ? () async {
                    final isConfirmed = await _confirmUpdateDialog();

                    if (mounted && isConfirmed) {
                      onPressed!();
                    }
                  }
                : onPressed,
            style:
                style ??
                ButtonStyle(
                  padding: const WidgetStatePropertyAll(EdgeInsets.all(20)),
                  backgroundColor: WidgetStatePropertyAll(
                    mainPrimaryColor.toAlpha(isDisabled ? 0.4 : 1),
                  ),
                  elevation: isDisabled
                      ? const WidgetStatePropertyAll(0)
                      : null,
                ),
            child: Tooltip(
              message: tooltip ?? labelText,
              child: Text(
                labelText,
                style: const TextStyle(
                  color: kWhiteColor,
                  overflow: TextOverflow.ellipsis,
                ),
                semanticsLabel: label,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget elevatedIconBtn(
    dynamic icon, {
    dynamic label,
    VoidCallback? onPressed,
    Color? bgColor,
    Color? txtColor,
    String? tooltip,
    ButtonStyle? style,
    IconAlignment? iconAlignment,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      iconAlignment: iconAlignment,
      style:
          style ??
          ElevatedButton.styleFrom(backgroundColor: bgColor ?? kOffWhiteColor),

      icon: icon is IconData ? Icon(icon) : icon,
      label: Tooltip(
        message: tooltip ?? (label is String ? label : ''),
        child: label is String
            ? Text(
                label,
                style: TextStyle(color: txtColor),
                semanticsLabel: label,
                overflow: TextOverflow.ellipsis,
              )
            : label,
      ),
    );
  }

  // Text button
  Widget textButton(
    String label, {
    VoidCallback? onPressed,
    Color? txtColor,
    String? tooltip,
    ButtonStyle? style,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: style,
      child: Tooltip(
        message: tooltip ?? label,
        child: Text(
          label,
          style: TextStyle(color: txtColor, overflow: TextOverflow.ellipsis),
          semanticsLabel: label,
        ),
      ),
    );
  }

  /// [elevatedButton] A customizable elevated button widget.
  ///
  Widget elevatedButton(
    String label, {
    VoidCallback? onPressed,
    Color? bgColor,
    Color? txtColor,
    String? tooltip,
    EdgeInsetsGeometry? padding,
    ButtonStyle? style,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style:
          style ??
          ElevatedButton.styleFrom(
            backgroundColor: bgColor ?? kOffWhiteColor,
            padding: padding,
          ),
      child: Tooltip(
        message: tooltip ?? label,
        child: Text(
          label,
          style: TextStyle(color: txtColor, overflow: TextOverflow.ellipsis),
          semanticsLabel: label,
        ),
      ),
    );
  }

  Widget outlinedIconBtn(
    dynamic icon, {
    dynamic label,
    VoidCallback? onPressed,
    Color? bgColor,
    Color? txtColor,
    Color? borderColor,
    String? tooltip,
    ButtonStyle? style,
  }) {
    return elevatedIconBtn(
      icon,
      label: label,
      tooltip: tooltip,
      bgColor: bgColor,
      txtColor: txtColor,
      onPressed: onPressed,
      style:
          style ??
          ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor ?? kOffWhiteColor),
              borderRadius: _borderRadius,
            ),
          ),
    );
  }

  Widget outlinedButton(
    dynamic label, {
    VoidCallback? onPressed,
    Color? bgColor,
    Color? txtColor,
    Color? borderColor,
    String? tooltip,
    ButtonStyle? style,
  }) {
    return elevatedButton(
      label,
      tooltip: tooltip,
      bgColor: bgColor,
      txtColor: txtColor,
      onPressed: onPressed,
      style:
          style ??
          ElevatedButton.styleFrom(
            backgroundColor: bgColor ?? kOffWhiteColor,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor ?? kOffWhiteColor),
              borderRadius: _borderRadius,
            ),
          ),
    );
  }

  Widget iconButton(
    IconData icon, {
    double? iconSize,
    Color? bgColor,
    Color? iconColor,
    Color? borderColor,
    String? tooltip,
    bool isCard = false,
    required void Function()? onPressed,
  }) {
    final btn = _buildIconButton(
      onPressed,
      tooltip,
      bgColor,
      borderColor,
      icon,
      iconColor,
      iconSize,
    );
    return isCard ? Card(elevation: 2.0, child: btn) : btn;
  }

  IconButton _buildIconButton(
    void Function()? onPressed,
    String? tooltip,
    Color? bgColor,
    Color? borderColor,
    IconData icon,
    Color? iconColor,
    double? iconSize,
  ) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: ElevatedButton.styleFrom(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        backgroundColor: bgColor ?? kOffWhiteColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor ?? kOffWhiteColor),
          borderRadius: _borderRadius,
        ),
      ),
      icon: Icon(
        icon,
        color: iconColor ?? kWhiteColor,
        size: iconSize,
        semanticLabel: tooltip ?? 'Icon button',
      ),
    );
  }

  Widget toolbarButton({
    required String label,
    Color? bgColor,
    Color? shadowColor,
    dynamic icon,
    String? tooltip,
    Color? txtColor,
    Color? borderColor,
    VoidCallback? onPressed,
    bool showLabel = false,
  }) {
    final controller = WidgetStatesController();

    return Tooltip(
      message: tooltip ?? label,
      child: ElevatedButton.icon(
        statesController: controller,
        onPressed: onPressed,
        icon: icon is IconData
            ? Icon(icon, color: txtColor ?? kWhiteColor)
            : icon,
        label: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final isHoveredOrFocused =
                controller.value.contains(WidgetState.hovered) ||
                controller.value.contains(WidgetState.focused);

            final shouldShowLabel = showLabel || isHoveredOrFocused;

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: shouldShowLabel
                  ? Text(
                      label,
                      key: const ValueKey('label'),
                      style: TextStyle(color: txtColor ?? kWhiteColor),
                    )
                  : const SizedBox(key: ValueKey('empty'), width: 0),
            );
          },
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          alignment: Alignment.centerRight,
          shadowColor: shadowColor,
          shape: RoundedRectangleBorder(
            side: borderColor != null
                ? BorderSide(color: borderColor)
                : BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Future<bool> _confirmUpdateDialog() async => await confirmAction<bool>(
    const Text('Would you like to proceed?'),
    title: "Confirm Changes",
    onAcceptLabel: "Save",
    onRejectLabel: "Cancel",
  );
}
