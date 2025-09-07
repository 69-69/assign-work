//-------------------------------
// 🔥 Firestore Collections types
//-------------------------------
import 'package:assign_erp/core/util/str_util.dart';

enum CollectionType { global, workspace, chats, stores, clients }

/* USAGE:
* final type = CollectionType.global;
* print(type.label); // Output: global
* */
extension CollectionTypeExtension on CollectionType {
  String get getValue => getEnumName<CollectionType>(this);
  /*String get label {
    return switch (this) {
      CollectionType.global => 'global', // Global collections
      CollectionType.chats => 'chats', // Chat conversations
      CollectionType.stores => 'stores', // Company-specific stores/shops
      CollectionType.clients => 'clients', // Agent-clients mapping
      /// Workspace-specific collections: is based on WorkspaceRole (eg.: agentFranchise, subscriber, etc)
      CollectionType.workspace => 'workspace',
    };
  }*/
}
