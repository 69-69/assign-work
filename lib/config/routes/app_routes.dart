import 'dart:async';

import 'package:assign_erp/config/routes/route_logger.dart';
import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/features/404_fallback/not_found_screen.dart';
import 'package:assign_erp/features/agent/presentation/agent_app.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/auth/presentation/screen/sign_in/index.dart';
import 'package:assign_erp/features/customer_crm/presentation/index.dart';
import 'package:assign_erp/features/home/home_app.dart';
import 'package:assign_erp/features/inventory_ims/presentation/index.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/stock_management/index.dart';
import 'package:assign_erp/features/live_support/presentation/index.dart';
import 'package:assign_erp/features/onboarding/initial_screen.dart';
import 'package:assign_erp/features/pos_system/presentation/index.dart';
import 'package:assign_erp/features/procurement/presentation/index.dart';
import 'package:assign_erp/features/sales_distribution/presentation/index.dart';
import 'package:assign_erp/features/system_admin/presentation/index.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/index.dart';
import 'package:assign_erp/features/user_guide/presentation/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef DynamicRoute = ({
  String name,
  String? path,
  Widget Function(BuildContext context, GoRouterState state) builder,
  List<GoRoute> subRoutes,
});

final DashboardGuard dashboardGuard = DashboardGuard();
// final EmailVerificationGuard emailVerificationGuard = EmailVerificationGuard();
// final WorkspaceRoleGuard canAccessAgentPanel = WorkspaceRoleGuard();

// Helper methods for authentication and verification checks
/*Future<bool> _checkAuthentication(context, GoRouterState state) async {
  return await dashboardGuard.redirect(context);
}
Future<bool> _checkEmailVerification(context, GoRouterState state) async {
  return await emailVerificationGuard.redirect(context, state);
}*/

CustomTransitionPage<dynamic> _animateTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
        child: child,
      );
    },
  );
}

/* USAGE:
final dynamicRoutes = <DynamicRoute>[
  (
    name: RouteNames.createCustomer,
    path: '${RouteNames.createCustomer}/:openTab',
    builder: (context, state) {
      final tab = state.pathParameters['openTab'] ?? '';
      return CustomerScreen(openTab: tab);
    },
    subRoutes: const [], // You can add nested routes here
  ),
];

final customerRoute = GoRoute(
  name: RouteNames.customersApp,
  path: RouteNames.customersApp,
  pageBuilder: (context, state) =>
      _animateTransition(state, const CustomerApp()),
  routes: _mapDynamicRoutes(dynamicRoutes),
);

List<GoRoute> _mapDynamicRoutes(List<DynamicRoute> routes) => routes
    .map(
      (r) => GoRoute(
        name: r.name,
        path: r.path ?? r.name,
        builder: r.builder,
        routes: r.subRoutes,
      ),
    )
    .toList();
*/

List<GoRoute> _mapStaticRoutes(List<({String name, Widget screen})> routes) =>
    routes
        .map(
          (r) =>
              GoRoute(name: r.name, path: r.name, builder: (_, __) => r.screen),
        )
        .toList();

GoRoute _configBaseRoute({
  required String name,
  required String path,
  required Widget child,
  List<RouteBase> routes = const [],
  FutureOr<String?> Function(BuildContext, GoRouterState)? redirect,
}) {
  return GoRoute(
    name: name,
    path: path,
    pageBuilder: (context, state) => _animateTransition(state, child),
    routes: routes,
    redirect: redirect,
  );
}

/// CRM App
GoRoute _customerRoute() {
  return GoRoute(
    name: RouteNames.customersApp,
    path: RouteNames.customersApp,
    pageBuilder: (context, state) =>
        _animateTransition(state, const CustomerApp()),
    routes: [
      GoRoute(
        name: RouteNames.createCustomer,
        path: '${RouteNames.createCustomer}/:openTab',
        builder: (context, state) =>
            CustomerScreen(openTab: state.pathParameters['openTab'] ?? ''),
      ),
    ],
  );
}

