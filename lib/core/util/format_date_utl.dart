import 'package:assign_erp/core/util/str_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

final _today = DateTime.now();

extension ConvertDateTime on dynamic {
  ({String filename, String id}) get generateBackupFileName {
    final formattedDate = DateFormat('yyyy-MM-dd').format(_today);
    return (filename: '$this-$formattedDate', id: _today.toISOString);
  }

  /// Convert microsecondsSinceEpoch to DateTime object [toStandardDT]
  String get toStandardDT {
    if (this == null || this == "" || this == "null" || this == "null null") {
      return '0000-00-00 00:00:00.000';
    }

    DateTime dateTime = toDateTime;

    // Format the DateTime object using a standard date time format
    // DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    DateFormat formatter = DateFormat.yMEd().add_jms();

    // Return the formatted date time string
    return formatter.format(dateTime);
  }

  /// Convert microsecondsSinceEpoch to DateTime object [dateOnly]
  String get dateOnly {
    if (this == null || this == "" || this == "null" || this == "null null") {
      return '0000-00-00';
    }

    // Return the formatted date time string
    // return DateFormat('yyyy-MM-dd').format(this);
    var dt = this is String ? toDateTimeFn(this) : this;
    return DateFormat.yMEd().format(dt);
  }

  /// Get time only from datetime: Fri, 8/8/2025 12:54:30
  /// Convert microsecondsSinceEpoch to DateTime object [timeOnly]
  String get timeOnly {
    if (this == null || this == "" || this == "null" || this == "null null") {
      return '00:00:00';
    }
    var dt = this is String ? toDateTimeFn(this) : this;
    return DateFormat.jm().format(dt);
  }

  /// Convert DateTime object to microsecondsSinceEpoch String [toISOString]
  String get toISOString {
    if (this == null || this == "" || this == "null" || this == "null null") {
      return '';
    }

    DateTime dateTime = toDateTime;

    // Return the formatted date time string
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    ).toIso8601String();
  }

  /// To DateTime format [toDateTime]
  DateTime get toDateTime => toDateTimeFn(this);

  /*
  /// MillisecondsSinceEpoch To DateTime format [toDateTime]
  DateTime get fromMillisecondsSinceEpoch => this is DateTime
      ? this
      : DateTime.fromMillisecondsSinceEpoch(int.parse(this));
  */

  /// Convert DateTime to Timestamp [fromDate]
  Timestamp? get fromDate => this != null ? Timestamp.fromDate(this) : null;

  /// Convert Timestamp to DateTime [toDate]
  DateTime? get fromTimestamp =>
      this != null ? (this as Timestamp).toDate() : null;

  String get chatDatetime {
    final diff = _today.difference(this);

    // Format date as "Month Day, Year"
    if (diff.inDays > 0) {
      final localDate = this.toLocal();
      return DateFormat('MMMM dd, yyyy').format(localDate);
    } else {
      final hour = this.hour % 12;
      final minute = this.minute.toString().padLeft(2, '0');
      final amPm = this.hour >= 12 ? 'PM' : 'AM';
      return '${hour == 0 ? 12 : hour}:$minute $amPm';
    }
  }
}

extension TotalDaysFromDate on DateTime? {
  /// To calculate the number of days from the current date to a specific future date [toDays]
  int get toDays {
    if (this == null) {
      return 0;
    }

    // Future date (12/24/2024 in this example)
    DateTime futureDate = this ?? DateTime(0000, 00, 00);

    // Calculate the difference
    Duration difference = futureDate.difference(_today);

    // Get the number of days from the duration
    int daysDifference = difference.inDays;

    return daysDifference;
  }
}

extension DateFromTotalDays on int {
  /// Converts number of days from today into a DateTime
  /// Positive = future date, Negative = past date [toDate]
  DateTime get toDate => DateTime.now().add(Duration(days: this));
}

DateTime toDateTimeFn(dateTime) {
  if ('$dateTime'.trim().isNullOrEmpty) {
    return _today;
  }
  // If is int else string
  if (dateTime is DateTime) return dateTime;
  if (dateTime is Timestamp) return dateTime.toDate();
  if (dateTime is int) return DateTime.fromMillisecondsSinceEpoch(dateTime);
  if (dateTime is String) {
    try {
      return DateTime.parse(dateTime);
    } catch (_) {
      return DateTime.now(); // fallback on parse error
    }
  }
  return _today;
}
