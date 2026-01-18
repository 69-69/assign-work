import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

enum PriceListType { sales, purchase }

extension PriceListTypeExtension on PriceListType {
  String get getName => EnumUtil<PriceListType>(this).getName;
}

class PriceList extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String name;
  final PriceListType type; // determines if the lines are selling or purchase
  final String currencyCode;
  final DateTime? validFrom;
  final DateTime? validTo;
  final bool isActive;
  final String createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PriceList({
    required this.id,
    required this.name,
    required this.type,
    required this.currencyCode,
    this.validFrom,
    this.validTo,
    this.isActive = true,
    required this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory PriceList.fromJson(Map<String, dynamic> map, {String? id}) {
    return PriceList(
      id: id ?? map['id'] ?? '',
      name: map['name'],
      type: fromString(map['type']),
      currencyCode: map['currencyCode'],
      validFrom: toDateTimeFn(map['validFrom']),
      validTo: toDateTimeFn(map['validTo'], isNullable: true),
      isActive: map['isActive'] ?? true,
      createdBy: map['createdBy'],
      updatedBy: map['updatedBy'],
      createdAt: toDateTimeFn(map['createdAt']),
      updatedAt: toDateTimeFn(map['updatedAt']),
    );
  }

  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'name': name,
    'type': getType,
    'currencyCode': currencyCode,
    'isActive': isActive,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
  };

  String get getType => type.getName;

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['validFrom'] = validFrom?.toISOString;
    newMap['validTo'] = validTo?.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['validFrom'] = validFrom?.toMilliseconds;
    newMap['validTo'] = validTo?.toMilliseconds;
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    currencyCode,
    validFrom,
    validTo,
    isActive,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];

  /// [fromString] Converts String/Label to enum value.
  static PriceListType fromString(String? value) =>
      EnumUtil.fromString<PriceListType>(PriceListType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Price List type' : '';
    return EnumUtil.toStringList<PriceListType>(PriceListType.values, label);
  }
}

// PriceListLine Model (Price per Item)
class PriceListLine {
  final String id;
  final String priceListId;
  final String itemId; // (FK: ItemMaster.id)
  /// [price] If PriceList.type == PriceListType.sales, then price = selling price
  /// If PriceList.type == PriceListType.purchase, then price = purchase price
  final double price;
  final String uom; // needed for multiple Line Items
  final double? minQuantity;
  final double discountPercent;

  PriceListLine({
    required this.id,
    required this.priceListId,
    required this.itemId,
    required this.price,
    required this.uom,
    this.minQuantity,
    this.discountPercent = 0.0,
  });

  factory PriceListLine.fromJson(Map<String, dynamic> map, {String? id}) {
    return PriceListLine(
      id: id ?? map['id'] ?? '',
      priceListId: map['priceListId'],
      itemId: map['itemId'],
      price: (map['price'] as num).asDouble,
      uom: map['uom'],
      minQuantity: (map['minQuantity'] as num?).asDouble,
      discountPercent: (map['discountPercent'] as num).asDouble,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'priceListId': priceListId,
      'itemId': itemId,
      'price': price,
      'uom': uom,
      'minQuantity': minQuantity,
      'discountPercent': discountPercent,
    };
  }
}
