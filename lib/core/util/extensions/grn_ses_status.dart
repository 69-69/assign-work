// -------------------------------------------------------
// ⚙ Goods Receipt (GRN) and Service Entry Sheet (SES) Status
// -------------------------------------------------------

import 'package:assign_erp/core/util/enum_util.dart';

/// Unified status enum for GRN & SES.
/// NOTE:
/// - GRN uses: draft, posted, rejected
/// - SES uses: draft, submitted, approved, rejected
enum GRNSESStatus {
  draft,
  posted, // Only for GRN
  submitted, // Only for SES
  approved, // Only for SES
  rejected,
}

extension GRNSESStatusExtension on GRNSESStatus {
  /// [getName] Get the specific Enum Name
  String get getName => EnumUtil<GRNSESStatus>(this).getName;
  String get getLabel => EnumUtil<GRNSESStatus>(this).getLabel;

  /// Returns true if this status is valid for a GRN document
  bool get isGRNStatus =>
      this == GRNSESStatus.draft ||
      this == GRNSESStatus.posted ||
      this == GRNSESStatus.rejected;

  /// Returns true if this status is valid for a SES document
  bool get isSESStatus =>
      this == GRNSESStatus.draft ||
      this == GRNSESStatus.submitted ||
      this == GRNSESStatus.approved ||
      this == GRNSESStatus.rejected;
}

class GRNSESStatusUtil {
  static GRNSESStatus fromString(String? value) =>
      EnumUtil.fromString<GRNSESStatus>(GRNSESStatus.values, value);

  static List<String> toStringList([bool includeHeader = true]) {
    final list = EnumUtil.toStringList<GRNSESStatus>(GRNSESStatus.values);
    return includeHeader ? ['status', ...list] : list;
  }
}
