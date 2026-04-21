import 'package:equatable/equatable.dart';

class RefMaster extends Equatable {
  final String id;
  final List<String> references;

  const RefMaster({required this.id, required this.references});

  /// Convert JSON/Map to Model [UserDeviceID.fromMap]
  factory RefMaster.fromMap(Map<String, dynamic> map) => RefMaster(
    id: map['id'] as String,
    references: List<String>.from(map['references'] ?? []),
  );

  /// Create List of String from List of Map [fromMapList]
  static List<String> fromMapList(List<Map<String, dynamic>> mapList) {
    return mapList.expand((map) => List<String>.from(map['references'] ?? [])).toList();
  }

  /// Convert UserModel to a map for storing in Firestore [toMap]
  /// [id] is device id
  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'references': references,
  };

  /// Convert Model to toCache Function [toCache]
  /// [data] to be stored in cache
  /// [id] to be used as cache key
  Map<String, dynamic> toCache() => <String, dynamic>{
    'id': id,
    'data': toMap(),
  };

  @override
  List<Object?> get props => [id, references];
}
