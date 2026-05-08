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
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/variants_master_screen.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/index.dart';
import 'package:assign_erp/features/app_training/presentation/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/*typedef DynamicRoute = ({
  String name,
  String? path,
  Widget Function(BuildContext context, GoRouterState state) builder,
  List<GoRoute> subRoutes,
});

 USAGE:
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

// final EmailVerificationGuard emailVerificationGuard = EmailVerificationGuard();
// final WorkspaceRoleGuard canAccessAgentPanel = WorkspaceRoleGuard();

// Helper methods for authentication and verification checks
Future<bool> _checkAuthentication(context, GoRouterState state) async {
  return await dashboardGuard.redirect(context);
}
Future<bool> _checkEmailVerification(context, GoRouterState state) async {
  return await emailVerificationGuard.redirect(context, state);
}*/

typedef StaticRouteConfig = ({
  String name,
  Widget Function({String? openTab}) screen,
  bool openTab,
});

final DashboardGuard dashboardGuard = DashboardGuard();

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

List<GoRoute> _mapStaticRoutes(List<StaticRouteConfig> routes) {
  return routes.map((r) {
    final path = r.openTab ? '${r.name}/:openTab' : r.name;

    return GoRoute(
      name: r.name,
      path: path,
      builder: (_, state) {
        final tab = r.openTab ? state.pathParameters['openTab'] : null;
        return r.screen(openTab: tab);
      },
    );
  }).toList();
}

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
  final List<StaticRouteConfig> posSubScreens = [
    (
      name: RouteNames.posOrders,
      openTab: false,
      screen: ({openTab}) => const PosOrdersScreen(),
    ),
    (
      name: RouteNames.posSales,
      openTab: false,
      screen: ({openTab}) => const PosSalesScreen(),
    ),
    (
      name: RouteNames.posReports,
      openTab: false,
      screen: ({openTab}) => const ReportsAnalyticsScreen(),
    ),
    (
      name: RouteNames.posPayments,
      openTab: false,
      screen: ({openTab}) => const PosSalesScreen(),
    ),
  ];

  return GoRoute(
    name: RouteNames.posApp,
    path: RouteNames.posApp,
    pageBuilder: (_, state) => _animateTransition(state, const POSApp()),
    routes: _mapStaticRoutes(posSubScreens),
  );
}

/// Master Data Module
GoRoute _masterDataRoute() {
  // Sub routes for Master Data
  final List<StaticRouteConfig> wmsSubRoutes = [
    (
      name: RouteNames.itemMaster,
      openTab: false,
      screen: ({openTab}) => const ItemMasterScreen(),
    ),
    (
      name: RouteNames.taxMaster,
      openTab: false,
      screen: ({openTab}) => const ManageTaxScreen(),
    ),
    (
      name: RouteNames.warehouseMaster,
      openTab: false,
      screen: ({openTab}) => const WarehouseScreen(),
    ),
    (
      name: RouteNames.warehouseLocationMaster,
      openTab: false,
      screen: ({openTab}) => const WHLocationScreen(),
    ),
    (
      name: RouteNames.warehouseBinMaster,
      openTab: false,
      screen: ({openTab}) => const WHBinScreen(),
    ),
    (
      name: RouteNames.priceListMaster,
      openTab: false,
      screen: ({openTab}) => const PriceListMasterScreen(),
    ),
    (
      name: RouteNames.currencyMaster,
      openTab: false,
      screen: ({openTab}) => const CurrencyMasterScreen(),
    ),
    (
      name: RouteNames.referenceMaster,
      openTab: false,
      screen: ({openTab}) => const ReferenceMasterScreen(),
    ),
    (
      name: RouteNames.variantsMaster,
      openTab: false,
      screen: ({openTab}) => const VariantsMasterScreen(),
    ),
    (
      name: RouteNames.workflowMaster,
      openTab: false,
      screen: ({openTab}) => const ApprovalRulesScreen(),
    ),
  ];

  return GoRoute(
    name: RouteNames.coreMasterData,
    path: RouteNames.coreMasterData,
    pageBuilder: (_, state) =>
        _animateTransition(state, const MasterDataScreen()),
    routes: _mapStaticRoutes(wmsSubRoutes),
  );
}

