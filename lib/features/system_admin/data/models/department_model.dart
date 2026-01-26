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

  /// Department lead/manager's Id [leadId]
  final String leadId;

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
    this.leadId = '',
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
      leadId: map['leadId'] ?? '',
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
    'leadId': leadId,
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
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  /// A singleton instance representing an empty/default Department.
  /// Used as a fallback when no matching Department is found.
  static get empty => Department(id: '', name: '', code: '', createdBy: '');

  bool get isEmpty => name.isEmpty || code.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  String get itemAsString => name.toTitle;

  /// Filter/search
  bool filterByAny(String filter) =>
      itemAsList.filterAny(filter) || description.filterAny(filter);

  /// [findById]
  static Department? findById(List<Department> departs, String id) =>
      departs.firstWhereOrNull((d) => d.id == id);

  /// copyWith method
  Department copyWith({
    String? id,
    String? code,
    String? name,
    String? leadId,
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
      leadId: leadId ?? this.leadId,
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
    leadId,
    description,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
    history,
  ];

  /// ToList for StoreLocation [itemAsList]
  List<String> get itemAsList => [
    id,
    code,
    name.toTitle,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'Code',
    'Department',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

/// Creates the default department for the business owner during initial workspace setup
/// (first-time tenant creation): System-defined department created automatically.
Map<String, dynamic> createBusinessOwnerDepartment({required String id}) =>
    Department(
      id: id,
      name: 'executive office',
      leadId: 'ceo',
      code: 'ceo'.generateUniqueCode(),
      description: 'this is the ceo\'s executive office department',
      createdBy: 'system',
    ).toMap();
