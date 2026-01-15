import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/features/access_control/domain/repository/access_control_repository.dart';
import 'package:assign_erp/features/access_control/presentation/cubit/access_control_state.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/error_logs_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccessControlCubit extends Cubit<AccessControlState> {
  final AccessControlRepository accessControlRepository;

  AccessControlCubit(this.accessControlRepository)
    : super(const AccessControlState(permissions: {}, licenses: {}));

  String? _cachedRoleId;
  String? _cachedSubscriptionId;
  String? _cachedRoleName;
  String? _cachedSubscriptionName;

  String? get roleName => _cachedRoleName;

  String? get subscriptionName => _cachedSubscriptionName;

  /// Load permissions and licenses
  Future<void> loadAll(
    String roleId, {
    String? subscriptionId,
    String? workspaceId,
    String? workspaceRole,
  }) async {
    try {
      emit(state.copyWith(status: AccessControlStatus.loading));

      // Load both in parallel
      final futures = [
        if (subscriptionId != null) loadLicenses(subscriptionId),

        loadPermissions(
          roleId,
          workspaceId: workspaceId,
          workspaceRole: workspaceRole,
        ),
      ];

      await Future.wait(futures);

      emit(state.copyWith(status: AccessControlStatus.loaded));
    } catch (e) {
      emit(state.copyWith(status: AccessControlStatus.error));
      final errorLogCache = ErrorLogCache();
      errorLogCache.setError(error: '$e', fileName: 'access_control_cubit');

      prettyPrint("Error loading access control data", "$e");
    }
  }

  Future<void> loadPermissions(
    String roleId, {
    String? workspaceId,
    String? workspaceRole,
  }) async {
    if (_cachedRoleId == roleId && state.permissions.isNotEmpty) {
      return; // Already loaded
    }

    final result = await accessControlRepository.fetchPermissionsForRole(
      roleId,
      workspaceId: workspaceId,
      workspaceRole: workspaceRole,
    );

    _cachedRoleId = roleId;
    _cachedRoleName = result.meta;

    emit(state.copyWith(permissions: result.data));
  }

  Future<void> loadLicenses(String subscriptionId) async {
    if (_cachedSubscriptionId == subscriptionId && state.licenses.isNotEmpty) {
      return;
    }

    final result = await accessControlRepository.fetchLicensesForSubscription(
      subscriptionId,
    );
    _cachedSubscriptionId = subscriptionId;
    _cachedSubscriptionName = result.meta;

    emit(state.copyWith(licenses: result.data));
  }

  void clear() {
    _cachedRoleId = null;
    _cachedSubscriptionId = null;
    _cachedRoleName = null;
    _cachedSubscriptionName = null;

    emit(
      const AccessControlState(
        licenses: {},
        permissions: {},
        status: AccessControlStatus.initial,
      ),
    );
  }

  // Permission helpers
  bool has(String permission) => state.permissions.contains(permission);

  bool hasAll(Set<String> perms) => state.permissions.containsAll(perms);

  bool hasAny(Set<String> perms) =>
      state.permissions.intersection(perms).isNotEmpty;

  // License helpers
  bool isLicensed(String license) => state.licenses.contains(license);

  bool isLicensedAny(Set<String> licenses) =>
      licenses.any((license) => state.licenses.contains(license));

  bool isLicensedAll(Set<String> licenses) =>
      licenses.every((license) => state.licenses.contains(license));
}

extension AccessControlCubitExtensions on BuildContext {
  /*final canAccess = context.watch((AccessControlCubit c) => c.has(perm));*/

  // Watch version (reactive) [_watchAcCubit]
  // Works only inside build() (or widgets that rebuild), not in callbacks like onTap or async
  AccessControlCubit _watchAcCubit() => watch<AccessControlCubit>();

  // Read version (one-time, non-reactive) [_readAcCubit]
  // Works anywhere, including callbacks like onTap, async functions, or lifecycle methods.
  AccessControlCubit _readAcCubit() => read<AccessControlCubit>();

  /// Reactive methods (using watch)
  String get getRoleName => _watchAcCubit().roleName ?? 'employee';

  String get getSubscriptionName =>
      _watchAcCubit().subscriptionName ?? 'unsubscribed';

  Set<String> get getPermissions => _watchAcCubit().state.permissions;

  Set<String> get getLicenses => _watchAcCubit().state.licenses;

  bool Function(String) get hasPermission => _watchAcCubit().has;

  bool Function(Set<String>) get hasAllPermissions => _watchAcCubit().hasAll;

  bool Function(Set<String>) get hasAnyPermissions => _watchAcCubit().hasAny;

  bool Function(String) get isLicensed => _watchAcCubit().isLicensed;

  bool Function(Set<String>) get isLicensedAny => _watchAcCubit().isLicensedAny;

