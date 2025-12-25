import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

class Department extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String name;

  /// Department lead/manager's name [lead]
  final String lead;

  /// Departmental Unique Code/ID [code]
  final String code;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final List<AuditLog> history;

  Department({
    this.id = '',
    required this.code,
    required this.name,
    this.lead = '',
    this.description = '',
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? const [],
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [StoreLocation.fromMap]
  factory Department.fromMap(Map<String, dynamic> map, {String? id}) {
    return Department(
      id: id ?? map['id'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      lead: map['lead'] ?? '',
      description: map['description'] ?? '',
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
    'code': code,
    'name': name,
    'lead': lead,
    'description': description,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'history': history.map((e) => e.toMap()).toList(),
  };

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;
    newMap['updatedAt'] = updatedAt.millisecondsSinceEpoch;

    return {'id': id, 'data': newMap};
  }

  /// A singleton instance representing an empty/default Department.
  /// Used as a fallback when no matching Department is found.
  static final Department empty = Department(
    id: '',
    name: '',
    code: '',
    createdBy: '',
  );

  /// Returns true if this instance is the singleton [empty] Department.
  /// Use this to check if the Department is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, Department.empty);

  bool get isNotEmpty => !isEmpty;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  String get itemAsString => name.toTitle;

  /// Filter Search
  bool filterByAny(String filter) =>
      name.contains(filter) ||
      code.contains(filter) ||
      description.contains(filter) ||
      createdBy.contains(filter);

  /// [findById]
  static Department? findById(List<Department> departs, String id) =>
      departs.firstWhereOrNull((d) => d.id == id);

  /// copyWith method
  Department copyWith({
    String? id,
    String? code,
    String? name,
    String? lead,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) {
    return Department(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      lead: lead ?? this.lead,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    lead,
    description,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
    history,
  ];

  /// ToList for StoreLocation [toListL]
  List<String> toListL() => [
    id,
    code,
    name.toTitle,
    lead.toTitle,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'Code',
    'Department',
    'Lead (Manager)',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

/// [businessOwnerDefaultDepartment] This is the Business owner's default Department
/// during first-time workspace setup(Workspace Creation)
Map<String, dynamic> businessOwnerDefaultDepartment({required String id}) =>
    Department(
      id: id,
      name: 'executive office',
      lead: 'ceo',
      code: 'ceo'.generateUniqueCode(),
      description: 'this is the ceo\'s executive office department',
      createdBy: 'system',
    ).toMap();
