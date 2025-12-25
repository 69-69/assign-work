import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

class Category extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final List<AuditLog> history;

  Category({
    this.id = '',
    required this.name,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? const [],
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [StoreLocation.fromMap]
  factory Category.fromMap(Map<String, dynamic> map, {String? id}) {
    return Category(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
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

  /// A singleton instance representing an empty/default Category.
  /// Used as a fallback when no matching Category is found.
  static final Category empty = Category(name: '', createdBy: '');

  /// Returns true if this instance is the singleton [empty] Category.
  /// Use this to check if the Category is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, Category.empty);

  bool get isNotEmpty => !isEmpty;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// Current / Today's Products/Stocks
  bool get isToday {
    var dt = createdAt.toDateTime;

    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  String get itemAsString => name.toTitle;

  static get notFound => Category(name: 'No Data', createdBy: 'No Data');

  /// Filter Search
  bool filterByAny(String filter) =>
      name.contains(filter) || id.contains(filter);

  /// [findCategoriesById]
  static Iterable<Category> findCategoriesById(
    List<Category> categories,
    String id,
  ) => categories.where((d) => d.id == id);

  /// copyWith method
  Category copyWith({
    String? id,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
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
    name,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
    history,
  ];

  /// ToList for StoreLocation [itemAsList]
  List<String> get itemAsList => [
    id,
    name.toTitle,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'Category',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}
