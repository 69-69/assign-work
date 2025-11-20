import 'package:assign_erp/core/util/enum_helper.dart';

enum DocType {
  work,
  item,
  order,
  purchase,
  misc,
  rfq,
  prs,
  sale,
  delivery,
  invoice,
  customer,
  pOrder,
  pSale,
  employee,
}

extension DocTypeExtension on DocType {
  /// For storage: "rfq", "sale", "pOrder"
  String get getValue => EnumHelper<DocType>(this).getValue;

  /// For UI labels: "RFQ", "Purchase Order", "Employee", etc.
  String get getLabel => EnumHelper<DocType>(this).getLabel;
}

class DocTypeHelper {
  static DocType fromString(String? value) =>
      EnumHelper.fromString<DocType>(DocType.values, value);
}