/// Setup App
GoRoute _setupRoute() {
  // Sub routes for Setup App
  final List<StaticRouteConfig> setupSubRoutes = [
    (
      name: RouteNames.companyInfo,
      openTab: true,
      screen: ({openTab}) => SetupScreen(openTab: openTab ?? '0'),
    ),
    (
      name: RouteNames.manageRoles,
      openTab: true,
      screen: ({openTab}) => SetupScreen(openTab: openTab ?? '0'),
    ),
    (
      name: RouteNames.allEmployees,
      openTab: true,
      screen: ({openTab}) => SetupScreen(openTab: openTab ?? '0'),
    ),
    (
      name: RouteNames.backup,
      openTab: true,
      screen: ({openTab}) => SetupScreen(openTab: openTab ?? '0'),
    ),
  ];

  return GoRoute(
    name: RouteNames.systemAdminApp,
    path: RouteNames.systemAdminApp,
    pageBuilder: (context, state) =>
        _animateTransition(state, const SetupApp()),
    routes: [
      // Setup subroutes
      ..._mapStaticRoutes(setupSubRoutes),
      _masterDataRoute(),
      /*...setupSubRoutes.map(
        (routeName) => GoRoute(
          name: routeName,
          path: '$routeName/:openTab',
          builder: (context, state) =>
              SetupScreen(openTab: state.pathParameters['openTab'] ?? ''),
        ),
      ),*/
    ],
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
  final List<StaticRouteConfig> stockManageSubRoutes = [
    (
      name: RouteNames.goodsReceipt,
      openTab: false,
      screen: ({openTab}) => const GoodsReceiptScreen(),
    ),
    (
      name: RouteNames.serviceReceipt,
      openTab: false,
      screen: ({openTab}) => const GoodsReceiptScreen(),
    ),
    (
      name: RouteNames.goodsIssue,
      openTab: false,
      screen: ({openTab}) => const GoodsIssueScreen(),
    ),
    (
      name: RouteNames.stockTransfer,
      openTab: false,
      screen: ({openTab}) => const StockTransferScreen(),
    ),
    (
      name: RouteNames.stockAdjustment,
      openTab: false,
      screen: ({openTab}) => const StockAdjustmentScreen(),
    ),
    (
      name: RouteNames.reserveStocks,
      openTab: false,
      screen: ({openTab}) => const StockAdjustmentScreen(),
    ),
    (
      name: RouteNames.returnsFromCustomers,
      openTab: false,
      screen: ({openTab}) => const StockAdjustmentScreen(),
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
  final List<StaticRouteConfig> wmsSubRoutes = [
    (
      name: RouteNames.inboundReceiving,
      openTab: false,
      screen: ({openTab}) => const InboundReceivingScreen(),
    ),
    (
      name: RouteNames.internalMovements,
      openTab: false,
      screen: ({openTab}) => const InternalMovementScreen(),
    ),
    (
      name: RouteNames.outboundPickShipping,
      openTab: false,
      screen: ({openTab}) => const PickingShipmentScreen(),
    ),
  ];

  return GoRoute(
    name: RouteNames.wmsModule,
    path: RouteNames.wmsModule,
    pageBuilder: (_, state) =>
        _animateTransition(state, const WarehouseManagementScreen()),
    routes: _mapStaticRoutes(wmsSubRoutes),
  );
}

/// Orders Module
GoRoute _ordersRoute() {
  // Sub routes for Orders
  final List<StaticRouteConfig> orderSubRoutes = [
    (
      name: RouteNames.salesOrders,
      openTab: false,
      screen: ({openTab}) => const OrderScreen(),
    ),
    (
      name: RouteNames.imsPurchaseOrders,
      openTab: false,
      screen: ({openTab}) => const PurchaseOrderScreen(),
    ),
    (
      name: RouteNames.miscOrders,
      openTab: false,
      screen: ({openTab}) => const MiscOrderScreen(),
    ),
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
  final List<StaticRouteConfig> inventoryRoutes = [
    (
      name: RouteNames.invoice,
      openTab: false,
      screen: ({openTab}) => const InvoiceScreen(),
    ),
    (
      name: RouteNames.deliveries,
      openTab: false,
      screen: ({openTab}) => const DeliveryScreen(),
    ),
    (
      name: RouteNames.items,
      openTab: false,
      screen: ({openTab}) => const ProductScreen(),
    ),
    (
      name: RouteNames.sales,
      openTab: false,
      screen: ({openTab}) => const SaleScreen(),
    ),
    (
      name: RouteNames.inventReports,
      openTab: false,
      screen: ({openTab}) => const ReportsAnalyticsScreen(),
    ),
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
  final List<StaticRouteConfig> procurementRoutes = [
    (
      name: RouteNames.purchaseRequisition,
      openTab: false,
      screen: ({openTab}) => const ProPurchaseRequisitionScreen(),
    ),
    (
      name: RouteNames.proRequestForQuote,
      openTab: false,
      screen: ({openTab}) => const ProRequestForQuoteScreen(),
    ),
    (
      name: RouteNames.proPurchaseOrders,
      openTab: false,
      screen: ({openTab}) => const ProPurchaseOrderScreen(),
    ),
    (
      name: RouteNames.proMyApprovals,
      openTab: false,
      screen: ({openTab}) => const ProWorkflowApprovalsScreen(),
    ),
    /*(
      name: RouteNames.imsRequestForQuote,
      openTab: false,
    screen: ({openTab}) => const RequestForQuotationScreen(),
    ),*/
  ];

  final List<StaticRouteConfig> supplierSubRoutes = [
    (
      name: RouteNames.supplierAccount,
      openTab: false,
      screen: ({openTab}) => const SupplierAccountScreen(),
    ),
    (
      name: RouteNames.supplierEvaluation,
      openTab: false,
      screen: ({openTab}) => const SupplierEvaluationScreen(),
    ),
    (
      name: RouteNames.contractManagement,
      openTab: false,
      screen: ({openTab}) => const ContractManagementScreen(),
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
  final List<StaticRouteConfig> salesDistributionRoutes = [
    (
      name: RouteNames.salesOrders2,
      openTab: false,
      screen: ({openTab}) => const SalesOrderScreen(),
    ),
    (
      name: RouteNames.shippingDelivery,
      openTab: false,
      screen: ({openTab}) => const OrderDeliveryScreen(),
    ),
    (
      name: RouteNames.salesQuotation,
      openTab: false,
      screen: ({openTab}) => const SalesQuotationScreen(),
    ),
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

/// User App-Training App
GoRoute _appTrainingRoute() {
  // Sub routes for App-Training
  final List<StaticRouteConfig> appTrainingRoutes = [
    (
      name: RouteNames.howToConfigApp,
      openTab: false,
      screen: ({openTab}) => const HowToConfigAppScreen(),
    ),
    (
      name: RouteNames.howToRenewLicense,
      openTab: false,
      screen: ({openTab}) => const HowToRenewLicenseScreen(),
    ),
  ];

  return GoRoute(
    name: RouteNames.appTraining,
    path: RouteNames.appTraining,
    pageBuilder: (context, state) =>
        _animateTransition(state, const AppTraining()),
    routes: _mapStaticRoutes(appTrainingRoutes),
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
  final List<StaticRouteConfig> troubleShootRoutes = [
    (
      name: RouteNames.diagnoseIssues,
      openTab: false,
      screen: ({openTab}) => const DiagnosticScreen(),
    ),
    (
      name: RouteNames.allTenantWorkspaces,
      openTab: false,
      screen: ({openTab}) => const TenantWorkspacesScreen(),
    ),
    (
      name: RouteNames.manageSubscriptions,
      openTab: false,
      screen: ({openTab}) => const ManageSubscriptionScreen(),
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
          _appTrainingRoute(),
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