  bool Function(Set<String>) get isLicensedAll => _watchAcCubit().isLicensedAll;

  /// Non-reactive methods (using read)
  String get readRoleName => _readAcCubit().roleName ?? 'employee';

  String get readSubscriptionName =>
      _readAcCubit().subscriptionName ?? 'unsubscribed';

  Set<String> get readPermissions => _readAcCubit().state.permissions;

  Set<String> get readLicenses => _readAcCubit().state.licenses;

  bool Function(String) get readHasPermission => _readAcCubit().has;

  bool Function(Set<String>) get readHasAllPermissions => _readAcCubit().hasAll;

  bool Function(Set<String>) get readHasAnyPermissions => _readAcCubit().hasAny;

  bool Function(String) get readIsLicensed => _readAcCubit().isLicensed;

  bool Function(Set<String>) get readIsLicensedAny =>
      _readAcCubit().isLicensedAny;

  bool Function(Set<String>) get readIsLicensedAll =>
      _readAcCubit().isLicensedAll;
}

/*extension AccessControlCubitExtensions2 on BuildContext {
  AccessControlCubit get _acCubit => read<AccessControlCubit>();

  // AccessControlCubit get _acCubit => watch<AccessControlCubit>();

  String get getRoleName => _acCubit.roleName ?? 'employee';

  String get getSubscriptionName => _acCubit.subscriptionName ?? 'unsubscribed';

  Set<String> get getPermissions => _acCubit.state.permissions;

  Set<String> get getLicenses => _acCubit.state.licenses;

  // USAGE: context.hasPermission(permission)
  bool Function(String) get hasPermission => _acCubit.has;

  bool Function(Set<String>) get hasAllPermissions => _acCubit.hasAll;

  bool Function(Set<String>) get hasAnyPermissions => _acCubit.hasAny;

  // USAGE: context.isLicensed(license)
  bool Function(String) get isLicensed => _acCubit.isLicensed;

  bool Function(Set<String>) get isLicensedAny => _acCubit.isLicensedAny;

  bool Function(Set<String>) get isLicensedAll => _acCubit.isLicensedAll;
}*/

/* NEW:
class AccessControlCubit extends Cubit<Set<String>> {

  final AccessControlRepository accessControlRepository;

  AccessControlCubit(this.accessControlRepository) : super({});

  String? _cachedRoleId;
  String? _cachedSubscriptionId;

  String? _cachedRoleName;

  /// Employee/Staff role name [roleName]
  String? get roleName => _cachedRoleName;

  Set<String>? _cachedPermissions;
  Set<String>? _cachedLicenses;

  /// Load both permissions and licenses [loadAll]
  Future<void> loadAll(
    String roleId, {
    String? subscriptionId,
    String? workspaceId,
    String? workspaceRole,
  }) async {
    await Future.wait([
      /// Get Signed In Employee Role & Permissions
      loadPermissions(
        roleId,
        workspaceId: workspaceId,
        workspaceRole: workspaceRole,
      ),

      /// Get Signed In Tenant's (Workspace) Subscription Licenses
      if (subscriptionId != null) loadLicenses(subscriptionId),
    ]);
  }

  /// [loadLicenses] Fetch and cache Signed In Tenant's (Workspace) Subscription Licenses
  Future<void> loadLicenses(String subscriptionId) async {
    await _loadIfNeeded<void>(
      key: subscriptionId,
      cacheKey: _cachedSubscriptionId,
      cachedData: _cachedLicenses,
      fetch: () => accessControlRepository.fetchSubscriptionLicenses(subscriptionId),
      onCacheUpdate: (data, {meta}) {
        prettyPrint('licenses', '$data');
        _cachedSubscriptionId = subscriptionId;
        _cachedLicenses = data;
      },
    );
  }

  /// [loadPermissions] Fetch and cache Signed In Employee Role & Permissions
  Future<void> loadPermissions(
    String roleId, {
    String? workspaceId,
    String? workspaceRole,
  }) async {
    await _loadIfNeeded<String>(
      key: roleId,
      cacheKey: _cachedRoleId,
      cachedData: _cachedPermissions,
      fetch: () => accessControlRepository.fetchPermissionsForRole(
        roleId,
        workspaceId: workspaceId,
        workspaceRole: workspaceRole,
      ),
      onCacheUpdate: (data, {meta}) {
        prettyPrint('role-name', meta);
        _cachedRoleId = roleId;
        _cachedPermissions = data;
        _cachedRoleName = meta;
      },
    );
  }

  /// [_loadIfNeeded] Generalized helper method to load data (permissions or licenses) if needed
  Future<void> _loadIfNeeded<T>({
    required String key,
    required String? cacheKey,
    required Set<String>? cachedData,
    required Future<LoadResult<T>> Function() fetch,
    required void Function(Set<String> data, {T? meta}) onCacheUpdate,
  }) async {
    if (key == cacheKey && cachedData != null) {
      emit(cachedData);
      return;
    }

    final result = await fetch();
    onCacheUpdate(result.data, meta: result.meta);
    prettyPrint('result', result.data.toString());
    emit(result.data);
  }

  void clear() {
    _cachedPermissions = null;
    _cachedLicenses = null;
    _cachedRoleId = null;
    _cachedRoleName = null;
    emit({});
  }

  // Unified helpers for permissions
  bool has(String permission) => state.contains(permission);
  bool hasAll(Set<String> permissions) => state.containsAll(permissions);
  bool hasAny(Set<String> permissions) =>
      state.intersection(permissions).isNotEmpty;

  // Unified helpers for licenses
  bool isLicensed(String license) =>
      _cachedLicenses?.contains(license) ?? false;

  /// Check if workspace is licensed for one or more licenses
  bool isLicensedAny(Set<String> licenses) =>
      licenses.any((license) => _cachedLicenses?.contains(license) ?? false);

  /// Check if workspace has all the required licenses
  bool isLicensedAll(Set<String> licenses) =>
      licenses.every((license) => _cachedLicenses?.contains(license) ?? false);
}

extension AccessControlCubitExtensions on BuildContext {
  AccessControlCubit get _acCubit => read<AccessControlCubit>();

  /// Get employee/staff role name [roleName]
  String get getRoleName => _acCubit.roleName ?? 'employee';

  /// Get employee/staff permissions [getPermissions]
  Set<String> get getPermissions => _acCubit.state;

  /// Get employee/staff licenses [getLicenses]
  Set<String> get getLicenses => _acCubit._cachedLicenses ?? {};

  /// Check if employee has permissions
  get hasPermission => _acCubit.has;
  get hasAllPermissions => _acCubit.hasAll;
  get hasAnyPermissions => _acCubit.hasAny;

  /// Check if tenant (workspace) is licensed
  get isLicensed => _acCubit.isLicensed;
  get isLicensedAny => _acCubit.isLicensedAny;
  get isLicensedAll => _acCubit.isLicensedAll;
}*/

