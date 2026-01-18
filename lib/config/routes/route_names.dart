import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// We use name route
// To avoid delay in App load, by importing Screens/Pages with Routes
// we use the static Route String Name to access Named Routes

abstract class RouteNames {
  /// ──────────────────────── 🌟 Core Entry Points ────────────────────────
  /// Entry/Startup Point for Home / Landing-Page [initialScreen]
  static const initialScreen = '/';
  static const initialScreenName = 'initial_screen';
  static const homeDashboard = 'home';

  /// ─────────────────────────── 🔐 Workspace Authentication ───────────────────────────
  static const workspaceSignIn = 'workspace_sign_in';
  static const employeeSignIn = 'employee_sign_in';
  static const verifyWorkspaceEmail = 'verify_workspace_email';
  static const changeTemporaryPasscode = 'change_temporary_passcode';
  static const wForgotPassword = 'forgot_password';
  static const wUpdatePassword = 'update_password';
  static const wAddMissingSocialAuthInfo = 'add_missing_social_auth_info';
  // static const workspaceSignup = 'create_workspace_acc';

  /// ──────────────────────── 🏠 Home Modules / Tiles ────────────────────────
  static const salesDistributionApp = 'sales_distribution_app';
  static const inventoryApp = 'inventory_app';
  static const procurementApp = 'procurement_app';
  static const posApp = 'pos_app';
  static const systemAdminApp = 'setup_app';
  static const customersApp = 'customers_app';
  // static const warehouseApp = 'warehouse_app';

  /// ───────────────────────── 🔧 Trouble Shooting ─────────────────────────
  static const troubleShootingApp = 'trouble_shooting_app';
  static const diagnoseIssues = 'diagnose_issues';
  static const allTenantWorkspaces = 'all_tenants_workspaces';
  static const manageSubscriptions = 'manage_subscriptions';
  // static const listAppIssues = 'list_app_issues';
  // static const userDeviceSpecs = 'user_device_specs';

  /// ───────────────────────── 💬 Live Chat/Support between Agents with Clients/Subscribers/Tenants ─────────────────────────
  static const liveChatSupport = 'live_chat_support_app';
  static const tenantChat = 'tenant_chat_screen';

  /// ───────────────────────── 📄 User Guide/Manual ─────────────────────────
  static const userGuideApp = 'user_guide_app';
  static const howToConfigApp = 'how_to_config_app';
  static const howToRenewLicense = 'how_to_renew_license';

  /// ───────────────────────── 📦 Inventory Module ─────────────────────────
  static const invoice = 'invoice_screen';
  static const orders = 'all_orders_screen';
  // static const itemCategories = 'product_categories_screen';
  // static const itemSuppliers = 'product_suppliers_screen';
  static const salesOrders = 'sales_orders_screen';
  static const salesOrders2 = 'temp_sales_orders_screen';
  static const deliveries = 'deliveries_screen';
  static const shippingDelivery = 'shipping_delivery_screen';
  static const ordersTracking = 'orders_tracking';
  static const salesQuotation = 'sales_quotation_screen';
  static const imsPurchaseOrders = 'inventory_purchase_orders_screen';
  static const miscOrders = 'miscellaneous_orders_screen';
  static const items = 'products_screen';
  static const sales = 'sales_screen';
  static const inventReports = 'invent_reports_screen';

  // for procurement
  /// ───────────────────────── 📦 Procurement Module ─────────────────────────
  static const purchaseRequisition = 'purchase_requisition_screen';
  static const proRequestForQuote = 'pro_request_for_quote_screen';
  static const proPurchaseOrders = 'pro_purchase_orders_screen';
  static const proMyApprovals = 'pro_my_approvals_screen';
  static const supplierManagement = 'supplier_management_screen';
  static const supplierAccount = 'supplier_account_screen';
  static const procurementReports = 'pro_reports_screen';
  static const supplierEvaluation = 'supplier_evaluation_screen';
  static const contractManagement = 'contract_management_screen';

