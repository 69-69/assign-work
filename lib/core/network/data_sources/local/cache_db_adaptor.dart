import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/network/data_sources/local/index.dart';
import 'package:hive_flutter/adapters.dart';

// Define a list of box names for CacheData
const cacheDataBoxes = [
  employeesDBCollectionPath,
  rolesDBCollectionPath,
  employeeSessionLogsCollectionPath,
  storeLocationsDBCollectionPath,
  companyInfoDBCollectionPath,
  departmentsDBCollectionPath,
  supplierDBCollectionPath,
  categoryDBCollectionPath,
  customersDBCollectionPath,
  invoiceDBCollectionPath,
  itemsDBCollectionPath,
  salesDBCollectionPath,
  deliveryDBCollectionPath,
  ordersDBCollectionPath,
  miscOrdersDBCollectionPath,
  workspaceAccDBCollectionPath, // Only for system-wide-bloc (to cache all workspaces)
  subscriptionDBCollectionPath,
  purchaseOrdersDBCollectionPath,
  requestPriceQuoteDBCollectionPath,
  posSalesDBCollectionPath,
  posOrdersDBCollectionPath,
  userGuideDBCollectionPath,
  liveChatSupportDBCollectionPath,
  backupFileNamesCache,
  appErrorLogsCache,
  agentClientsDBCollection,
  taxesDBCollectionPath,
];

/// This is the Cache-Data for all CRUD operation [cacheDBAdaptor]
Future<void> cacheDBAdaptor() async {
  /// Initialize Hive
  await Hive.initFlutter(appCacheDirectory);

  /// Register all adapters
  Hive.registerAdapter(CacheDataAdapter());
  Hive.registerAdapter(SetupPrintOutAdapter());

  /// Open AuthCache hiveBox: for Authentication
  await Hive.openBox<CacheData>(userAuthCache);

  /// Open DeviceCache hiveBox: for User Device Id
  await Hive.openBox<CacheData>(deviceInfoCache);

  /// Open SetupPrintOut hiveBox: for PDFs & Printout Setup
  await Hive.openBox<SetupPrintOut>(printoutSetupCache);

  /// Open all CacheData hiveBoxes for app CRUD operations
  await Future.wait(
    cacheDataBoxes.map((path) => Hive.openBox<CacheData>(path)),
  );
}