/// POS App
GoRoute _posRoute() {
  // Sub routes for POS App
  final List<({String name, Widget screen})> posSubScreens = [
    (name: RouteNames.posOrders, screen: const PosOrdersScreen()),
    (name: RouteNames.posSales, screen: const PosSalesScreen()),
    (name: RouteNames.posReports, screen: const ReportsAnalyticsScreen()),
    (name: RouteNames.posPayments, screen: const PosSalesScreen()),
  ];

  return GoRoute(
    name: RouteNames.posApp,
    path: RouteNames.posApp,
    pageBuilder: (_, state) => _animateTransition(state, const POSApp()),
    routes: _mapStaticRoutes(posSubScreens),
  );
}

/// Setup App
GoRoute _setupRoute() {
  // Sub routes for Setup App
  final List<String> setupSubRoutes = [
    RouteNames.companyInfo,
    RouteNames.allEmployees,
    RouteNames.manageRoles,
    RouteNames.workflowApprovalRules,
    RouteNames.manageTaxes,
    RouteNames.productConfig,
    RouteNames.backup,
  ];

  return GoRoute(
    name: RouteNames.systemAdminApp,
    path: RouteNames.systemAdminApp,
    pageBuilder: (context, state) =>
        _animateTransition(state, const SetupApp()),
    routes: setupSubRoutes
        .map(
          (routeName) => GoRoute(
            name: routeName,
            path: '$routeName/:openTab',
            builder: (context, state) =>
                SetupScreen(openTab: state.pathParameters['openTab'] ?? ''),
          ),
        )
        .toList(),
  );
}

/// Stores Switcher App
GoRoute _storesSwitcherRoute() {
  return GoRoute(
    name: RouteNames.switchStoresAccount,
    path: RouteNames.switchStoresAccount,
    pageBuilder: (context, state) =>
        _animateTransition(state, const SwitchStoreLocationsScreen()),
  );
}

/// Stock Management Module
GoRoute _stockManagementRoute() {
  // Sub routes for Stock Management
  final List<({String name, Widget screen})> stockManageSubRoutes = [
    (name: RouteNames.goodsReceipt, screen: const GoodsReceiptScreen()),
    (name: RouteNames.serviceReceipt, screen: const GoodsReceiptScreen()),
    (name: RouteNames.goodsIssue, screen: const GoodsIssueScreen()),
    (name: RouteNames.stockTransfer, screen: const StockTransferScreen()),
    (name: RouteNames.stockAdjustment, screen: const StockAdjustmentScreen()),
    (name: RouteNames.reserveStocks, screen: const StockAdjustmentScreen()),
    (
      name: RouteNames.returnsFromCustomers,
      screen: const StockAdjustmentScreen(),
    ),
  ];

  return GoRoute(
    name: RouteNames.stockManagementModule,
    path: RouteNames.stockManagementModule,
    pageBuilder: (_, state) =>
        _animateTransition(state, const StockManagementScreen()),
    routes: _mapStaticRoutes(stockManageSubRoutes),
  );
}

/// Warehouse Management Module
GoRoute _wmsRoute() {
  // Sub routes for Warehouse Management
  final List<({String name, Widget screen})> wmsSubRoutes = [
    (name: RouteNames.warehouse, screen: const WarehouseScreen()),
    (name: RouteNames.warehouseLocation, screen: const WarehouseScreen()),
    (name: RouteNames.warehouseBin, screen: const WarehouseScreen()),
  ];

  return GoRoute(
    name: RouteNames.wmsModule,
    path: RouteNames.wmsModule,
    pageBuilder: (_, state) => _animateTransition(state, const WMSScreen()),
    routes: _mapStaticRoutes(wmsSubRoutes),
  );
}

/// Orders Module
GoRoute _ordersRoute() {
  // Sub routes for Orders
  final List<({String name, Widget screen})> orderSubRoutes = [
    (name: RouteNames.salesOrders, screen: const OrderScreen()),
    (name: RouteNames.imsPurchaseOrders, screen: const PurchaseOrderScreen()),
    (name: RouteNames.miscOrders, screen: const MiscOrderScreen()),
  ];

  return GoRoute(
    name: RouteNames.orders,
    path: RouteNames.orders,
    pageBuilder: (_, state) => _animateTransition(state, const OrdersScreen()),
    routes: _mapStaticRoutes(orderSubRoutes),
  );
}

