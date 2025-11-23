// ------------------------------------
// ⚙️ Workflow Audit Entry Definitions
// ------------------------------------

import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';

/// [AuditAction] Tracks key workflow actions taken in the system
enum AuditAction {
  unknown,
  viewed,
  created,
  submitted,
  updated,
  approved,
  rejected,
  cancelled,
  assigned,
  sent,
  commented,
  attached,
  delivered,
  received,
  completed,
  deleted,
  reopened,
  printed,
  convertedToPO, // Converted Purchase Order
  convertedToRFQ, // Converted Request For Quote
}

/* USAGE:
* final status = AuditEntry.created;
* print(status.label); // Output: created
* */
extension AuditActionExtension on AuditAction {
  /// [getValue] Get the label for the specific enum value (e.g. "convertedToRFQ").
  String get getValue => EnumHelper<AuditAction>(this).getValue;

  /// Returns a user-friendly label (e.g. "converted To RFQ")
  String get getLabel => EnumHelper<AuditAction>(this).getLabel;
}

class AuditActionHelper {
  /// Check if action matches
  static bool isMatch(String action) =>
      EnumHelper.isValid<AuditAction>(AuditAction.values, action, false);

  /// [fromString] Converts String/Label to enum value.
  static AuditAction fromString(String? value) =>
      EnumHelper.fromString<AuditAction>(AuditAction.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final list = EnumHelper.toStringList<AuditAction>(AuditAction.values);
    return includeHeader ? ['audit entry', ...list] : list;
  }
}

/// [AuditLog] Tracks key workflow/entry actions taken on purchase requisition.
class AuditLog {
  static get _today => DateTime.now();

  // e.g., 'created', 'approved', 'rejected', 'updated'
  final AuditAction action;
  final String comment;
  final String performedBy;
  final DateTime performedAt;

  AuditLog({
    required this.action,
    required this.performedBy,
    DateTime? performedAt,
    this.comment = '',
  }) : performedAt = performedAt ?? _today;

  Map<String, dynamic> toMap() => {
    'action': getAction,
    'performedBy': performedBy,
    'performedAt': performedAt.toISOString,
    'comment': comment,
  };

  factory AuditLog.fromMap(Map<String, dynamic> map) => AuditLog(
    action: AuditActionHelper.fromString(map['action']),
    performedBy: map['performedBy'] ?? '',
    performedAt: toDateTimeFn(map['performedAt'] ?? '$_today'),
    comment: map['comment'] ?? '',
  );

  /// A singleton instance representing an empty/default AuditLog.
  /// Used as a fallback when no matching PR is found.
  static final AuditLog empty = AuditLog(
    action: AuditAction.unknown,
    performedBy: '',
  );

  /// Returns true if this instance is the singleton [empty] PR.
  /// Use this to check if the PR is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, AuditLog.empty);
  bool get isNotEmpty => !isEmpty;

  /// For UI display only
  String get getPerformedAt => performedAt.toStandardDT;
  String get getAction => action.getLabel;

  /// For UI display only
  List<String> get itemAsList => [
    getAction.toTitle,
    performedBy.toTitle,
    getPerformedAt,
  ];

  /// For UI Header display only
  static List<String> get dataTableHeader => [
    'Activity',
    'Employee',
    'Date & Time',
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
        "${type.getValue}::$id::$_getCurrentDate"; // namespace to avoid collisions

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
