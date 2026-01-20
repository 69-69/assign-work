import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/trouble_shooting/data/models/license_model.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

/// Subscription-Based Access-Control [Subscription]
class Subscription extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String name;
  final double fee;
  final Set<License> licenses;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresOn;
  final DateTime effectiveFrom;

  Subscription({
    this.id = '',
    required this.fee,
    required this.name,
    required this.licenses,
    this.createdBy = '',
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    DateTime? expiresOn,
    DateTime? effectiveFrom,
  }) : effectiveFrom = effectiveFrom ?? _today,
       expiresOn = expiresOn ?? _today,
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  static const String cacheKey = 'sub_licenses_cache';

  /// fromFirestore / fromJson Function [Subscription.fromMap]
  factory Subscription.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawLicenses = map['licenses'] as List<dynamic>? ?? [];

    final licenses = rawLicenses
        .map((l) => Map<String, dynamic>.from(l as Map))
        .map(License.fromMap)
        .toSet();

    return Subscription(
      id: (id ?? map['id']) ?? '',
      fee: '${map['fee']}'.asDouble,
      name: map['name'] ?? '',
      licenses: licenses,
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt']),
      expiresOn: toDateTimeFn(map['expiresOn']),
      effectiveFrom: toDateTimeFn(map['effectiveFrom']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'fee': fee,
    'name': name,
    'licenses': licenses.map((p) => p.toMap()).toList(),
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
    'expiresOn': expiresOn,
    'effectiveFrom': effectiveFrom,
  };

  /// Convert Subscription to a map for storing in Firestore [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;
    newMap['expiresOn'] = expiresOn.toISOString;
    newMap['effectiveFrom'] = effectiveFrom.toISOString;

    return newMap;
  }

  /// Convert Subscription to toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;
    newMap['expiresOn'] = expiresOn.toMilliseconds;
    newMap['effectiveFrom'] = effectiveFrom.toMilliseconds;

    return {'id': cacheKey, 'data': newMap};
  }

  Subscription copyWith({
    String? id,
    double? fee,
    String? name,
    Set<License>? licenses,
    String? updatedBy,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? effectiveFrom,
    DateTime? expiresOn,
  }) {
    return Subscription(
      id: id ?? this.id,
      fee: fee ?? this.fee,
      name: name ?? this.name,
      licenses: licenses ?? this.licenses,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresOn: expiresOn ?? this.expiresOn,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
    );
  }

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getExpiresOn]
  String get getExpiresOn => expiresOn.toStandardDT;

  /// Formatted to Standard-DateTime in String [getEffectiveFrom]
  String get getEffectiveFrom => effectiveFrom.toStandardDT;

  /// subscriptionId UnExpired [unExpired]
  bool get unExpired => _today.isBefore(expiresOn.toDateTime);

  /// subscriptionId Expired [isExpired]
  bool get isExpired => !unExpired || _today.isAfter(expiresOn.toDateTime);

  /// [findById]
  static Subscription? findById(List<Subscription> subscriptions, String id) =>
      subscriptions.firstWhereOrNull((r) => r.id == id);

  String get itemAsString => name.toTitle;

  /// Filter/search
  bool filterByAny(String filter) => true;

  @override
  List<Object?> get props => [
    id,
    fee,
    name,
    licenses,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
    expiresOn,
    effectiveFrom,
  ];

  /// ToList for PRODUCTS [itemAsList]
  List<String> get itemAsList => [
    id,
    '$fee',
    name.toTitle,
    getCreatedAt,
    createdBy.toTitle,
    updatedBy.toTitle,
    getUpdatedAt,
    getEffectiveFrom,
    getExpiresOn,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Fee',
    'Subscription',
    'Created At',
    'Created By',
    'Updated By',
    'Updated At',
    'Effective Date',
    'Expiry Date',
  ];
}
