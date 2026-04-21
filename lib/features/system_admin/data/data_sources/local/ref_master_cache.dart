import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/ref_master_model.dart';
import 'package:hive/hive.dart';

/// A util service for caching User's selection from RefMaster using Hive local storage.
class RefMasterCache {
  final Box<CacheData> _dataBox;

  RefMasterCache() : _dataBox = Hive.box<CacheData>(refMasterCache);

  /// Read/Get cache data by Key [_getCacheByKey]
  CacheData? _getCacheByKey(String key) => _dataBox.get(key);

  // debugPrint('PATH:: ${_dataBox.path}');
  /// Add to Cache/localStorage [_addToCache]
  Future<void> _addToCache(String key, CacheData cacheData) async =>
      await _dataBox.put(key, cacheData);

  /// Retrieves the cached, if it exists.
  RefMaster? getById(String id) {
    CacheData? cache = _getCacheByKey(id);
    return cache != null ? RefMaster.fromMap(cache.data) : null;
  }

  List<Map<String, dynamic>> _buildMap() {
    return _dataBox.values.map((e) => e.data).toList();
  }

  /// List of String of all Reference Master
  List<String> getRefs() => RefMaster.fromMapList(_buildMap());

  /// Stores the generated Reference Master in local storage.
  Future<void> setRef(Map<String, dynamic> data) async {
    final ref = RefMaster.fromMap(data);
    final cacheKey = ref.id;
    final cacheData = CacheData.fromCache(
      ref.toCache(),
      id: cacheKey,
      scopeId: 'reference_master_scope',
    );

    return await _addToCache(cacheKey, cacheData);
  }

  /// Clears the stored Ref Master by ID.
  /// [id] is same as cacheKey
  Future<void> clearById(String id) async => await _dataBox.delete(id);
}