/// Inventory App
GoRoute _inventoryRoute() {
  // Sub routes for Inventory
  final List<({String name, Widget screen})> inventoryRoutes = [
    (name: RouteNames.itemMasterModule, screen: const ItemMasterScreen()),
    (name: RouteNames.invoice, screen: const InvoiceScreen()),
    (name: RouteNames.deliveries, screen: const DeliveryScreen()),
    (name: RouteNames.items, screen: const ProductScreen()),
    (name: RouteNames.sales, screen: const SaleScreen()),
    (name: RouteNames.inventReports, screen: const ReportsAnalyticsScreen()),
  ];

  return GoRoute(
    name: RouteNames.inventoryApp,
    path: RouteNames.inventoryApp,
    pageBuilder: (context, state) =>
        _animateTransition(state, const InventoryApp()),
    routes: [
      // Inventory subroutes
      ..._mapStaticRoutes(inventoryRoutes),

      // Stock Management with subroutes
      _stockManagementRoute(),

      // Warehouse Management with subroutes
      _wmsRoute(),

      // Orders with subroutes
      _ordersRoute(),
    ],
  );
}

/// Procurement App
GoRoute _procurementRoute() {
  final List<({String name, Widget screen})> procurementRoutes = [
    (
      name: RouteNames.purchaseRequisition,
      screen: const ProPurchaseRequisitionScreen(),
    ),
    (
      name: RouteNames.proRequestForQuote,
      screen: const ProRequestForQuoteScreen(),
    ),
    (
      name: RouteNames.proPurchaseOrders,
      screen: const ProPurchaseOrderScreen(),
    ),
    (
      name: RouteNames.proMyApprovals,
      screen: const ProWorkflowApprovalsScreen(),
    ),
    /*(
      name: RouteNames.imsRequestForQuote,
      screen: const RequestForQuotationScreen(),
    ),*/
  ];

  final List<({String name, Widget screen})> supplierSubRoutes = [
    (name: RouteNames.supplierAccount, screen: const SupplierAccountScreen()),
    (
      name: RouteNames.supplierEvaluation,
      screen: const SupplierEvaluationScreen(),
    ),
    (
      name: RouteNames.contractManagement,
      screen: const ContractManagementScreen(),
    ),
  ];

  return GoRoute(
    name: RouteNames.procurementApp,
    path: RouteNames.procurementApp,
    pageBuilder: (context, state) =>
        _animateTransition(state, const ProcurementApp()),
    routes: [
      // procurement routes
      ..._mapStaticRoutes(procurementRoutes),

      // Supplier management's subroutes
      GoRoute(
        name: RouteNames.supplierManagement,
        path: RouteNames.supplierManagement,
        builder: (context, state) => const ProSupplierManagementScreen(),
        routes: _mapStaticRoutes(supplierSubRoutes),
      ),
    ],
  );
}

/// Sales and Distribution App
GoRoute _salesDistributionRoute() {
  // Sub routes for Sales and Distribution
  final List<({String name, Widget screen})> salesDistributionRoutes = [
    (name: RouteNames.salesOrders2, screen: const SalesOrderScreen()),
    (name: RouteNames.shippingDelivery, screen: const OrderDeliveryScreen()),
    (name: RouteNames.salesQuotation, screen: const SalesQuotationScreen()),
  ];

  return GoRoute(
    name: RouteNames.salesDistributionApp,
    path: RouteNames.salesDistributionApp,
    pageBuilder: (context, state) =>
        _animateTransition(state, const SalesDistributionApp()),
    routes: [
      // Sales Distribution subroutes
      ..._mapStaticRoutes(salesDistributionRoutes),
    ],
  );
}

/// Agent App
GoRoute _agentRoute() {
  return GoRoute(
    name: RouteNames.agent,
    path: RouteNames.agent,
    pageBuilder: (context, state) =>
        _animateTransition(state, const AgentApp()),
    routes: [
      GoRoute(
        name: RouteNames.tenantChat,
        path: '${RouteNames.tenantChat}/:clientWorkspaceId',
        builder: (context, state) => AgentChatDashboard(
          clientWorkspaceId: state.pathParameters['clientWorkspaceId'] ?? '',
        ),
      ),
    ],

    /*redirect: (context, state) {
          // Check if the user can access the agent panel
          if (!WorkspaceRoleGuard.canAccessAgentPanel(context)) {
            return '/${RouteNames.employeeSignIn}';
          }
          // Allow access if the user meets the required role
          return null;
        },*/
  );
}

