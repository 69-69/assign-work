import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/*class ProductSupplier {
  final String productId;
  final String supplierId; // foreign key to Procurement's Supplier
  final double price;
  // refers to the number of days it typically takes for a supplier to deliver an item from the moment a purchase order (PO) is placed until the goods arrive at your warehouse or facility.
  final int leadTimeDays;
  final bool isDefault;
}*/

class Supplier extends Equatable {
  static get _today => DateTime.now();

  final String id;

  /// [name] Supplier Company Name
  final String name;
  final String phone;
  final String? email;
  final String address;

  /// Supplier Code
  final String code;
  final String businessType;
  final String? bankDetails;
  final String? taxDetails;

  /// [items] Products or Services that supplier/vendor supplies
  final String items;
  final List<SupplierContactPerson> contactPersons;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  Supplier({
    this.id = '',
    required this.name,
    required this.phone,
    required this.code,
    this.email,
    required this.address,
    required this.businessType,
    this.bankDetails,
    this.taxDetails,
    required this.items,
    required this.contactPersons,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [Supplier.fromMap]
  factory Supplier.fromMap(Map<String, dynamic> map, {String? id}) {
    return Supplier(
      id: id ?? map['id'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      items: map['items'] ?? '',
      businessType: map['businessType'] ?? '',
      bankDetails: map['bankDetails'] ?? '',
      taxDetails: map['taxDetails'] ?? '',
      contactPersons:
          (map['contactPersons'] as List<dynamic>?)
              ?.map(
                (i) =>
                    SupplierContactPerson.fromMap(Map<String, dynamic>.from(i)),
              )
              .toList() ??
          [],
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'code': code,
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'items': items,
    'businessType': businessType,
    'bankDetails': bankDetails,
    'taxDetails': taxDetails,
    'contactPersons': contactPersons.map((i) => i.toMap()).toList(),
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

  /// A singleton instance representing an empty/default Supplier.
  /// Used as a fallback when no matching Supplier is found.
  static get empty => Supplier(
    id: '',
    code: '',
    name: '',
    phone: '',
    address: '',
    items: '',
    businessType: '',
    contactPersons: const [],
    createdBy: '',
  );

  /// Returns true if this instance is the singleton [empty] Supplier.
  /// Use this to check if the Supplier is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, Supplier.empty);

  bool get isNotEmpty => !isEmpty;

  get _parts => businessType.split(' - '); // business - industry
  /// Business Type: Manufacturer, Distributor, Wholesaler, Retailer
  String get getBusinessType => _parts.first;

  /// Industry Type: Telecommunication, Clothing, Electronics, Furniture
  String get getIndustryType => _parts.last;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// Current / Today's Products/Items/Stocks
  bool get isToday {
    var dt = createdAt.toDateTime;

    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  String get itemAsString => name.toTitle;

  /// Filter Search
  bool filterByAny(String filter) =>
      id.contains(filter) ||
      code.contains(filter) ||
      name.contains(filter) ||
      phone.contains(filter) ||
      email!.contains(filter) ||
      address.contains(filter) ||
      items.contains(filter) ||
      businessType.contains(filter) ||
      bankDetails!.contains(filter) ||
      taxDetails!.contains(filter) ||
      contactPersons.any((e) => e.filterByAny(filter));

  /// [findById]
  static Supplier findById(List<Supplier> suppliers, String id) =>
      suppliers.firstWhere((s) => s.id == id, orElse: () => Supplier.empty);

  /// copyWith method
  Supplier copyWith({
    String? id,
    String? name,
    String? code,
    String? phone,
    String? address,
    String? items,
    String? businessType,
    String? bankDetails,
    String? taxDetails,
    List<SupplierContactPerson>? contactPersons,
    String? email,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      items: items ?? this.items,
      address: address ?? this.address,
      businessType: businessType ?? this.businessType,
      bankDetails: bankDetails ?? this.bankDetails,
      taxDetails: taxDetails ?? this.taxDetails,
      contactPersons: contactPersons ?? this.contactPersons,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    phone,
    email,
    address,
    businessType,
    bankDetails,
    taxDetails,
    contactPersons,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for Items/Products-Supplier address [toListL]
  List<String> toListL() => [
    id,
    name.toTitle,
    phone,
    (email ?? 'none').toLowerAll,
    address.toSentence,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'Supplier',
    'Phone',
    'Email',
    'Address',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

/// RFQ Line Items
class SupplierContactPerson extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String position;
  final DateTime createdAt;

  SupplierContactPerson({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.position,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? _today;

  factory SupplierContactPerson.fromMap(
    Map<String, dynamic> data, {
    String? id,
  }) {
    return SupplierContactPerson(
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

  SupplierContactPerson copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? position,
    DateTime? createdAt,
  }) => SupplierContactPerson(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    department: department ?? this.department,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
  );

  static empty({String? name}) => SupplierContactPerson(
    id: '',
    name: '',
    email: '',
    phone: '',
    department: '',
    position: '',
  );

  bool get isEmpty => identical(this, SupplierContactPerson.empty);

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