  /// ───────────────────────── 🧾 POS Module ─────────────────────────
  static const posPayments = 'pos_payments_screen';
  static const posReports = 'pos_reports_screen';
  static const posOrders = 'pos_orders_screen';
  static const posSales = 'pos_sales_screen';
  static const posReceipt = 'invoice_screen'; // Consider renaming for clarity

  /// ───────────────────────── 👥 CRM Module ─────────────────────────
  static const createCustomer = 'create_customer_screen';

  /// ─────────────────────── 🏢 Warehouse Module ───────────────────────
  static const wmsModule = 'warehouse_module_screen';
  static const warehouse = 'wms_storage_screen';
  static const warehouseLocation = 'wms_location_screen';
  static const warehouseBin = 'wms_bin_screen';
  static const inboundReceiving = 'wms_inbound_receiving_screen';
  static const internalMovements = 'wms_internal_movements_screen';
  static const outboundPickShipping = 'wms_outbound_pick_shipping_screen';

  /// ─────────────────────── 🏢 Stock Management Module ───────────────────────
  static const stockManagementModule = 'stock_management_screen';
  static const goodsReceipt = 'goods_receipt_screen';
  static const serviceReceipt = 'service_receipt_screen';
  static const goodsIssue = 'goods_issue_screen';
  static const stockTransfer = 'stock_transfer_screen';
  static const stockAdjustment = 'stock_adjustment_screen';
  static const reserveStocks = 'reserve_stocks_screen';
  static const returnsFromCustomers = 'return_goods_screen';

  /// ─────────────────────── ⚙️ Setup / Settings Module ───────────────────────
  static const companyInfo = 'company_info_screen';
  static const coreMasterData = 'master_data_screen';
  static const allEmployees = 'all_employees_screen';
  static const manageRoles = 'manage_roles_screen';
  static const backup = 'backup_screen';

  /// ─────────────────────────  📋 Master Sub-Screens ─────────────────────────
  static const itemMaster = 'item_master_screen';
  static const taxMaster = 'tax_master_screen';
  // workflow Approval Rules
  static const workflowMaster = 'workflow_master_screen';
  static const referenceMaster = 'reference_master_screen';
  static const priceListMaster = 'price_list_master_screen';
  static const currenciesMaster = 'currencies_master_screen';
  // static const variantsMaster = 'variants_master_screen';
  // static const uomMaster = 'uom_master_screen';

  /// ───────────────────────── 🔄 Switch/Change Store/Shop Locations ─────────────────────────
  static const switchStoresAccount = 'switch_store_locations_screen';

  /// ───────────────────────── 📡 CRM / Agent ─────────────────────────
  static const agent = 'agent_clientele_screen';

  /// ───────────────────────── 🛑 Errors / Fallback ─────────────────────────
  // static const notFoundScreen = 'content_not_found';
}

/// Extension on [BuildContext] to simplify access to GoRouter-related properties.
extension GoRouterContextExtensions on BuildContext {
  /// [routePath] Returns the matched location from the current [GoRouterState].
  ///
  /// Example: `/users/123/profile`
  String get routePath => GoRouter.of(this).state.matchedLocation;

  /// Alternative way to get the current path from the config's URI.
  ///
  /// [routeFromUri] Functionally similar to [routePath], but uses the structured [Uri] object.
  String get routeFromUri => routeConfig.uri.path;

  /// [delegate] Returns the [GoRouterDelegate] associated with the current context.
  ///
  /// This delegate manages the navigation stack and route configuration.
  GoRouterDelegate get delegate => GoRouter.of(this).routerDelegate;

  /// [currentRouteConfig] Returns the current route configuration as a [RouteMatchList].
  ///
  /// This provides access to the list of matched routes in the current configuration,
  /// which can be useful for custom navigation logic or breadcrumbs.
  RouteMatchList get routeConfig => delegate.currentConfiguration;
}

/*extension MyWork on String {
  String get isWork =>
      this == 'buyerAccess' ? RouteNames.workspaceSignIn : RouteNames.workspaceSignup;
}*/
