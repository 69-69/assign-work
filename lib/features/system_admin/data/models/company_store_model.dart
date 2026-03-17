import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

class CompanyStore extends Equatable {
  static get _today => DateTime.now();

  final String id;

  /// [isPrimary] Primary store-branch created during initial workspace setup.
  /// This branch is associated with the `business owner` and `cannot be changed`.
  final bool isPrimary;
  final String storeNumber;
  final String name;
  final String phone;
  final String address;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final List<AuditLog> history;

  CompanyStore({
    this.id = '',
    this.isPrimary = false,
    required this.name,
    this.phone = '',
    required this.address,
    required this.storeNumber,
    this.notes,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? const [],
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [CompanyStore.fromMap]
  factory CompanyStore.fromMap(Map<String, dynamic> map, {String? id}) {
    return CompanyStore(
      id: id ?? map['id'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      notes: map['notes'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt']),
      history: AuditLog.auditLogs(map['history']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'isPrimary': isPrimary,
    'name': name,
    'phone': phone,
    'address': address,
    'storeNumber': storeNumber,
    'notes': notes,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'history': history.map((e) => e.toMap()).toList(),
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
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  /// Used as a fallback when no matching CompanyStores is found.
  static get empty => CompanyStore(
    id: '',
    name: '',
    phone: '',
    address: '',
    storeNumber: '',
    createdBy: '',
  );

  /// If its any other [store-branches], then it can be deleted.
  /// The [primary store] created during initial workspace creation `cannot be deleted`.
  bool get canBeDeleted => !isPrimary;

  bool get isEmpty => name.isEmpty || phone.isEmpty || address.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// Current / Today's Products/Stocks
  bool get isToday {
    var dt = createdAt.toDateTime;

    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  String get itemAsString => '$name - $storeNumber'.toTitle;

  /// Filter/Search
  bool filterByAny(String filter) => itemAsList.filterAny(filter);

  /// [findById]
  static CompanyStore? findById(List<CompanyStore> departs, String id) =>
      departs.firstWhereOrNull((d) => d.id == id);

  /// Extract all storeNumber from the list
  static List<String> getStoreNumbers(List<CompanyStore> stores) =>
      stores.map((s) => s.storeNumber).toList();

  /// copyWith method
  CompanyStore copyWith({
    String? id,
    bool? isPrimary,
    String? name,
    String? phone,
    String? address,
    String? storeNumber,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) {
    return CompanyStore(
      id: id ?? this.id,
      isPrimary: isPrimary ?? this.isPrimary,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      storeNumber: storeNumber ?? this.storeNumber,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [
    id,
    isPrimary,
    name,
    phone,
    address,
    storeNumber,
    notes,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
    history,
  ];

  List<String> get itemAsList => [
    id,
    storeNumber,
    isPrimary ? 'Yes' : 'No',
    name.toTitle,
    phone,
    address.toTitle,
    (notes ?? 'none').toTitle,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Store #',
    'Default',
    'Name',
    'Phone',
    'Address',
    'Notes',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

/// [createBusinessOwnerPrimaryBranch] Creates the primary store-branch for the business owner during
/// initial workspace setup (first-time tenant creation).
Map<String, dynamic> createBusinessOwnerPrimaryBranch({
  required String id,
  required String name,
  required String address,
}) {
  return CompanyStore(
    id: id,

    /// Primary branch associated with the business owner.
    /// This branch is created during workspace setup and cannot be changed.
    isPrimary: true,
    name: name,
    address: address,
    storeNumber: name.nextCode(),
    notes: 'Business headquarters',
    createdBy: 'system',
  ).toMap();
}
