import 'package:assign_erp/core/util/enum_util.dart';

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
  itemMaster,
  pSale,
  employee,
}

extension DocTypeExtension on DocType {
  /// [getName] Get the specific Enum Name (e.g. "itemMaster")
  String get getName => EnumUtil<DocType>(this).getName;

  /// For UI labels: 'itemMaster' -> 'Item Master'
  String get getLabel => EnumUtil<DocType>(this).getLabel;
}

class DocTypeUtil {
  static DocType fromString(String? value) =>
      EnumUtil.fromString<DocType>(DocType.values, value);
}
