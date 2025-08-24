import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

var _today = DateTime.now();

class Supplier extends Equatable {
  final String id;
  final String name;
  final String contactPersonName;
  final String phone;
  final String? email;
  final String address;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  /*class ProductSupplier {
  final String productId;
  final String supplierId; // foreign key to Procurement's Supplier
  final double price;
  // refers to the number of days it typically takes for a supplier to deliver an item from the moment a purchase order (PO) is placed until the goods arrive at your warehouse or facility.
  final int leadTimeDays;
  final bool isDefault;
}*/

  Supplier({
    this.id = '',
    required this.name,
    this.phone = '',
    this.email,
    required this.address,
    required this.contactPersonName,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [Supplier.fromMap]
  factory Supplier.fromMap(Map<String, dynamic> data, String documentId) {
    return Supplier(
      id: documentId,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      contactPersonName: data['contactPersonName'] ?? '',
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
    'phone': phone,
    'email': email,
    'address': address,
    'contactPersonName': contactPersonName,
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

  bool get isEmpty => id.isEmpty && (name.isEmpty || contactPersonName.isEmpty);

  bool get isNotEmpty => !isEmpty;

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

  String get itemAsString => name.toTitleCase;

  static get notFound => Supplier(
    name: 'no data',
    address: 'no data',
    contactPersonName: 'no data',
    createdBy: 'no data',
  );

  /// Filter Search
  bool filterByAny(String filter) =>
      id.contains(filter) ||
      name.contains(filter) ||
      phone.contains(filter) ||
      email!.contains(filter) ||
      contactPersonName.contains(filter) ||
      address.contains(filter);

  /// [findCategoriesById]
  static Iterable<Supplier> findCategoriesById(
    List<Supplier> suppliers,
    String id,
  ) => suppliers.where((d) => d.id == id);

  /// copyWith method
  Supplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? contactPersonName,
    String? email,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      contactPersonName: contactPersonName ?? this.contactPersonName,
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
    phone,
    address,
    contactPersonName,
    email,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for Items/Products-Supplier address [toListL]
  List<String> toListL() => [
    id,
    name.toTitleCase,
    contactPersonName.toTitleCase,
    phone,
    (email ?? 'none').toTitleCase,
    address.toTitleCase,
    createdBy.toTitleCase,
    getCreatedAt,
    updatedBy.toTitleCase,
    getUpdatedAt,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'Supplier Name',
    'Contact Person Name',
    'Phone',
    'Email',
    'Address / Location',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}
