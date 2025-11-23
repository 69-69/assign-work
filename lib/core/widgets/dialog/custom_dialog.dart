import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:flutter/material.dart';

extension CustomDialogExt on Widget {
  Future<void> openCustomDialog(
    BuildContext context, {
    Color? bgColor,
    bool? isDismissible,
    double maxHeightRatio = 0.94,
    bool? isScrollControlled,
    BoxConstraints? constraints = const BoxConstraints(),
  }) => showModalBottomSheet(
    context: context,
    isDismissible: isDismissible ?? true,
    isScrollControlled: isScrollControlled ?? false,
    backgroundColor: bgColor ?? kTransparentColor,
    scrollControlDisabledMaxHeightRatio: maxHeightRatio,
    constraints: constraints?.copyWith(maxWidth: context.screenWidth),
    builder: (_) => this,
  );
}

class CustomDialog extends StatelessWidget {
  const CustomDialog({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.bgColor,
    this.icon,
    this.isCard = false,
  });

  final Widget title;
  final Widget body;
  final List<Widget> actions;
  final Color? bgColor;
  final Widget? icon;
  final bool isCard;

  @override
  Widget build(BuildContext context) {
    return _buildWillPopScope(
      context,
      child: isCard
          ? CustomCard(title: title, body: body, actions: actions)
          : _buildBody(context),
    );
  }

  PopScope<Object> _buildWillPopScope(
    BuildContext context, {
    required Widget child,
  }) {
    return PopScope(
      canPop: false, // disables default back navigation
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          bool shouldPop = await context.confirmAction(
            Text('Are you sure you want to exit?'),
            title: 'Confirm Exit',
          );
          if (context.mounted && shouldPop) {
            // or pass result: Navigator.of(context).pop(myResult);
            Navigator.of(context).pop();
          }
        }
      },
      child: child,
    );
  }

  AlertDialog _buildBody(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      icon: Align(
        alignment: Alignment.topRight,
        child:
            icon ??
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: context.outlineColor.toAlpha(0.4),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: kTextColor),
            ),
      ),
      iconPadding: const EdgeInsets.only(right: 5, top: 5),
      // backgroundColor: bgColor ?? context.bgAuthColor,
      title: title,
      content: body,
      actions: actions,
    );
  }
}

class CustomCard extends StatelessWidget {
  final Widget? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? icon;
  final Color? bgColor;

  const CustomCard({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.icon,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // color: bgColor ?? context.bgAuthColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(15, 10, 15, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (title != null)
                  Expanded(
                    child: DefaultTextStyle(
                      style: context.textTheme.titleMedium!,
                      textAlign: TextAlign.center,
                      child: title!,
                    ),
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child:
                      icon ??
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: context.outlineColor.toAlpha(0.3),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: kTextColor),
                      ),
                ),
              ],
            ),
            Expanded(child: body),
            if (actions != null) Wrap(children: actions!),
          ],
        ),
      ),
    );
  }
}

/*class InlineAlertBox extends StatelessWidget {
  final Widget? title;
  final Widget? body;
  final List<Widget>? actions;
  final Widget? icon;
  final Color? bgColor;

  const InlineAlertBox({
    Key? key,
    this.title,
    this.body,
    this.actions,
    this.icon,
    this.bgColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bgColor ?? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // max 80% of screen
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: icon ??
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.close),
                    ),
              ),
              if (title != null) ...[
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleMedium!,
                  child: title!,
                ),
                const SizedBox(height: 8),
              ],
              if (body != null) ...[
                body!,
                const SizedBox(height: 16),
              ],
              if (actions != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
