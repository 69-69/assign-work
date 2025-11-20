import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/system_admin/data/models/permission_model.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

/// Role-Based Access-Control [Role]
class Role extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String name;
  final Set<Permission> permissions;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Role({
    this.id = '',
    required this.name,
    required this.permissions,
    this.createdBy = '',
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  static const String cacheKey = 'role_permissions_cache';

  /// fromFirestore / fromJson Function [Role.fromMap]
  factory Role.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawPermissions = map['permissions'] as List<dynamic>? ?? [];

    final perms = rawPermissions
        .map((perm) => Map<String, dynamic>.from(perm as Map))
        .map(Permission.fromMap)
        .toSet();

    return Role(
      id: (id ?? map['id']) ?? '',
      name: map['name'] ?? '',
      permissions: perms,
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'name': name,
    'permissions': permissions.map((p) => p.toMap()).toList(),
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
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
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;
    newMap['updatedAt'] = updatedAt.millisecondsSinceEpoch;

    return {'id': cacheKey, 'data': newMap};
  }

  Role copyWith({
    String? id,
    String? name,
    Set<Permission>? permissions,
    String? updatedBy,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// [findById]
  static Role? findById(List<Role> roles, String id) =>
      roles.firstWhereOrNull((r) => r.id == id);

  String get itemAsString => name.toTitle;

  /// Filter
  bool filterByAny(String filter) =>
      name.contains(filter) || permissions.any((p) => p.filterByAny(filter));

  @override
  List<Object?> get props => [
    id,
    name,
    permissions,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for PRODUCTS [itemAsList]
  List<String> itemAsList() => [
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
