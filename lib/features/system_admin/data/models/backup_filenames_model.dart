import 'package:equatable/equatable.dart';

class BackupFilename extends Equatable {
  final String id;
  final String filename;

  const BackupFilename({required this.id, required this.filename});

  /// Convert JSON/Map to Model [UserDeviceID.fromMap]
  factory BackupFilename.fromMap(Map<String, dynamic> map) => BackupFilename(
    id: map['id'] as String,
    filename: map['filename'] as String,
  );

  /// Create List of String from List of Map [fromMapList]
  static List<String> fromMapList(List<Map<String, dynamic>> mapList) {
    return mapList.map((map) => map['filename'] as String).toList();
  }

  /// Convert UserModel to a map for storing in Firestore [toMap]
  /// [id] is device id
  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'filename': filename,
  };

  /// Convert Model to toCache Function [toCache]
  /// [data] to be stored in cache
  /// [id] to be used as cache key
  Map<String, dynamic> toCache() => <String, dynamic>{
    'id': id,
    'data': toMap(),
  };

  @override
  List<Object?> get props => [id, filename];
}
