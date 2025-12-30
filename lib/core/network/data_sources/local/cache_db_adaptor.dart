import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/network/data_sources/local/index.dart';
import 'package:hive_flutter/adapters.dart';

// Define a list of box names for CacheData
const _cacheDataBoxes = [
  ...erpCacheBoxes,
  ...systemCacheBoxes,
  ...sessionCacheBoxes,
];

/// This is the Cache-Data for all CRUD operation [cacheDBAdaptor]
Future<void> cacheDBAdaptor() async {
  /// Initialize Hive
  await Hive.initFlutter(appCacheDirectory);

  /// Register all adapters (ONCE)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(CacheDataAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(SetupPrintOutAdapter());
  }

  /// Open Auth & Device(User Device Id) boxes (explicit lifecycle)
  await Hive.openBox<CacheData>(userAuthCache);
  await Hive.openBox<CacheData>(deviceInfoCache);

  /// Open PDFs & Printout setup (different adapter)
  await Hive.openBox<SetupPrintOut>(printoutSetupCache);

  /// Open all CacheData hiveBoxes for app CRUD operations
  await Future.wait(
    _cacheDataBoxes.map((path) => Hive.openBox<CacheData>(path)),
  );
}
