import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/system_admin/data/models/permission_model.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

/// Role-Based Access-Control [Role]
class Role extends Equatable {
  static get _today => DateTime.now();

  final String id;

  /// [isPrimary] Primary [Role] created during initial workspace setup.
  /// This branch is associated with the business owner and `cannot be changed`.
  final bool isPrimary;
  final String name;
  final Set<Permission> permissions;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AuditLog> history;

  Role({
    this.id = '',
    required this.name,
    this.isPrimary = false,
    required this.permissions,
    this.createdBy = '',
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    this.history = const [],
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  static const String cacheKey = 'role_permissions_cache';

  /// fromFirestore / fromJson Function [Role.fromMap]
  factory Role.fromMap(Map<String, dynamic> map, {String? id}) {
    return Role(
      id: (id ?? map['id']) ?? '',
      name: map['name'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
      permissions: Permission.permissionsSet(
        map['permissions'] as List<dynamic>?,
      ),
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt']),
      history: AuditLog.auditLogs(map['history']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'name': name,
    'isPrimary': isPrimary,
    'permissions': permissions.map((p) => p.toMap()).toList(),
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
    'history': history.map((a) => a.toMap()).toList(),
  };

  /// Convert Role to a map for storing in Firestore [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  /// Convert Role to toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': cacheKey, 'data': newMap};
  }

  Role copyWith({
    String? id,
    String? name,
    bool? isPrimary,
    Set<Permission>? permissions,
    String? updatedBy,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      isPrimary: isPrimary ?? this.isPrimary,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }

  /// If its any other [Role], then it can be deleted.
  /// The [primary role] created during initial workspace creation `cannot be deleted`.
  bool get canBeDeleted => !isPrimary;

  /// A singleton instance representing an empty Role.
  /// Used as a fallback when no matching Role is found.
  static get empty => Role(id: '', name: '', permissions: {});

  /// [isEmpty] Checks if the Role is empty.
  bool get isEmpty => identical(this, Role.empty);

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// [findById]
  static Role? findById(List<Role> roles, String id) =>
      roles.firstWhereOrNull((r) => r.id == id);

  String get itemAsString => name.toTitle;

  /// Filter/search
  bool filterByAny(String filter) =>
      itemAsList.filterAny(filter) || permissions.filterAny(filter);

  @override
  List<Object?> get props => [
    id,
    name,
    isPrimary,
    permissions,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
    history,
  ];

  /// ToList for PRODUCTS [itemAsList]
  List<String> get itemAsList => [
    id,
    name.toTitle,
    permissions.length.toString(),
    getCreatedAt,
    createdBy.toTitle,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Role',
    'Permissions',
    'Created At',
    'Created By',
    'Updated By',
    'Updated At',
  ];
}
