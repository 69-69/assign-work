import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:equatable/equatable.dart';

final _today = DateTime.now();

class ErrorLog extends Equatable {
  final String? id;
  final String error;
  final String fileName;
  final DateTime dateTime;

  ErrorLog({
    required this.error,
    required this.fileName,
    String? id,
    DateTime? dateTime,
  }) : id = id ?? _today.millisecondsSinceEpoch.toString(),
       dateTime = dateTime ?? _today;

  /// Creates an [ErrorLog] instance from a map.
  factory ErrorLog.fromMap(Map<String, dynamic> map) => ErrorLog(
    id: map['id'] as String?,
    error: map['error'] as String,
    fileName: map['fileName'] as String,
    dateTime: toDateTimeFn(map['dateTime']),
  );

  /// Serializes the object into a map format for storage or transfer.
  Map<String, dynamic> toMap() => {
    'id': id,
    'error': error,
    'fileName': fileName,
    'dateTime': dateTime.toISOString,
  };

  /// toCache Function [toCache]
  /// Converts the log entry to a format suitable for caching.
  /// Wraps the entry under a key-value structure.
  Map<String, dynamic> toCache() {
    var map = toMap();
    map['dateTime'] = dateTime.millisecondsSinceEpoch;

    return {'id': id, 'data': map};
  }

  /// Table headers for UI or exports.
  static List<String> get dataTableHeader => const [
    'ID',
    'Error',
    'File Name',
    'Created At',
  ];

  /// ToList for Logs [itemAsList]
  List<String> get itemAsList => [id!, error, fileName, getErrorDate];

  /// [findLogsById]
  static Iterable<ErrorLog> findLogsById(List<ErrorLog> logs, String id) =>
      logs.where((d) => d.id == id);

  /// Formatted to Standard-DateTime in String [getErrorDate]
  String get getErrorDate => dateTime.toStandardDT;

  /// For comparing objects via Equatable.
  @override
  List<Object?> get props => [id, fileName, error, dateTime];

  /* Internal helper for date parsing.
  static DateTime _parseDate(dynamic value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? _now;
    return _now;
  }*/
}
