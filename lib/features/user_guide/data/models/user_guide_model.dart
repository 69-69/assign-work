import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:equatable/equatable.dart';

class UserGuide extends Equatable {
  static get _today => DateTime.now();

  UserGuide({
    this.id = '',
    required this.url,
    required this.title,
    required this.category,
    required this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.history = const [],
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  final String id;
  final dynamic url;
  final String title;
  final String category;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AuditLog> history;

  /// fromFirestore / fromJson Function [UserGuide.fromMap]
  factory UserGuide.fromMap(Map<String, dynamic> map, {String? id}) {
    return UserGuide(
      id: (id ?? map['id']) ?? '',
      url: map['url'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedAt: toDateTimeFn(map['updatedAt']),
      history: AuditLog.auditLogs(map['history']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'url': url,
    'title': title,
    'category': category,
    'description': description,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
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

  static final UserGuide empty = UserGuide(
    id: '',
    url: '',
    title: '',
    category: '',
    description: '',
  );

  bool get isEmpty => identical(this, UserGuide.empty);

  bool get isNotEmpty => !isEmpty;

  /// copyWith method
  UserGuide copyWith({
    String? id,
    String? url,
    String? title,
    String? category,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) {
    return UserGuide(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [
    id,
    url,
    title,
    category,
    description,
    createdAt,
    updatedAt,
    history,
  ];
}