/* OLD
class PermissionCubit extends Cubit<Set<String>> {
  final PermissionRepository rolePermRepository;

  PermissionCubit(this.rolePermRepository) : super({});

  String? _cachedRoleId;
  Set<String>? _cachedPermissions;
  Set<String>? _cachedLicenses;

  // load the two methods under one name
  Future<void> loadAll(
    String roleId, {
    String? subscriptionId,
    String? workspaceId,
    String? workspaceRole,
  }) async {
    await Future.wait([
      // loadLicenses(workspaceId!),
      loadPermissions(
        roleId,
        workspaceId: workspaceId,
        workspaceRole: workspaceRole,
      ),
    ]);
  }

  Future<void> loadLicenses(String subscriptionId) async {
    await _loadIfNeeded(
      key: subscriptionId,
      cacheKey: _cachedSubscriptionId,
      cachedData: _cachedLicenses,
      fetch: () => rolePermRepository.fetchSubscriptionLicenses(subscriptionId),
      onCacheUpdate: (data) {
        _cachedSubscriptionId = subscriptionId;
        _cachedLicenses = data;
      },
    );
  }

  Future<void> loadPermissions(
    String roleId, {
    String? workspaceId,
    String? workspaceRole,
  }) async {
    await _loadIfNeeded(
      key: roleId,
      cacheKey: _cachedRoleId,
      cachedData: _cachedPermissions,
      fetch: () => rolePermRepository.fetchPermissionsForRole(
        roleId,
        workspaceId: workspaceId,
        workspaceRole: workspaceRole,
      ),
      onCacheUpdate: (data) {
        _cachedRoleId = roleId;
        _cachedPermissions = data;
      },
    );
  }

  Future<void> _loadIfNeeded({
    required String key,
    required String? cacheKey,
    required Set<String>? cachedData,
    required Future<LoadResult<String>> Function() fetch,
    required void Function(Set<String>) onCacheUpdate,
  }) async {
    if (key == cacheKey && cachedData != null) {
      emit(cachedData);
      return;
    }

    final result = await fetch();
    onCacheUpdate(result.data);
    emit(result.data);
  }

  void clear() {
    _cachedPermissions = null;
    _cachedLicenses = null;
    _cachedRoleId = null;
    _cachedWorkspaceId = null;
    emit({});
  }

  // Unified helpers
  bool has(String permission) => state.contains(permission);
  bool hasAll(Set<String> permissions) => state.containsAll(permissions);
  bool hasAny(Set<String> permissions) =>
      state.intersection(permissions).isNotEmpty;

  bool isLicensed(String license) => has(license);
  bool isLicensedAll(Set<String> licenses) => hasAll(licenses);
  bool isLicensedAny(Set<String> licenses) => hasAny(licenses);
}*/
