import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/// [Permission] Represents a single permission entry
/// (e.g., "editStock" under "Inventory" module).
/// This is the atomic unit of a permission, saved to Firestore in this format:
///
/// Example JSON:
/// {
///   "module": "Inventory",
///   "permission": "editStock"
/// }
class Permission extends Equatable {
  /// [module] Name of the Module. E.g., "Inventory".
  final String module;

  /// [permission] Name of the Permission. E.g., "editStock".
  final String permission;

  const Permission({required this.module, required this.permission});

  factory Permission.fromMap(Map<String, dynamic> map) => Permission(
    module: map['module'] ?? '',
    permission: map['permission'] ?? '',
  );

  Map<String, dynamic> toMap() => {'module': module, 'permission': permission};

  bool filterByAny(String filter) {
    final term = filter.toLowerAll;
    return module.toLowerAll.contains(term) ||
        permission.toLowerAll.contains(term);
  }

  /// Equality check needed for storing in `Set<Permission>`.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Permission &&
          runtimeType == other.runtimeType &&
          module.toLowerAll == other.module.toLowerAll &&
          permission == other.permission;

  /// Used by Sets and Maps for uniqueness.
  @override
  int get hashCode => module.hashCode ^ permission.hashCode;

  @override
  List<Object?> get props => [module, permission];
}
