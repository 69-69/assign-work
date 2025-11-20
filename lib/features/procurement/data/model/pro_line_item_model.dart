import 'package:assign_erp/core/constants/item_category.dart';
import 'package:assign_erp/core/constants/unit_of_measure.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/// [ProLineItem] Represents an individual line item in Procurement
class ProLineItem extends Equatable {
  final int quantity;
  final String itemName;
  final ItemCategory category;
  final UnitOfMeasure unitOfMeasure;
  final String notes;

  const ProLineItem({
    required this.itemName,
    required this.quantity,
    this.category = ItemCategory.unknown,
    this.unitOfMeasure = UnitOfMeasure.unknown,
    this.notes = '',
  });

  factory ProLineItem.fromMap(Map<String, dynamic> map) {
    return ProLineItem(
      itemName: map['itemName'] ?? '',
      quantity: int.tryParse('${map['quantity']}') ?? 0,
      category: ItemCategoryHelper.fromString(map['category']),
      unitOfMeasure: UOMHelper.fromString(map['unitOfMeasure']),
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'itemName': itemName,
    'quantity': quantity,
    'category': getCategory,
    'unitOfMeasure': getUnitOfMeasure,
    'notes': notes,
  };

  bool filterByAny(String filter) =>
      itemName.contains(filter) || notes.contains(filter);

  ProLineItem copyWith({
    String? itemName,
    int? quantity,
    String? notes,
    ItemCategory? category,
    UnitOfMeasure? unitOfMeasure,
  }) => ProLineItem(
    itemName: itemName ?? this.itemName,
    quantity: quantity ?? this.quantity,
    notes: notes ?? this.notes,
    category: category ?? this.category,
    unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
  );

  /// A singleton instance representing an empty/default ProLineItem.
  /// Used as a fallback when no matching PR is found.
  static final ProLineItem empty = ProLineItem(itemName: '', quantity: 0);

  /// Returns true if this instance is the singleton [empty] PR.
  /// Use this to check if the PR is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, ProLineItem.empty);

  bool get isNotEmpty => itemName.isNotEmpty;

  String get getCategory => category.getLabel;

  String get getUnitOfMeasure => unitOfMeasure.getLabel;

  List<String> get itemAsList => [
    itemName.toTitle,
    '$quantity',
    getCategory.toTitle,
    getUnitOfMeasure.toTitle,
    notes.toSentence,
  ];

  /// For UI Header display only
  static List<String> get dataTableHeader => const [
    'Item',
    'Qty',
    'Category',
    'Unit Of Measure',
    'Notes',
  ];

  @override
  List<Object?> get props => [
    itemName,
    quantity,
    category,
    unitOfMeasure,
    notes,
  ];
}
