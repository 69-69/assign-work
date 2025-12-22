import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

enum AddressType { billing, shipping, warehouse, office }

extension AddressTypeExtension on AddressType {
  /// [getName] Get the specific Enum Name (e.g. "material")
  String get getName => EnumHelper<AddressType>(this).getName;
}

/// Address Class [Address]
class AddressInfo extends Equatable {
  final String id;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  // final AddressType type;

  const AddressInfo({
    this.id = '',
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
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
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
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
    };

    return map.cleaned;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() => {'id': id, 'data': toMap()};

  /// A singleton instance representing an empty/default Address.
  /// Used as a fallback when no matching Address is found.
  static AddressInfo get empty =>
      AddressInfo(address: '', city: '', state: '', postalCode: '');

  /// [isEmpty] Checks if the PurchaseOrder is empty.
  bool get isEmpty => identical(this, AddressInfo.empty);

  bool get isNotEmpty => !isEmpty;

  /// copyWith method
  AddressInfo copyWith({
    String? id,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) {
    return AddressInfo(
      id: id ?? this.id,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
    );
  }

  @override
  List<Object?> get props => [id, address, city, state, country, postalCode];

  List<String> get itemAsList => [
    id,
    address,
    city,
    state,
    country,
    postalCode,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'Address',
    'City',
    'State',
    'Country',
    'Postal Code',
  ];

  /// [fromString] Converts String/Label to enum value.
  static AddressType fromString(String? value) =>
      EnumHelper.fromString<AddressType>(AddressType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Address type' : '';
    return EnumHelper.toStringList<AddressType>(AddressType.values, label);
  }
}
