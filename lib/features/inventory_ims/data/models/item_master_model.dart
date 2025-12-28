import 'package:equatable/equatable.dart';

/// Central definition of all stockable, sellable, and purchasable items
class ItemMaster extends Equatable {
  /// 1. Identification
  final String id; // UUID
  final String sku; // Unique stock keeping unit
  final String name; // Product / Item name
  final String description; // Optional detailed description

  /// 2. Categorization
  final String categoryId; // FK to ItemCategory
  final String categoryName; // Denormalized for reporting

  /// 3. Unit of Measure
  final String uom; // Base unit (pcs, kg, liter, etc.)
  final double? conversionFactor; // Optional: for alternate units

  /// 4. Pricing & Cost
  final double purchasePrice; // Cost for procurement
  final double sellingPrice; // Standard selling price
  final double? taxRate; // Tax percentage applicable

  /// 5. Barcodes / Identifiers
  final List<String> barcodes; // Optional multiple barcodes
  final String? externalId; // Optional external system reference

  /// 6. Variants
  final Map<String, String> variants; // e.g., {"Size": "L", "Color": "Red"}

  /// 7. Inventory tracking flags
  final bool isActive; // Active / inactive for sales

  /// 8. Audit / System
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  ItemMaster({
    required this.id,
    required this.sku,
    required this.name,
    this.description = '',
    required this.categoryId,
    this.categoryName = '',
    required this.uom,
    this.conversionFactor,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.taxRate,
    this.barcodes = const [],
    this.externalId,
    this.variants = const {},
    this.isActive = true,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Deserialize from Map / JSON
  factory ItemMaster.fromMap(Map<String, dynamic> map) {
    return ItemMaster(
      id: map['id'] ?? '',
      sku: map['sku'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      uom: map['uom'] ?? 'pcs',
      conversionFactor: map['conversionFactor']?.toDouble(),
      purchasePrice: map['purchasePrice']?.toDouble() ?? 0.0,
      sellingPrice: map['sellingPrice']?.toDouble() ?? 0.0,
      taxRate: map['taxRate']?.toDouble(),
      barcodes: List<String>.from(map['barcodes'] ?? []),
      externalId: map['externalId'],
      variants: Map<String, String>.from(map['variants'] ?? {}),
      isActive: map['isActive'] ?? true,
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Serialize to Map / JSON
  Map<String, dynamic> toMap() => {
    'id': id,
    'sku': sku,
    'name': name,
    'description': description,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'uom': uom,
    'conversionFactor': conversionFactor,
    'purchasePrice': purchasePrice,
    'sellingPrice': sellingPrice,
    'taxRate': taxRate,
    'barcodes': barcodes,
    'externalId': externalId,
    'variants': variants,
    'isActive': isActive,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedBy': updatedBy,
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    sku,
    name,
    categoryId,
    uom,
    purchasePrice,
    sellingPrice,
    taxRate,
    barcodes,
    variants,
    isActive,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];
}
