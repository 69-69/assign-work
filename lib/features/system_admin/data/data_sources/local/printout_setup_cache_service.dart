import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/network/data_sources/local/setup_printout_model.dart';
import 'package:hive/hive.dart';

class PrintoutSetupCacheService {
  static const String _settingsKey = 'print_out_setup';
  final Box<SetupPrintOut> dataBox;

  PrintoutSetupCacheService()
    : dataBox = Hive.box<SetupPrintOut>(printoutSetupCache);

  Future<SetupPrintOut?> getSettings() async {
    return dataBox.get(_settingsKey, defaultValue: SetupPrintOut());
  }

  Future<void> setSettings(SetupPrintOut settings) async {
    await dataBox.put(_settingsKey, settings);
  }

  Future<void> deleteSettings() async => await dataBox.delete(_settingsKey);
}
