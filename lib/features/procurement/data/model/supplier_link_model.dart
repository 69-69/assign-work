import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/// Supplier Link Status
enum SupplierLinkStatus {
  invited, // RFQ has been sent to the supplier/vendor (Waiting for quotation)
  responded, // Supplier has submitted a quotation (Waiting for approval)
  declined, // Supplier explicitly declined the RFQ (Rejected)
}

extension SupplierLinkStatusExt on SupplierLinkStatus {
  /// [getName] Get the specific Enum Name
  String get getName => EnumUtil<SupplierLinkStatus>(this).getName;
}

/// [SupplierLink] Supplier Link model: for associating RFQ, PO and Invoice with Suppliers
class SupplierLink extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String quoteId; // RFQ ID
  final String supplierId;

  /// [supplierRepId] Supplier representative (Contact Person) ID
  final String? supplierRepId;
  final SupplierLinkStatus status; // invited, responded, declined
  final DateTime? invitedAt;
  final DateTime? respondedAt;

  SupplierLink({
    this.id = '',
    this.quoteId = '',
    required this.supplierId,
    this.supplierRepId,
    required this.status,
    DateTime? invitedAt,
    DateTime? respondedAt,
  }) : invitedAt = invitedAt ?? _today,
       respondedAt = respondedAt ?? _today;

  factory SupplierLink.fromMap(dynamic map, {String? id}) {
    final newMap = Map<String, dynamic>.from(map);

    return SupplierLink(
      id: id ?? newMap['id'] ?? '',
      quoteId: newMap['quoteId'] ?? '',
      supplierId: newMap['supplierId'] ?? '',
      supplierRepId: newMap['supplierRepId'] ?? '',
      status: fromString(newMap['status']),
      invitedAt: toDateTimeFn(newMap['invitedAt']),
      respondedAt: toDateTimeFn(newMap['respondedAt']),
    );
  }

  static List<SupplierLink> suppliers(List<dynamic>? map) {
    return map
            ?.map((i) => SupplierLink.fromMap(Map<String, dynamic>.from(i)))
            .toList() ??
        [];
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'quoteId': quoteId,
    'supplierId': supplierId,
    'supplierRepId': supplierRepId,
    'status': getStatus,
    'invitedAt': invitedAt.toISOString,
    'respondedAt': respondedAt.toISOString,
  };

  /// A singleton instance representing an empty/default RFQSupplier.
  /// Used as a fallback when no matching Supplier is found.
  static final empty = SupplierLink(
    quoteId: '',
    supplierId: '',
    status: SupplierLinkStatus.invited,
  );

  bool get isEmpty => identical(this, SupplierLink.empty);

  String get getStatus => status.getName;

  String get getInvitedAt => invitedAt.dateOnly;

  String get getRespondedAt => respondedAt.dateOnly;

  bool filterByAny(String filter) => {
    id,
    quoteId,
    supplierId,
    supplierRepId!,
    getStatus,
    getInvitedAt,
    getRespondedAt,
  }.filterAny(filter);

  SupplierLink copyWith({
    String? id,
    String? quoteId,
    String? supplierId,
    String? supplierRepId,
    SupplierLinkStatus? status,
    DateTime? invitedAt,
    DateTime? respondedAt,
  }) => SupplierLink(
    id: id ?? this.id,
    quoteId: quoteId ?? this.quoteId,
    supplierId: supplierId ?? this.supplierId,
    supplierRepId: supplierRepId ?? this.supplierRepId,
    status: status ?? this.status,
    invitedAt: invitedAt ?? this.invitedAt,
    respondedAt: respondedAt ?? this.respondedAt,
  );

  @override
  List<Object?> get props => [
    id,
    quoteId,
    supplierId,
    supplierRepId,
    status,
    invitedAt,
    respondedAt,
  ];

  /// [fromString] Converts String/Label to enum value.
  static SupplierLinkStatus fromString(String? value) =>
      EnumUtil.fromString<SupplierLinkStatus>(SupplierLinkStatus.values, value);

  /// [toStringList] Convert enum status list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final list = EnumUtil.toStringList<SupplierLinkStatus>(
      SupplierLinkStatus.values,
    );
    return includeHeader ? ['Supplier Status', ...list] : list;
  }
}
