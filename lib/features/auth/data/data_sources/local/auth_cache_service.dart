import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/network/data_sources/local/cache_data_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:hive/hive.dart';

class AuthCacheService {
  static const String _empCacheKey = Employee.cacheKey;
  static const String _workCacheKey = Workspace.cacheKey;

  Box<CacheData> _dataBox;

  AuthCacheService() : _dataBox = Hive.box<CacheData>(userAuthCache);

  /// Read/Get cache data by id [_getCacheById]
  CacheData? _getCacheById(String id) => _dataBox.get(id);

  // debugPrint('PATH:: ${_dataBox.path}');
  /// Add to Cache/localStorage [_addToCache]
  /// [docId] is the cache key
  Future<void> _addToCache(String docId, CacheData cacheData) async =>
      await _dataBox.put(docId, cacheData);

  /// Clear & delete Cache/localStorage [_clearCache]
  Future<void> _clearCache(String key) async {
    try {
      // Ensure the box isn't closed before performing any actions
      if (!_dataBox.isOpen) {
        // Open the box if it's not already open
        _dataBox = await Hive.openBox<CacheData>(userAuthCache);
      }

      await Future.wait([
        _dataBox.clear(),
        _dataBox.delete(key),
        _dataBox.flush(),
      ]);
      prettyPrint('Cache cleared', 'successfully');
    } catch (e) {
      prettyPrint('Error clearing cache', '$e');
    }
  }

  Workspace? getWorkspace() {
    CacheData? cache = _getCacheById(_workCacheKey);
    return cache != null ? Workspace.fromMap(cache.data) : null;
  }

  Employee? getEmployee() {
    CacheData? cache = _getCacheById(_empCacheKey);
    return cache != null ? Employee.fromMap(cache.data) : null;
  }

  /// Set Workspace to Cache/localStorage [setWorkspace]
  Future<void> setWorkspace(Workspace workspace) async {
    final cacheData = CacheData.fromCache(
      workspace.toCache(),
      id: _workCacheKey,
      scopeId: workspace.id,
    );
    // Add to Cache/localStorage
    await _addToCache(_workCacheKey, cacheData);
  }

  /// Set Employee to Cache/localStorage [setEmployee]
  Future<void> setEmployee(Employee employee) async {
    final cacheData = CacheData.fromCache(
      employee.toCache(),
      id: _empCacheKey,
      scopeId: employee.workspaceId,
    );
    // Add to Cache/localStorage
    await _addToCache(_empCacheKey, cacheData);
  }

  /// Switch between store Locations [switchStores]
  Future<bool> switchStores(String storeNumber) async {
    Employee? employee = getEmployee();
    if (employee == null) return false;

    final emp = employee.copyWith(storeNumber: storeNumber);
    await setEmployee(emp);
    // await _dataBox.flush(); // flush cache to disk

    return true;
  }

  Future<void> deleteWorkspace() async => _clearCache(_workCacheKey);

  Future<void> deleteEmployee() async => _clearCache(_empCacheKey);
}
