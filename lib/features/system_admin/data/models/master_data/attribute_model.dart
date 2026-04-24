import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/// Variant Attributes
class Attribute extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String type; // Color, Size
  final String value; // Red, Blue, Extra Large, Large, Medium
  final String code; // Red, Blu, XL, M, L,
  final String storeNumber; // FK CompanyStore.storeNumber
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final List<AuditLog> history;

  Attribute({
    this.id = '',
    required this.type,
    required this.value,
    required this.code,
    required this.storeNumber,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? const [],
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  // 'Type' must group values logically
  static Map<String, List<String>> groupAttributes(List<Attribute> attrs) {
    final Map<String, List<String>> grouped = {};

    for (final a in attrs) {
      grouped.putIfAbsent(a.type, () => []);
      grouped[a.type]!.add(a.value);
    }

    return grouped;
  }

  // Generate Short Code for Attribute value
  String get safeCode {
    // word-based code
    final words = value.trim().toUpperAll.split(RegExp(r'\s+'));

    if (words.length == 1) {
      return words.first.substring(0, words.first.length.clamp(1, 3));
    }

    // multi-word: take initials
    return words.map((w) => w[0]).join();
  }

  /// fromFirestore / fromJson Function [StoreLocation.fromMap]
  factory Attribute.fromMap(Map<String, dynamic> map, {String? id}) {
    return Attribute(
      id: id ?? map['id'] ?? '',
      type: map['type'] ?? '',
      value: map['value'] ?? '',
      code: map['code'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
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
    'type': type.toTitle,
    'value': value,
    'code': code,
    'storeNumber': storeNumber,
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

  /// A singleton instance representing an empty/default Attribute.
  /// Used as a fallback when no matching Attribute is found.
  static final Attribute empty = Attribute(
    type: '',
    value: '',
    code: '',
    createdBy: '',
    storeNumber: '',
  );

  /// Returns true if this instance is the singleton [empty] Attribute.
  /// Use this to check if the Attribute is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, Attribute.empty);

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

  String get itemAsString => type.toTitle;

  /// Filter/Search
  bool filterByAny(String filter) =>
      {type, value, code, id, storeNumber}.filterAny(filter);

  /// [findCategoriesById]
  static Iterable<Attribute> findAttributesById(
    List<Attribute> attributes,
    String id,
  ) => attributes.where((d) => d.id == id);

  /// copyWith method
  Attribute copyWith({
    String? id,
    String? type,
    String? value,
    String? code,
    String? storeNumber,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) {
    return Attribute(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      code: code ?? this.code,
      storeNumber: storeNumber ?? this.storeNumber,
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
    type,
    value,
    code,
    storeNumber,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
    history,
  ];

  /// ToList for StoreLocation [itemAsList]
  List<String> get itemAsList => [
    id,
    type.toTitle,
    value.toTitle,
    (code.isEmpty ? safeCode:code).toUpperAll,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'Type',
    'Value',
    'Code',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

/**/
