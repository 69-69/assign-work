import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

enum AddressType { billing, shipping, warehouse, office }

extension AddressTypeExtension on AddressType {
  /// [getName] Get the specific Enum Name (e.g. "material")
  String get getName => EnumHelper<AddressType>(this).getName;

  // if same
  bool get isBilling => this == AddressType.billing;
  bool get isShipping => this == AddressType.shipping;
  bool get isWarehouse => this == AddressType.warehouse;
  bool get isOffice => this == AddressType.office;
}

/// Address Class [Address]
class AddressInfo extends Equatable {
  final String id;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final AddressType type;

  const AddressInfo({
    this.id = '',
    required this.type,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = '',
  }); // Set default value

  /// fromFirestore / fromJson Function [AddressInfo.fromMap]
  factory AddressInfo.fromMap(Map<String, dynamic> map, {String? id}) {
    return AddressInfo(
      id: id ?? map['id'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
      type: fromString(map['type']),
      address: map['address'] ?? '',
    );
  }

  /// [addresses] Converts a list of maps from the provided [map] under the given [key] into a list of [Address] objects.
  static List<AddressInfo> addresses(List<dynamic>? map) {
    return map
            ?.map((i) => AddressInfo.fromMap(Map<String, dynamic>.from(i)))
            .toList() ??
        [];
  }

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'address': address,
      'type': getType,
    };

    return map.cleaned;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() => {'id': id, 'data': toMap()};

  /// A singleton instance representing an empty/default Address.
  /// Used as a fallback when no matching Address is found.
  static AddressInfo get empty => AddressInfo(
    address: '',
    city: '',
    state: '',
    postalCode: '',
    type: AddressType.office,
  );

  /// [isEmpty] Checks if the PurchaseOrder is empty.
  bool get isEmpty => identical(this, AddressInfo.empty);

  bool get isNotEmpty => !isEmpty;

  String get getType => type.getName;

  /// copyWith method
  AddressInfo copyWith({
    String? id,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? address,
    AddressType? type,
  }) {
    return AddressInfo(
      id: id ?? this.id,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      address: address ?? this.address,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
    id,
    city,
    state,
    country,
    postalCode,
    type,
    address,
  ];

  List<String> get itemAsList => [
    id,
    getType,
    address,
    city,
    state,
    country,
    postalCode,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'City',
    'State',
    'Country',
    'Postal Code',
    'Type',
    'Address',
  ];

  bool filterByAny(String query) =>
      itemAsList.any((item) => item.contains(query));

  /// [fromString] Converts String/Label to enum value.
  static AddressType fromString(String? value) =>
      EnumHelper.fromString<AddressType>(AddressType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Address type' : '';
    return EnumHelper.toStringList<AddressType>(AddressType.values, label);
  }
}
