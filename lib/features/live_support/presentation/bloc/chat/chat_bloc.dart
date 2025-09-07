import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/constants/collection_type.dart';
import 'package:assign_erp/features/live_support/data/models/live_chat_model.dart';
import 'package:assign_erp/features/live_support/presentation/bloc/live_chat_bloc.dart';

class ChatBloc extends LiveChatBloc<LiveChatMessage> {
  ChatBloc({required super.firestore})
    : super(
        collectionType: CollectionType.chats,
        collectionPath: liveChatSupportDBCollectionPath,
        fromFirestore: (data, id) => LiveChatMessage.fromMap(data, id: id),
        toFirestore: (chat) => chat.toMap(),
        toCache: (chat) => chat.toCache(),
      );
}

class ChatOverviewBloc extends LiveChatBloc<LiveChatOverview> {
  ChatOverviewBloc({required super.firestore})
    : super(
        collectionType: CollectionType.chats,
        collectionPath: liveChatSupportDBCollectionPath,
        fromFirestore: (data, id) => LiveChatOverview.fromMap(data),
        toFirestore: (chat) => chat.toMap(),
        toCache: (chat) => chat.toCache(),
      );
}
