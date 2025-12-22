import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/*class ContactInfo {
  final String name;
  final String email;
  final String phone;
  final String altPhone;
  final String fax;
}*/
/// ContactPerson Class [ContactPerson]
class ContactPerson extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String position;
  final DateTime createdAt;

  ContactPerson({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.department = '',
    this.position = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? _today;

  factory ContactPerson.fromMap(Map<String, dynamic> data, {String? id}) {
    return ContactPerson(
      id: id ?? data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      department: data['department'] ?? '',
      position: data['position'] ?? '',
      createdAt: toDateTimeFn(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'department': department,
    'position': position,
    'createdAt': createdAt.toISOString,
  };

  ContactPerson copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? position,
    DateTime? createdAt,
  }) => ContactPerson(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    department: department ?? this.department,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
  );

  static empty({String? name}) => ContactPerson(
    id: '',
    name: name ?? '',
    email: '',
    phone: '',
    department: '',
    position: '',
  );

  bool get isEmpty => identical(this, ContactPerson.empty);

  bool get isNotEmpty => !isEmpty;

  String get itemAsString => name.toTitle;

  String get getCreatedAt => createdAt.toStandardDT;

  bool filterByAny(String filter) =>
      id.contains(filter) ||
      name.contains(filter) ||
      email.contains(filter) ||
      phone.contains(filter) ||
      department.contains(filter) ||
      position.contains(filter);

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    department,
    position,
    createdAt,
  ];

  static List<String> get dataTableHeader => const [
    'Name',
    'Email',
    'Phone',
    'Department',
    'Position',
    'Created At',
  ];

  List<String> get itemAsList => [
    name.toTitle,
    email.toLowerAll,
    phone,
    department.toTitle,
    position.toTitle,
    createdAt.toStandardDT,
  ];
}
