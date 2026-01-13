import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:equatable/equatable.dart';

class WorkspaceChatGroup {
  final String workspaceId;
  final List<LiveChatOverview> summary;

  WorkspaceChatGroup({required this.workspaceId, required this.summary});
}

class LiveChatMessage extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String senderId;
  final String senderRole;
  final String message;
  final DateTime? createdAt;

  LiveChatMessage({
    this.id = '',
    required this.senderId,
    required this.senderRole,
    required this.message,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? _today;

  factory LiveChatMessage.fromMap(Map<String, dynamic> map, {String? id}) {
    return LiveChatMessage(
      id: id ?? map['id'],
      senderId: map['senderId'] ?? '',
      senderRole: map['senderRole'] ?? '',
      message: map['message'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      // createdAt: (map['createdAt']).toDate(),
    );
  }

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() => {
    // 'id': id,
    'senderId': senderId,
    'senderRole': senderRole,
    'message': message,
    'createdAt': createdAt?.toISOString,
  };

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var map = toMap();
    map['createdAt'] = createdAt?.toMilliseconds;

    return {'id': id, 'data': map};
  }

  @override
  List<Object?> get props => [id, senderId, senderRole, message, createdAt];
}

class LiveChatOverview {
  static get _today => DateTime.now();

  final String? userName;
  final String lastMessage;
  final DateTime? updatedAt;
  final bool isResolved;

  LiveChatOverview({
    this.userName,
    required this.lastMessage,
    DateTime? updatedAt,
    this.isResolved = false,
  }) : updatedAt = updatedAt ?? _today;

  factory LiveChatOverview.fromMap(Map<String, dynamic> map) {
    return LiveChatOverview(
      userName: map['userName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      isResolved: map['isResolved'] ?? false,
      updatedAt: toDateTimeFn(map['updatedAt']),
      // (map['updatedAt'] as createdAt).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'lastMessage': lastMessage,
    'isResolved': isResolved,
    'updatedAt': updatedAt?.toISOString,
    if (userName != null) 'userName': userName,
  };

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var map = toMap();
    var sec = updatedAt?.toMilliseconds;
    map['updatedAt'] = sec;

    return {'id': sec, 'data': map};
  }
}
