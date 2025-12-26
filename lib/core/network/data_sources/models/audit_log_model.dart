// ------------------------------------
// ⚙️ Workflow Audit Entry Definitions
// ------------------------------------

import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';

/// [AuditAction] Tracks key workflow actions taken in the ERP system
enum AuditAction {
  unknown,
  draft,
  amended,
  pending,
  viewed,
  created,
  submitted,
  updated,
  approved,
  rejected,
  cancelled,
  assigned,
  sent,
  issued,
  commented,
  attached,
  delivered,
  received,
  completed,
  deleted,
  opened,
  closed,
  reopened,
  printed,
  underReview,
  acknowledged,
  partlyFulfilled,
  fulfilled,
  invoiced,
  paid,
  convertedToRFQ, // Converted to Request For Quotation
  convertedToPO, // Converted to Purchase Order
}

/* USAGE:
* final status = AuditEntry.created;
* print(status.label); // Output: created
* */
extension AuditActionExtension on AuditAction {
  /// [getName] Get the specific Enum Name (e.g. "convertedToRFQ")
  String get getName => EnumHelper<AuditAction>(this).getName;

  /// Returns a user-friendly label (e.g. "converted To RFQ")
  String get getLabel => EnumHelper<AuditAction>(this).getLabel;
}

class AuditActionHelper {
  /// Check if action is valid
  static bool isValid(String action) =>
      EnumHelper.isValid<AuditAction>(AuditAction.values, action, false);

  /// Returns true if the action is Approved
  static bool isApproved(String? action) =>
      EnumHelper.isEqual(AuditAction.approved, action);

  /// [fromString] Converts String/Label to enum value.
  static AuditAction fromString(String? value) =>
      EnumHelper.fromString<AuditAction>(AuditAction.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final list = EnumHelper.toStringList<AuditAction>(AuditAction.values);
    return includeHeader ? ['audit entry', ...list] : list;
  }
}

/// [AuditLog] Tracks key workflow/entry actions taken in the ERP System
class AuditLog {
  static get _today => DateTime.now();

  final String id;
  // e.g., 'created', 'approved', 'rejected', 'updated'
  final AuditAction action;
  final String actionBy;
  final DateTime actionAt;
  final String comment;
  // What is the document status immediately after this action?
  // The snapshot of the document status immediately after the action occurred
  final String? statusAfterAction;

  AuditLog({
    this.id = '',
    required this.action,
    required this.actionBy,
    DateTime? actionAt,
    this.comment = '',
    this.statusAfterAction,
  }) : actionAt = actionAt ?? _today;

  Map<String, dynamic> toMap() => {
    'action': getAction,
    'actionBy': actionBy,
    'actionAt': actionAt.toISOString,
    'comment': comment,
    'statusAfterAction': statusAfterAction,
  };

  factory AuditLog.fromMap(Map<String, dynamic> map, {String? id}) => AuditLog(
    id: id ?? map['id'] ?? '',
    action: AuditActionHelper.fromString(map['action']),
    actionBy: map['actionBy'] ?? '',
    actionAt: toDateTimeFn(map['actionAt'] ?? '$_today'),
    comment: map['comment'] ?? '',
    statusAfterAction: map['statusAfterAction'] ?? 'NA',
  );

  /// [auditLogs] Converts a list of maps from the provided [map] under the given [key] into a list of [AuditLog] objects.
  static List<AuditLog> auditLogs(List<dynamic>? map) {
    return map
            ?.map((i) => AuditLog.fromMap(Map<String, dynamic>.from(i)))
            .toList() ??
        [];
  }

  static Map<String, dynamic>? logScaffold({
    List<AuditLog> oldLogs = const [],
    required AuditLog newLog,
  }) => {
    'history': [
      ...oldLogs.map((e) => e.toMap()), // keep old logs
      newLog.toMap(), // new log
    ],
  };

  /// A singleton instance representing an empty/default AuditLog.
  /// Used as a fallback when no matching PR is found.
  static final AuditLog empty = AuditLog(
    action: AuditAction.unknown,
    actionBy: '',
  );

  /// Returns true if this instance is the singleton [empty] PR.
  /// Use this to check if the PR is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, AuditLog.empty);
  bool get isNotEmpty => !isEmpty;

  /// For UI display only
  String get getActionAt => actionAt.toStandardDT;
  String get getAction => action.getLabel;

  /// For UI display only
  List<String> get itemAsList => [
    getAction.toTitle,
    actionBy.toTitle,
    getActionAt,
    statusAfterAction.toTitle,
  ];

  /// For UI Header display only
  static List<String> get dataTableHeader => [
    'Activity',
    'Employee',
    'Date & Time',
    'Status After',
  ];
}

/// ------------------------------------
/// [AuditTracker] Prevent Duplicate Audit Logs Per Session
/// ------------------------------------
class AuditTracker {
  // Maps action → Set of unique "type/id::date" keys
  static final Map<AuditAction, Set<String>> _sessionMap = {};

  // Get current date in YYYY-MM-DD format
  static String get _getCurrentDate => DateTime.now().dateOnly;

  /// [shouldLog] Returns true if action should be logged for the given object type + id
  static bool shouldLog({
    required String id,
    required DocType type,
    AuditAction action = AuditAction.viewed,
  }) {
    final key =
        "${type.getName}::$id::$_getCurrentDate"; // namespace to avoid collisions

    // Ensure that the action is initialized in the map
    _sessionMap.putIfAbsent(action, () => <String>{});

    // If the key is already in the map, don't log again for this day
    if (_sessionMap[action]!.contains(key)) {
      return false; // Already logged for today
    }

    // Otherwise, log the action
    _sessionMap[action]!.add(key);
    return true; // Not logged yet for today, so allow logging
  }
}
