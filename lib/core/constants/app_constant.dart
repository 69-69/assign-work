/*is on line 18
<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>*/

/// 'autoID' is used to generate a new Customer-ID,
/// if customer doesn't exist, while placing Orders [autoID]
const autoID = 'auto-id';

/// Assign: is prefix error message to distinguish Generic (Firestore) error [errorPrefix]
const errorPrefix = 'Assign';
// rhoda= 172298 - steve = 60438
/// APP NAME
const _nChar = '⏺';
// WORKSPACE, HEALTHSPACE, EDUSPACE
const appName = 'ASSIGN.WORK';
const appSubName =
    'A.I $_nChar P.O.S $_nChar Inventory $_nChar C.R.M $_nChar Procurement $_nChar Cloud $_nChar Warehouse $_nChar Reports $_nChar Multi-Location';
const ghanaCedis = '¢';

/// APP LOGO
const assetPath = 'assets/images';
const assetPrint = 'assets/print';
const appLogo = '$assetPath/logo.png';
const appLogo2 = '$assetPath/logo_2.png';
const appBg = '$assetPath/app_bg.png';
const appLogoWithBG = '$assetPath/logo_bg.png';
const printFooterBg = '$assetPrint/invoice.svg';
const densePrintLayout = '$assetPrint/dense_print_layout.png';
const loosePrintLayout = '$assetPrint/loose_print_layout.png';

/// OnBoarding bg-Images
const onBoardingBg1 = '$assetPath/erp_software.png';
const onBoardingBg2 = '$assetPath/all-devices-support.png';
const onBoardingBg3 = '$assetPath/inventory_ims.png';
const onBoardingBg4 = '$assetPath/p_o_s_system.png';
const onBoardingBg5 = '$assetPath/c_r_m_system.png';

/// DESIGN BY: ASSIGN-DEVELOPER
const appDeveloper = 'assignDeveloper';
const designBy = 'Design By: $appDeveloper';
final copyRight =
    'Copyright \u00a9 ${DateTime.now().year}, All Rights Reserved.';

/// SCREEN TITLES
const welcomeTitle = 'Welcome to Assign';
const employeeSignInTitle = 'Employee Sign In';
const agentTitle = 'agent';
const posAppTitle = 'p.o.s';
const inventoryAppTitle = 'inventory - ims';
const procurementAppTitle = 'procurement & suppliers';
const salesDistributionAppTitle = 'sales - distribution';
const warehouseAppTitle = 'warehouse - wms';
const customerAppTitle = 'customer - crm';
const systemAdminAppTitle = 'System Administration';
const storeSwitcherAppTitle = 'switch store locations';
const userGuideAppTitle = 'user - guide';

/// MANAGEMENT SUB-SCREENS TITLES
const supplierManagementScreenTitle = 'supplier management';
const supplierEvaluationScreenTitle = 'supplier evaluation';
const supplierAccountScreenTitle = 'supplier account';
const contractManagementScreenTitle = 'contract management';
const liveSupportScreenTitle = 'live support';
const allOrderScreenTitle = 'orders Management';
const stocksScreenTitle = 'item management';
const clienteleScreenTitle = 'clientele';
const allWorkspacesScreenTitle = 'tenants workspaces';
const subscriptionScreenTitle = 'subscriptions & licenses';
const troubleshootScreenTitle = 'troubleshoot';
const salesOrderScreenTitle = ' orders (so)';
const purchaseOrderScreenTitle = 'purchase order (po)';
const miscOrderScreenTitle = 'miscellaneous order (mo)';
const requestPriceQuoteScreenTitle = 'request for quote';
const deliveryScreenTitle = 'delivery management';
const reportsAnalyticsScreenTitle = 'reports analytics';
const salesScreenTitle = 'sales management';
const warehouseScreenTitle = 'warehouse management';
const customersScreenTitle = 'customer management';
const posSalesScreenTitle = 'p.o.s - sales';
const posOrdersScreenTitle = 'p.o.s - orders';
const guideToScreenTitle = 'Guide to...';

const kAppBarHeight = 80.0;
const fMinutesDuration = Duration(minutes: 5);
const kDProgressDelay = Duration(seconds: 2);
const kRProgressDelay = Duration(seconds: 3);
const kFProgressDelay = Duration(seconds: 5);
const kIProgressDelay = Duration(seconds: 20);
const kTProgressDelay = Duration(seconds: 10);
const kAnimateDuration = Duration(milliseconds: 300);
const fAnimateDuration = Duration(milliseconds: 500);
