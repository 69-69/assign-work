import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

var _today = DateTime.now();

class Tax extends Equatable {
  final String id;

  /// COVID-19 levy: 1% [covid]
  /// VAT is the Value Added levy: 15% [vat]
  /// National Health Insurance Levy: 2.5% [nHil]
  /// Tourism Development Fund levy: 1% [tourism]
  /// Ghana Education Trust Fund levy: 2.5% [getFund]
  final String name;

  /// Tax code
  final String code;
  final double rate;
  final String notes;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  Tax({
    this.id = '',
    required this.name,
    required this.code,
    required this.rate,
    required this.notes,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [StoreLocation.fromMap]
  factory Tax.fromMap(Map<String, dynamic> data, {String? id}) => Tax(
    id: id ?? data['id'] ?? '',
    name: data['name'] ?? '',
    code: data['code'] ?? '',
    rate: double.tryParse(data['rate']?.toString() ?? '0') ?? 0.0,
    notes: data['notes'] ?? '',
    createdBy: data['createdBy'] ?? '',
    createdAt: toDateTimeFn(data['createdAt']),
    updatedBy: data['updatedBy'] ?? '',
    updatedAt: toDateTimeFn(data['updatedAt']),
  );

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'name': name,
    'code': code,
    'rate': rate,
    'notes': notes,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
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

  bool get isEmpty => name.isEmpty || '$rate'.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  String get itemAsString => '$name - $rate';

  // @override
  // String toString() => '$name - $rate';

  /// Filter Search
  bool filterByAny(String filter) {
    // Split the filter into separate terms if it contains spaces
    final terms = filter.split(' ');

    // Check if any term matches any of the properties
    return terms.any(
      (term) =>
          id.contains(term) ||
          code.contains(term) ||
          name.contains(term) ||
          '$rate'.contains(term) ||
          notes.contains(term) ||
          createdBy.contains(term),
    );
  }

  /// [findById]
  static Tax? findById(List<Tax> departs, String id) =>
      departs.firstWhereOrNull((d) => d.id == id);

  /// copyWith method
  Tax copyWith({
    String? id,
    String? name,
    String? code,
    double? rate,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Tax(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      rate: rate ?? this.rate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    rate,
    notes,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for tax [toListT]
  List<String> toListT() => [
    id,
    name.toTitleCase,
    code.toUpperCaseAll,
    '$rate',
    notes.toSentenceCase,
    createdBy.toTitleCase,
    getCreatedAt,
    updatedBy.toTitleCase,
    getUpdatedAt,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'Tax',
    'Code',
    'Rate %',
    'Notes',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}
