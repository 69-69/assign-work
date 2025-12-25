import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/network/data_sources/local/setup_printout_model.dart';
import 'package:hive/hive.dart';

class PrintSetupCacheService {
  static const String _settingsKey = 'print_out_setup';
  final Box<SetupPrintOut> dataBox;

  PrintSetupCacheService()
    : dataBox = Hive.box<SetupPrintOut>(printoutSetupCache);

  Future<SetupPrintOut?> getSettings() async {
    return dataBox.get(_settingsKey, defaultValue: SetupPrintOut.empty);
  }

  Future<void> setSettings(SetupPrintOut settings) async {
    await dataBox.put(_settingsKey, settings);
  }

  Future<void> deleteSettings() async => await dataBox.delete(_settingsKey);
}
