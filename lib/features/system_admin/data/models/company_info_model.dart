import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

class Company extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String name;
  final String email;
  final String phone;
  final String altPhone;
  final String address;
  final String faxNumber;
  final String? logo;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  Company({
    this.id = '',
    required this.name,
    required this.email,
    required this.phone,
    this.altPhone = '',
    required this.address,
    this.faxNumber = '',
    this.logo,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [CompanyInfo.fromMap]
  factory Company.fromMap(Map<String, dynamic> data, String documentId) {
    return Company(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      altPhone: data['altPhone'] ?? '',
      faxNumber: data['faxNumber'] ?? '',
      logo: data['logo'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: toDateTimeFn(data['createdAt']),
      updatedBy: data['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(data['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'altPhone': altPhone,
    'faxNumber': faxNumber,
    'logo': logo,
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

  bool get isEmpty => phone.isEmpty && name.isEmpty;

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

  static get notFound => Company(
    name: 'No Data',
    email: 'No Data',
    phone: 'No Data',
    address: 'No Data',
    createdBy: 'No Data',
  );

  /// copyWith method
  Company copyWith({
    String? id,
    String? phone,
    String? email,
    String? altPhone,
    String? name,
    String? address,
    String? logo,
    String? faxNumber,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      altPhone: altPhone ?? this.altPhone,
      faxNumber: faxNumber ?? this.faxNumber,
      logo: logo ?? this.logo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    phone,
    address,
    altPhone,
    email,
    name,
    faxNumber,
    logo,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for CompanyInfo [toListC]
  List<String> toListC() => [
    id,
    name.toTitle,
    phone,
    altPhone,
    email,
    address.toTitle,
    faxNumber,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'Name',
    'phone',
    'Alt Phone',
    'Email',
    'Address',
    'Fax',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}
