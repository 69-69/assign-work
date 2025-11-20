import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  static get _today => DateTime.now();

  final String id; // Firestore will assign a unique ID (documentId)
  final String storeNumber;
  final String customerId;
  final String name;
  final String phone;
  final String altPhone;
  final String email;
  final String address;
  final String companyName;
  final DateTime? birthDay;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  Customer({
    this.id = '',
    required this.storeNumber,
    required this.customerId,
    required this.name,
    required this.phone,
    this.altPhone = '',
    this.address = '',
    this.email = '',
    this.companyName = '',
    DateTime? birthDay,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       birthDay = birthDay ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [Customer.fromMap]
  factory Customer.fromMap(Map<String, dynamic> data, String documentId) {
    return Customer(
      id: documentId,
      storeNumber: data['storeNumber'] ?? '',
      customerId: data['customerId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      altPhone: data['altPhone'] ?? '',
      address: data['address'] ?? '',
      email: data['email'] ?? '',
      companyName: data['companyName'] ?? '',
      birthDay: toDateTimeFn(data['birthDay']),
      createdBy: data['createdBy'] ?? '',
      createdAt: toDateTimeFn(data['createdAt']),
      updatedBy: data['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(data['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'customerId': customerId,
    'name': name,
    'phone': phone,
    'altPhone': altPhone,
    'email': email,
    'address': address,
    'companyName': companyName,
    'birthDay': birthDay,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
  };

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['birthDay'] = birthDay?.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['birthDay'] = birthDay?.millisecondsSinceEpoch;
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;
    newMap['updatedAt'] = updatedAt.millisecondsSinceEpoch;

    return {'id': id, 'data': newMap};
  }

  bool get isEmpty => customerId.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Date Only in String [getBirthDay]
  String get getBirthDay => birthDay.dateOnly;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// Current / Today's Customers
  bool get isToday {
    var dt = createdAt.toDateTime;

    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  static get notFound => Customer(
    customerId: '',
    storeNumber: 'No Data',
    name: 'No Data',
    phone: 'No Data',
    createdBy: 'No Data',
  );

  String get itemAsString => name.contains(autoID)
      ? name.toUpperAll
      : isEmpty
      ? 'No Data'
      : '$name - $customerId'.toTitle;

  /// [findCustomerById]
  static Iterable<Customer> findCustomerById(
    List<Customer> customers,
    String customerId,
  ) => customers.where((customer) => customer.customerId == customerId);

  /// [filterCustomersByDate]
  static List<Customer> filterCustomersByDate(
    List<Customer> customers, {
    bool isSameDay = true,
  }) {
    // If customer-name isNotEqual Auto-ID, & isToday or not isToday
    return customers
        .where(
          (c) =>
              !c.name.contains(autoID) && (isSameDay ? c.isToday : !c.isToday),
        )
        .toList();
  }

  /// Filter
  bool filterByAny(String filter) =>
      name.contains(filter) ||
      storeNumber.contains(filter) ||
      customerId.contains(filter) ||
      phone.contains(filter) ||
      altPhone.contains(filter) ||
      email.contains(filter) ||
      companyName.contains(filter);

  /// copyWith method
  Customer copyWith({
    String? id,
    String? storeNumber,
    String? name,
    String? phone,
    String? altPhone,
    String? email,
    String? address,
    String? companyName,
    DateTime? birthDay,
    String? customerId,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      storeNumber: storeNumber ?? this.storeNumber,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      altPhone: altPhone ?? this.altPhone,
      email: email ?? this.email,
      address: address ?? this.address,
      birthDay: birthDay ?? this.birthDay,
      companyName: companyName ?? this.companyName,
      customerId: customerId ?? this.customerId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    storeNumber,
    name,
    phone,
    altPhone,
    email,
    address,
    companyName,
    customerId,
    birthDay,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for Customers [itemAsList]
  List<String> itemAsList() => [
    id,
    customerId,
    storeNumber,
    name.toTitle,
    phone,
    altPhone,
    email,
    getBirthDay,
    address.toTitle,
    companyName.toTitle,
    createdBy.toTitle,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Customer ID',
    'Store Number',
    'Name',
    'Phone',
    'Alt-Phone',
    'Email',
    'Birth day',
    'Address / Location',
    'Company Name',
    'Created By',
    'Updated By',
    'Updated At',
  ];
}
