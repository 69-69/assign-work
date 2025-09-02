import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _today = DateTime.now();

class Attendance {
  final String id;

  /// [type] attendance type (sign in/out)
  final String type;

  /// [userId] employee/workspace ID
  final String userId;

  /// [name] employee/workspace name
  final String name;
  final String? ip;
  final String? city;
  final String? region;
  final GeoPoint? location;
  final DateTime createdAt;

  /// [areasViewed] list of areas viewed by employee/workspace
  final List<String> areasViewed;

  Attendance({
    this.id = '',
    required this.type,
    required this.userId,
    required this.name,
    this.ip,
    this.city,
    this.region,
    this.areasViewed = const [],
    this.location,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? _today;

  static const String cacheKey = 'log_attendance';

  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'type': type,
    'userId': userId,
    'name': name,
    'ip': ip,
    'city': city,
    'region': region,
    'areasViewed': areasViewed,
    'createdAt': _today,
    'location': location != null
        ? {'latitude': location!.latitude, 'longitude': location!.longitude}
        : null,
  };

  factory Attendance.fromMap(Map<String, dynamic> map, {String? id}) {
    final loc = map['location'];

    return Attendance(
      id: (id ?? map['id']) ?? '',
      type: map['type'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'employee',
      ip: map['ip'] ?? '',
      city: map['city'] ?? '',
      region: map['region'] ?? '',
      areasViewed: List<String>.from(map['areasViewed'] ?? []),
      createdAt: toDateTimeFn(map['createdAt']),
      location:
          loc != null && loc['latitude'] != null && loc['longitude'] != null
          ? GeoPoint(loc['latitude'], loc['longitude'])
          : null,
    );
  }

  /// Convert Attendance to a map for storing in Firestore [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toISOString;

    return newMap;
  }

  /// Convert Attendance to toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;

    return {'id': cacheKey, 'data': newMap};
  }

  static Attendance findById(List<Attendance> attendances, String id) =>
      attendances.firstWhere((attendance) => attendance.id == id);

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  List<String> itemAsList() => [
    id,
    userId,
    type.toTitle,
    name.toTitle,
    ip ?? '',
    city ?? '',
    region ?? '',
    // areasViewed.join(', '),
    getCreatedAt,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Employee id',
    'Type',
    'Name',
    'IP',
    'City',
    'Region',
    // 'areas viewed',
    'Created at',
  ];
}
