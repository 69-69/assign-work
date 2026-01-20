import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

enum AddressType { billing, shipping, warehouse, office }

extension AddressTypeExtension on AddressType {
  /// [getName] Get the specific Enum Name (e.g. "material")
  String get getName => EnumUtil<AddressType>(this).getName;

  // if same
  bool get isBilling => this == AddressType.billing;
  bool get isShipping => this == AddressType.shipping;
  bool get isWarehouse => this == AddressType.warehouse;
  bool get isOffice => this == AddressType.office;
}

class AddressTypeUtil {
  /// [fromString] Converts String/Label to enum value.
  static AddressType fromString(String? value) =>
      EnumUtil.fromString<AddressType>(AddressType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Address type' : '';
    return EnumUtil.toStringList<AddressType>(AddressType.values, label);
  }
}

/// Address Class [Address]
class AddressInfo extends Equatable {
  final String id;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final AddressType type;

  const AddressInfo({
    this.id = '',
    required this.type,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = '',
  });

  /// fromFirestore / fromJson Function [AddressInfo.fromMap]
  factory AddressInfo.fromMap(Map<String, dynamic> map, {String? id}) {
    return AddressInfo(
      id: id ?? map['id'] ?? '',
      type: AddressTypeUtil.fromString(map['type']),
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
      street: map['street'] ?? '',
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
      'street': street,
      'type': getType,
    };

    return map.cleaned;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() => {'id': id, 'data': toMap()};

  /// A singleton instance representing an empty/default Address.
  /// Used as a fallback when no matching Address is found.
  static AddressInfo get empty => AddressInfo(
    street: '',
    city: '',
    state: '',
    postalCode: '',
    type: AddressType.office,
  );

  /// [isEmpty] Checks if the Address is empty.
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
    String? street,
    AddressType? type,
  }) {
    return AddressInfo(
      id: id ?? this.id,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      street: street ?? this.street,
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
    street,
  ];

  List<String> get itemAsList => [
    id,
    getType,
    street,
    city,
    state,
    country,
    postalCode,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'Type',
    'City',
    'State',
    'Street',
    'Postal Code',
    'Country',
  ];

  bool filterByAny(String keyword) => itemAsList.filterAny(keyword);
}
