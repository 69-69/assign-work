import 'package:assign_erp/core/constants/tax_context.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

class Tax extends Equatable {
  static get _today => DateTime.now();

  final String id;

  /// [isAutoApply] Determines if the system should auto-apply this tax to eligible transactions.
  final bool isAutoApply;

  /// [isWithholding] Indicates if this tax is a withholding tax,
  /// meaning it should be subtracted from the amount payable, not added.
  final bool isWithholding;

  /// [autoApplyOn] Entities or transaction types the tax applies to (e.g., pos, invoice, etc).
  final List<TaxContext> autoApplyOn;

  /// COVID-19 levy: 1% [covid]
  /// VAT is the Value Added levy: 15% [vat]
  /// National Health Insurance Levy: 2.5% [nHil]
  /// Tourism Development Fund levy: 1% [tourism]
  /// Ghana Education Trust Fund levy: 2.5% [getFund]
  final String name;

  /// Tax code
  final String code;
  final double rate;
  final String notes;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  Tax({
    this.id = '',
    this.isAutoApply = false,
    this.isWithholding = false,
    required this.name,
    required this.code,
    required this.rate,
    required this.notes,
    this.autoApplyOn = const [],
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [StoreLocation.fromMap]
  factory Tax.fromMap(Map<String, dynamic> map, {String? id}) {
    return Tax(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      isAutoApply: map['isAutoApply'] ?? false,
      isWithholding: map['isWithholding'] ?? false,
      autoApplyOn: TaxContextHelper.parseList(map['autoApplyOn']),
      rate: double.tryParse(map['rate']?.toString() ?? '0') ?? 0.0,
      notes: map['notes'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() {
    final strList = TaxContextHelper.toStringList(autoApplyOn);

    return {
      'id': id,
      'name': name,
      'code': code,
      'rate': rate,
      'notes': notes,
      'isAutoApply': isAutoApply,
      'isWithholding': isWithholding,
      'autoApplyOn': strList,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
    };
  }

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

  /// A singleton instance representing an empty/default Tax.
  /// Used as a fallback when no matching Tax is found.
  static final Tax empty = Tax(
    id: '',
    name: '',
    code: '',
    rate: 0.0,
    notes: '',
    createdBy: '',
  );

  /// Returns true if this instance is the singleton [empty] Tax.
  /// Use this to check if the Tax is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, Tax.empty);

  bool get isNotEmpty => !isEmpty;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  String get itemAsString => '$name - $rate';

  // @override
  // String toString() => '$name - $rate';
  bool shouldAutoApplyOn(TaxContext context) {
    return isAutoApply &&
        (autoApplyOn.contains(context) || autoApplyOn.contains(TaxContext.all));
  }

  /// Filter Search
  bool filterByAny(String filter) {
    // Split the filter into separate terms if it contains spaces
    final terms = filter.split(' ');

    // Check if any term matches any of the properties
    return terms.any(
      (term) =>
          id.contains(term) ||
          code.contains(term) ||
          name.contains(term) ||
          '$rate'.contains(term) ||
          notes.contains(term) ||
          createdBy.contains(term),
    );
  }

  /// [findById]
  static Tax? findById(List<Tax> departs, String id) =>
      departs.firstWhereOrNull((d) => d.id == id);

  /// copyWith method
  Tax copyWith({
    String? id,
    String? name,
    String? code,
    double? rate,
    String? notes,
    bool? isAutoApply,
    bool? isWithholding,
    List<TaxContext>? autoApplyOn,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) => Tax(
    id: id ?? this.id,
    name: name ?? this.name,
    code: code ?? this.code,
    rate: rate ?? this.rate,
    notes: notes ?? this.notes,
    isAutoApply: isAutoApply ?? this.isAutoApply,
    isWithholding: isWithholding ?? this.isWithholding,
    autoApplyOn: autoApplyOn ?? this.autoApplyOn,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedBy: updatedBy ?? this.updatedBy,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    rate,
    notes,
    isAutoApply,
    isWithholding,
    autoApplyOn,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for tax [toListT]
  List<String> toListT() => [
    id,
    name.toTitle,
    isWithholding ? 'Withholding Tax' : 'Standard Tax',
    code.toUpperAll,
    '$rate',
    isAutoApply ? 'Auto-Applied' : 'Manual',
    TaxContextHelper.toStringList(autoApplyOn).join(', ').separateWord.toTitle,
    notes.toSentence,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'Tax',
    'Tax type',
    'Code',
    'Rate %',
    'Auto Apply',
    'Auto Context',
    'Notes',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

/// Resolve Tax Code [ResolveTaxCode]: Get Tax Rate and Name by Tax Code
class ResolveTaxCode {
  final double rate;
  final String name;

  ResolveTaxCode({required this.rate, required this.name});

  String get taxLabel => '$name (${rate.toPercent}%)';
}

/// Tax Auto Apply Context [TaxOption]
class TaxOption {
  final String key;
  final bool selected;
  final dynamic data;

  TaxOption({required this.key, required this.selected, this.data});

  factory TaxOption.fromMap(Map<String, dynamic> map) {
    return TaxOption(
      key: map['key'] ?? '',
      selected: map['selected'] ?? false,
      data: map['data'],
    );
  }
}
