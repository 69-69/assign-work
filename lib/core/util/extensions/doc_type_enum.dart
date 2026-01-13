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
  sQuote,
  delivery,
  invoice,
  customer,
  pOrder,
  pSale,
  employee,
}

extension DocTypeExtension on DocType {
  /// [getName] Get the specific Enum Name (e.g. "pOrder")
  String get getName => EnumHelper<DocType>(this).getName;

  /// For UI labels: 'pOrder' -> 'P Order'
  String get getLabel => EnumHelper<DocType>(this).getLabel;
}

class DocTypeHelper {
  static DocType fromString(String? value) =>
      EnumHelper.fromString<DocType>(DocType.values, value);
}
