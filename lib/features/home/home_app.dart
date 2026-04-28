import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/dashboard_tile_card.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_status_enum.dart';
import 'package:assign_erp/features/home/widget/license_tiles.dart';
import 'package:assign_erp/features/refresh_entire_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeApp extends StatelessWidget {
  const HomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return CustomScaffold(
          isGradientBg: true,
          backButton: const SizedBox.shrink(),
          body: _buildBody(context, state),
          actions: [
            context.reloadAppIconButton(
              onPressed: () => RefreshEntireApp.restartApp(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AuthState authState) {
    if (authState.authStatus == AuthStatus.authenticated) {
      return _buildDashboard(context, authState);
    }
    return context.loader;
  }

  Widget _buildDashboard(BuildContext context, AuthState authState) {
    return DashboardTileCard(tiles: context.licenseTiles);
  }

  /*final tiles = [
      Restriction by subscription license type
       ...?licenseTiles[workspace?.license]?.tiles,
      * Role Based Access Control
      ...?mainTiles[employee?.role]?.tiles,
      ...context.licenseTiles,
      ...homeTiles,
    ];

  _handleSignOut(BuildContext context) {
    context.read<AuthBloc>().add(AuthSignOutRequested());
  }*/
}

/*class FlowMenu extends StatefulWidget {
  const FlowMenu({super.key});

  @override
  State<FlowMenu> createState() => _FlowMenuState();
}

class _FlowMenuState extends State<FlowMenu> with SingleTickerProviderStateMixin {
  late AnimationController menuAnimation;
  IconData lastTapped = Icons.notifications;
  final List<IconData> menuItems = <IconData>[
    Icons.logout,
    Icons.new_releases,
    Icons.notifications,
    Icons.settings,
    Icons.menu,
  ];

  void _updateMenu(IconData icon) {
    if (icon != Icons.menu) {
      setState(() => lastTapped = icon);
    }
  }

  @override
  void initState() {
    super.initState();
    menuAnimation = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  Widget flowMenuItem(IconData icon) {
    final double buttonDiameter = context.screenWidth / menuItems.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RawMaterialButton(
        fillColor: lastTapped == icon ? kWarningColor : kPrimaryLightColor,
        splashColor: kPrimaryColor,
        shape: const CircleBorder(),
        constraints: BoxConstraints.tight(Size(buttonDiameter, buttonDiameter)),
        onPressed: () {
          _updateMenu(icon);
          if (icon == Icons.menu) {
            menuAnimation.status == AnimationStatus.completed
                ? menuAnimation.reverse()
                : menuAnimation.forward();
          }
        },
        child: Icon(
          icon,
          color: Colors.white,
          size: 45.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Flow(
      delegate: FlowMenuDelegate(menuAnimation: menuAnimation),
      children:
          menuItems.map<Widget>((IconData icon) => flowMenuItem(icon)).toList(),
    );
  }
}

class FlowMenuDelegate extends FlowDelegate {
  FlowMenuDelegate({required this.menuAnimation})
      : super(repaint: menuAnimation);

  final Animation<double> menuAnimation;

  @override
  bool shouldRepaint(FlowMenuDelegate oldDelegate) {
    return menuAnimation != oldDelegate.menuAnimation;
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    double dx = 0.0;
    for (int i = 0; i < context.childCount; ++i) {
      dx = context.getChildSize(i)!.width * i;
      context.paintChild(
        i,
        transform: Matrix4.translationValues(
          dx * menuAnimation.value,
          0,
          0,
        ),
      );
    }
  }
}*/

/*extension _ManagementChoice on BuildContext {
  /// Alert dialog/modal
  Future<dynamic> _showManagementChoice() => openDialog(
        title: 'activity type',
        child: TileCard(isAdaptive: false, tiles: managementChoiceTiles),
        actions: [const _Button()],
      );
}

class _Button extends StatelessWidget {
  const _Button();

  @override
  Widget build(BuildContext context) {
    return _buildButton(context);
  }

  Row _buildButton(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: () => context.goNamed(RouteNames.appTraining),
          icon: const Icon(Icons.how_to_reg),
          label: Text(
            'guide to'.toUppercaseAllLetter,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'cancel'.toUppercaseAllLetter,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
        ),
      ],
    );
  }}*/
