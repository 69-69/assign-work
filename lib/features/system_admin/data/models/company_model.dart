import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
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
  final List<AddressInfo> addresses;
  final String faxNumber;
  final String? logo;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  /// [history] Audit trail: track all changes made to the PR
  final List<AuditLog> history;

  Company({
    this.id = '',
    required this.name,
    required this.email,
    required this.phone,
    this.altPhone = '',
    required this.addresses,
    this.faxNumber = '',
    this.logo,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? [],
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [CompanyInfo.fromMap]
  factory Company.fromMap(Map<String, dynamic> map, {String? id}) {
    return Company(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      altPhone: map['altPhone'] ?? '',
      faxNumber: map['faxNumber'] ?? '',
      logo: map['logo'] ?? '',
      addresses: AddressInfo.addresses(map['addresses']),
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
    'email': email,
    'phone': phone,
    'altPhone': altPhone,
    'faxNumber': faxNumber,
    'logo': logo,
    'addresses': addresses.map((i) => i.toMap()).toList(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'history': history.map((i) => i.toMap()).toList(),
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

  /// A singleton instance representing an empty/default Company.
  /// Used as a fallback when no matching Company is found.
  static Company get empty => Company(
    name: '',
    email: '',
    phone: '',
    addresses: const [],
    createdBy: '',
  );

  /// [isEmpty] Checks if the PurchaseOrder is empty.
  bool get isEmpty => identical(this, Company.empty);

  bool get isNotEmpty => !isEmpty;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// copyWith method
  Company copyWith({
    String? id,
    String? phone,
    String? email,
    String? altPhone,
    String? name,
    String? logo,
    String? faxNumber,
    List<AddressInfo>? addresses,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      altPhone: altPhone ?? this.altPhone,
      faxNumber: faxNumber ?? this.faxNumber,
      logo: logo ?? this.logo,
      addresses: addresses ?? this.addresses,
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
    phone,
    altPhone,
    email,
    name,
    faxNumber,
    logo,
    addresses,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
    history,
  ];

  /// ToList for CompanyInfo [toListC]
  List<String> get itemAsList => [
    id,
    name.toTitle,
    phone,
    altPhone,
    email,
    faxNumber,
    addresses.first.address.toSentence,
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
    'Fax',
    'Address',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}
