import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/live_support/data/models/live_chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// workspaces_live_chat_db/{workspaceId}/chats/{employeeId}/messages/{messageId}

class LiveSupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the base `chats` collection for a given workspace.
  CollectionReference<Map<String, dynamic>> _chatsCollection(
    String workspaceId,
  ) {
    return _firestore
        .collection(liveChatSupportDBColPath) // Top-level collection
        .doc(workspaceId)
        .collection('chats'); // Nested under each workspace
  }

  /// Returns the chat document reference for a specific user within a workspace.
  DocumentReference<Map<String, dynamic>> _chatMessageRef(
    String workspaceId,
    String employeeId,
  ) {
    return _chatsCollection(workspaceId).doc(employeeId);
  }

  /// Get a stream of chat overviews/summary ordered by latest activity.
  Stream<QuerySnapshot<Map<String, dynamic>>> getChatOverviews({
    required String workspaceId,
  }) {
    return _chatsCollection(
      workspaceId,
    ).orderBy('updatedAt', descending: true).snapshots();
  }

  /// Get real-time messages for a specific chat (i.e., user).
  Stream<List<LiveChatMessage>> getChatMessages({
    required String workspaceId,
    required String userId,
  }) {
    return _chatMessageRef(workspaceId, userId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LiveChatMessage.fromMap(doc.data()))
              .toList(),
        );
  }

  /*// Send a message to a user's chat thread.
  Future<void> sendMessage({
    required String workspaceId,
    required String userId,
    required LiveSupportMessage message,
  }) async {
    final messagesRef = _chatDocRef(
      workspaceId,
      userId,
    ).collection('messages').doc();
    await messagesRef.set(message.toMap());
  }*/

  Future<void> sendMessageAndUpdateChat({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String messageText,
    required String workspaceId,
    String? userName, // Optional: set if creating chat for first time
  }) async {
    final message = LiveChatMessage(
      senderId: senderId,
      senderRole: senderRole,
      message: messageText,
    );

    final chatDoc = _firestore
        .collection(liveChatSupportDBColPath) // Top-level collection
        .doc(workspaceId)
        .collection('chats')
        .doc(chatId);

    // ✅ Ensure chat document exists before writing to subcollection
    await chatDoc.set({
      'lastMessage': message.message,
      'updatedAt': message.createdAt,
      if (userName != null) 'userName': userName,
    }, SetOptions(merge: true)); // merge = only updates provided fields

    // ✅ Add message to messages subcollection
    await chatDoc.collection('messages').add(message.toMap());
  }

  Future<void> updateChatResolvedStatus({
    required String chatId,
    required bool isResolved,
    required String workspaceId,
  }) {
    return _chatMessageRef(
      workspaceId,
      chatId,
    ).update({'isResolved': isResolved});
  }

  /*/// Update a message by its ID in a specific user's chat.
  Future<void> updateMessage({
    required String workspaceId,
    required String userId,
    required String messageId,
    required LiveSupportMessage updatedMessage,
  }) async {
    await _chatDocRef(
      workspaceId,
      userId,
    ).collection('messages').doc(messageId).update(updatedMessage.toMap());
  }

  /// Delete a message by its ID from a user's chat.
  Future<void> deleteMessage({
    required String workspaceId,
    required String userId,
    required String messageId,
  }) async {
    await _chatDocRef(
      workspaceId,
      userId,
    ).collection('messages').doc(messageId).delete();
  }

  /// Delete an entire chat thread for a user.
  Future<void> deleteChat({
    required String workspaceId,
    required String userId,
  }) async {
    await _chatDocRef(workspaceId, userId).delete();
  }*/
}
