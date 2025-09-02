import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/// [License] Represents a single license entry
/// (e.g., "pos" under "point of sale subscription").
/// This is the atomic unit of a license, saved to Firestore in this format:
///
/// Example JSON:
/// {
///   "module": "point of sale subscription",
///   "license": "pos"
/// }
class License extends Equatable {
  /// [module] Name of the Module. E.g., "point of sale subscription".
  final String module;

  /// [license] Name of the license. E.g., "pos".
  final String license;

  const License({required this.module, required this.license});

  factory License.fromMap(Map<String, dynamic> map) =>
      License(module: map['module'] ?? '', license: map['license'] ?? '');

  Map<String, dynamic> toMap() => {'module': module, 'license': license};

  /// Equality check needed for storing in `Set<License>`.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is License &&
          runtimeType == other.runtimeType &&
          module.toLowerAll == other.module.toLowerAll &&
          license == other.license;

  /// Used by Sets and Maps for uniqueness.
  @override
  int get hashCode => module.hashCode ^ license.hashCode;

  @override
  List<Object?> get props => [module, license];
}
