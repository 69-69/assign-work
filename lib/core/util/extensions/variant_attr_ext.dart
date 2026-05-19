import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';

extension AttributeMapperExt on Map<String, Attribute> {
  Map<String, String> toCodeMap({bool useValue = false}) {
    return map((k, v) {
      final val = useValue ? v.value : (v.code.isEmpty ? v.safeCode : v.code);
      return MapEntry(k, val);
    });
  }
}

extension ListSortExt<T> on List<T> {
  void sortByComparable(int Function(T a) score) {
    sort((a, b) => score(a).compareTo(score(b)));
  }
}