/// User User Guide App
GoRoute _userGuideRoute() {
  // Sub routes for User Guide
  final List<({String name, Widget screen})> userGuideRoutes = [
    (name: RouteNames.howToConfigApp, screen: const HowToConfigAppScreen()),
    (
      name: RouteNames.howToRenewLicense,
      screen: const HowToRenewLicenseScreen(),
    ),
  ];

  return GoRoute(
    name: RouteNames.userGuideApp,
    path: RouteNames.userGuideApp,
    pageBuilder: (context, state) =>
        _animateTransition(state, const UserGuideApp()),
    routes: _mapStaticRoutes(userGuideRoutes),
  );
}

/// Live Support/Chat App
GoRoute _liveSupportRoute() {
  return GoRoute(
    name: RouteNames.liveChatSupport,
    path: RouteNames.liveChatSupport,
    pageBuilder: (context, state) =>
        _animateTransition(state, const LiveSupportApp()),
  );
}

/// Developer Only: Trouble Shooting App
GoRoute _troubleShootRoute() {
  // Sub routes for Trouble Shooting
  final List<({String name, Widget screen})> troubleShootRoutes = [
    (name: RouteNames.diagnoseIssues, screen: const DiagnosticScreen()),
    (
      name: RouteNames.allTenantWorkspaces,
      screen: const TenantWorkspacesScreen(),
    ),
    (
      name: RouteNames.manageSubscriptions,
      screen: const ManageSubscriptionScreen(),
    ),
  ];

  return GoRoute(
    name: RouteNames.troubleShootingApp,
    path: RouteNames.troubleShootingApp,
    pageBuilder: (context, state) =>
        _animateTransition(state, const TroubleShootingApp()),
    routes: _mapStaticRoutes(troubleShootRoutes),
  );
}

// Define your routes
List<RouteBase> appRouterConfig = <RouteBase>[
  _configBaseRoute(
    name: RouteNames.initialScreenName,
    path: RouteNames.initialScreen,
    child: const InitialScreen(),
    routes: [
      /// Protected Workspace Route
      _configBaseRoute(
        name: RouteNames.homeDashboard,
        path: RouteNames.homeDashboard,
        child: const HomeApp(),
        routes: [
          _inventoryRoute(),
          _procurementRoute(),
          _setupRoute(),
          _customerRoute(),
          _posRoute(),
          _salesDistributionRoute(),
          _userGuideRoute(),
          _liveSupportRoute(),
          _agentRoute(),
          _troubleShootRoute(),
          _storesSwitcherRoute(),
        ],
      ),

      /// Auth Routes
      _configBaseRoute(
        name: RouteNames.workspaceSignIn,
        path: RouteNames.workspaceSignIn,
        child: const WorkspaceSignInScreen(),
      ),
      _configBaseRoute(
        name: RouteNames.employeeSignIn,
        path: RouteNames.employeeSignIn,
        child: const EmployeeSignInScreen(),
        redirect: (context, state) async {
          if (state.name == RouteNames.employeeSignIn) {
            final shouldRedirect = await dashboardGuard.redirect(context);
            return shouldRedirect ? '/${RouteNames.homeDashboard}' : null;
          }
          return null;
        },
      ),
      _configBaseRoute(
        name: RouteNames.changeTemporaryPasscode,
        path: RouteNames.changeTemporaryPasscode,
        child: const ChangeEmployeePasscodeScreen(),
      ),
      _configBaseRoute(
        name: RouteNames.verifyWorkspaceEmail,
        path: RouteNames.verifyWorkspaceEmail,
        child: const EmployeeSignInScreen(),
      ),
    ],
  ),
];

GoRouter appRouter(RouteLogger routeLogger) {
  return GoRouter(
    initialLocation: RouteNames.initialScreen,
    routes: appRouterConfig,
    errorBuilder: (context, state) => const NotFoundPage(),
    // [observers] To track & monitor routes visited
    observers: [routeLogger],
    // refreshListenable: GoRouterRefreshStream(authBloc.stream),
  );
}
