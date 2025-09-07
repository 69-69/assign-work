import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/features/system_admin/data/models/backup_filenames_model.dart';
import 'package:hive/hive.dart';

/// A service for caching the Backup Filename using Hive local storage.
class BackupFilenameCache {
  Box<CacheData> _dataBox;

  BackupFilenameCache() : _dataBox = Hive.box<CacheData>(backupFileNamesCache);

  /// Read/Get cache data by Key [_getCacheByKey]
  CacheData? _getCacheByKey(String key) => _dataBox.get(key);

  // debugPrint('PATH:: ${_dataBox.path}');
  /// Add to Cache/localStorage [_addToCache]
  Future<void> _addToCache(String key, CacheData cacheData) async =>
      await _dataBox.put(key, cacheData);

  /// Retrieves the cached, if it exists.
  BackupFilename? getById(String id) {
    CacheData? cache = _getCacheByKey(id);
    return cache != null ? BackupFilename.fromMap(cache.data) : null;
  }

  List<Map<String, dynamic>> _buildMap() {
    return _dataBox.values.map((e) => e.data).toList();
  }

  /// List of String of all backup filenames
  List<String> getFilenames() {
    return BackupFilename.fromMapList(_buildMap());
  }

  /// Stores the generated Backup Filename in local storage.
  Future<void> setBackupFilename(Map<String, dynamic> data) async {
    final info = BackupFilename.fromMap(data);
    final cacheKey = info.id;
    final cacheData = CacheData.fromCache(
      info.toCache(),
      id: cacheKey,
      scopeId: 'back_up_filename',
    );

    return await _addToCache(cacheKey, cacheData);
  }

  /// Clear & delete Cache/localStorage [_clearCache]
  Future<void> _clearCache() async {
    try {
      // Ensure the box isn't closed before performing any actions
      if (!_dataBox.isOpen) {
        // Open the box if it's not already open
        _dataBox = await Hive.openBox<CacheData>(userAuthCache);
      }

      await Future.wait([_dataBox.clear(), _dataBox.flush()]);
      prettyPrint('Cache cleared', 'successfully');
    } catch (e) {
      prettyPrint('Error clearing cache', '$e');
    }
  }

  /// Clears the stored Backup Filename by ID.
  /// [id] is same as cacheKey
  Future<void> clearById(String id) async => await _dataBox.delete(id);

  /// Clears the stored Backup Filename from local storage.
  Future<void> clearFilenames() async => await _clearCache();
}
