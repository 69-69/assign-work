import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/data/role/workspace_role.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/live_support/data/models/live_chat_model.dart';
import 'package:assign_erp/features/live_support/presentation/bloc/chat/chat_bloc.dart';
import 'package:assign_erp/features/live_support/presentation/bloc/live_chat_bloc.dart';
import 'package:assign_erp/features/live_support/presentation/widget/chat_input.dart';
import 'package:assign_erp/features/live_support/presentation/widget/chat_overview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Live support dashboard
class AgentChatDashboard extends StatefulWidget {
  final String? clientWorkspaceId;
  const AgentChatDashboard({super.key, this.clientWorkspaceId});

  @override
  State<AgentChatDashboard> createState() => _AgentChatDashboardState();
}

class _AgentChatDashboardState extends State<AgentChatDashboard> {
  String? selectedChatId;
  String? selectedUserName;

  String get _clientWorkspaceId =>
      widget.clientWorkspaceId ?? ''; // Same as Client's WorkspaceId
  String get _agentId =>
      context.workspace?.agentId ?? ''; // Same as Agent's WorkspaceId

  void _selectChat(String chatId, String userName) {
    setState(() {
      selectedChatId = chatId;
      selectedUserName = userName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: liveSupportScreenTitle,
      body: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 🧭 LEFT PANEL: Chat list
          ChatOverviewPane(
            onChatSelected: _selectChat,
            selectedChatId: selectedChatId,
            clientWorkspaceId: _clientWorkspaceId,
          ),

          /*SizedBox(
            width: context.screenWidth * 0.3,
            child: ChatOverviewPane(
              workspaceId: _clientWorkspaceId,
              onChatSelected: _selectChat,
              selectedChatId: selectedChatId,
            ),
          ),*/
          /// Message window
          _buildRightPane(context),
        ],
      ),
    );
  }

  /* 🧭 LEFT PANEL: Chat list
  _buildLeftPane(BuildContext context) {
    return Container(
      color: kLightBlueColor.toAlpha(0.3)),
      child: ChatOverviewPane(
        workspaceId: _clientWorkspaceId,
        onChatSelected: _selectChat,
        selectedChatId: selectedChatId,
      ),
    );
  }*/

  /// 💬 RIGHT PANEL: Message window
  Expanded _buildRightPane(BuildContext context) {
    return Expanded(
      child: selectedChatId == null
          ? Center(
              child: Text(
                'Select a conversation',
                style: context.textTheme.bodyLarge,
                textScaler: TextScaler.linear(context.textScaleFactor),
              ),
            )
          : ChatDetailPane(
              workspaceId: _clientWorkspaceId,
              agentId: _agentId,
              selectedChatId: selectedChatId ?? '',
              userName: selectedUserName ?? '',
            ),
    );
  }
}

/// Chat detail pane
class ChatDetailPane extends StatefulWidget {
  final String workspaceId;
  final String selectedChatId;
  final String userName;
  final String agentId;

  const ChatDetailPane({
    super.key,
    required this.workspaceId,
    required this.selectedChatId,
    required this.userName,
    required this.agentId,
  });

  @override
  State<ChatDetailPane> createState() => _ChatDetailPaneState();
}

class _ChatDetailPaneState extends State<ChatDetailPane> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _chatId => widget.selectedChatId;
  String get _agentId => widget.agentId;
  String get _workspaceId => widget.workspaceId;
  // String get _userName => widget.userName;

  Future<void> _sendMessage() async {
    final msg = _controller.text.trim();
    if (msg.isEmpty) return;

    /// 2. Create message with embedded summary
    final message = LiveChatMessage(
      senderId: _agentId,
      message: msg,
      senderRole: WorkspaceRole.agentFranchise.getName,
    );

    /// 3. Add message to BLoC
    context.read<ChatBloc>().add(
      AddChat<LiveChatMessage>(
        chatId: _chatId,
        message: message,
        workspaceId: _workspaceId,
      ),
    );

    _controller.clear();
    // After adding the message, scroll to the bottom
    _scrollToBottom();
    // Refocus the TextField
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Get current scroll position and max scroll extent
        final currentPosition = _scrollController.position.pixels;
        final maxScrollExtent = _scrollController.position.maxScrollExtent;

        // Only scroll to the bottom if the user is already at the bottom
        if (currentPosition == maxScrollExtent) {
          _scrollController.animateTo(
            maxScrollExtent,
            duration: kAnimateDuration,
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>(
      create: (context) => ChatBloc(firestore: FirebaseFirestore.instance)
        ..add(
          LoadChatMessagesById<LiveChatMessage>(
            workspaceId: _workspaceId,
            chatId: _chatId,
          ),
        ),
      child: Column(
        children: [
          Expanded(child: _buildMessageList()),
          Padding(
            padding: EdgeInsets.all(20),
            child: ChatInput(
              controller: _controller,
              focusNode: _focusNode,
              onFieldSubmitted: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return BlocBuilder<ChatBloc, LiveChatState<LiveChatMessage>>(
      builder: (context, state) {
        return switch (state) {
          LoadingChats<LiveChatMessage>() => context.loader,
          ChatsLoaded<LiveChatMessage>(data: var results) => _buildMessageBody(
            results,
          ),
          LiveChatError<LiveChatMessage>(error: final error) =>
            context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  ListView _buildMessageBody(List<LiveChatMessage> messages) {
    // Sort messages by ascending createdAt before displaying
    messages.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(0);
      final bTime = b.createdAt ?? DateTime(0);
      return aTime.compareTo(bTime);
    });

    // After messages are loaded or updated, scroll to the bottom
    _scrollToBottom();

    return _buildCard(messages);
  }

  ListView _buildCard(List<LiveChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isAgent = msg.senderRole == WorkspaceRole.agentFranchise.getName;

        return _listCard(isAgent, msg);
      },
    );
  }

  Align _listCard(bool isAgent, LiveChatMessage msg) {
    return Align(
      alignment: isAgent ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isAgent
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 2),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAgent ? kSuccessColor : kGrayBlueColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              msg.message,
              style: const TextStyle(color: kWhiteColor),
            ),
          ),
          Text(msg.createdAt!.chatDatetime),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /*Align _listCard(bool isAgent, LiveChatMessage msg) {
    return Align(
      alignment: isAgent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isAgent ? kSuccessColor : kGrayBlueColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(msg.message, style: const TextStyle(color: kLightColor)),
      ),
    );
  }*/
}

/// -------------End-------
/*class _ChatDetailPaneState extends State<ChatDetailPane> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = {
      'senderId': widget.workspaceId,
      'senderRole': WorkspaceRole.agentFranchise.label,
      'message': text,
      'timestamp': DateTime.now(),
    };

    final messagesRef = FirebaseFirestore.instance
        .collection(liveChatSupportDBCollectionPath)
        .doc(widget.workspaceId)
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');

    messagesRef.add(message);

    FirebaseFirestore.instance
        .collection(liveChatSupportDBCollectionPath)
        .doc(widget.workspaceId)
        .collection('chats')
        .doc(widget.chatId)
        .update({'lastMessage': text, 'lastTimestamp': DateTime.now()});

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection(liveChatSupportDBCollectionPath)
        .doc(widget.workspaceId)
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp');

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: messagesRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return context.loader;
              final messages = snapshot.data!.docs;

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: messages.map((msg) {
                  final data = msg.data() as Map<String, dynamic>;
                  final isAgent =
                      data['senderRole'] == WorkspaceRole.agentFranchise.label;

                  return Align(
                    alignment: isAgent
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isAgent ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(data['message']),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(child: _buildChatInput()),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatInput() {
    return CustomTextField(
      key: const Key('live_support_field'),
      controller: _controller,
      keyboardType: TextInputType.text,
      onFieldSubmitted: (_) => _sendMessage(),
      inputDecoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.all(1.0),
        hintText: 'Enter your message...',
        label: const Text('Live Support'),
        alignLabelWithHint: true,
        filled: true,
        fillColor: kLightBlueColor.toAlpha(0.5)),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.support_agent, size: 15),
        suffixIcon: IconButton(
          icon: const Icon(Icons.send, color: kPrimaryLightColor),
          onPressed: () => _sendMessage(),
        ),
      ),
    );
  }
}*/

/*Great thinking — that’s a more **desktop-friendly layout** (like Slack, Intercom, or Zendesk) using a **split-screen interface**. This avoids navigation and keeps everything visible, reactive, and stateful.

---

## 🧱 Layout Plan: Split-Screen Chat UI

We'll build a `Row` with two main parts:

| Section     | Widget                             | Width  |
| ----------- | ---------------------------------- | ------ |
| Left Panel  | `ChatOverviewPane` — list of chats | 30–35% |
| Right Panel | `ChatDetailPane` — selected chat   | 65–70% |

---

## ✅ Full Example: `AgentChatDashboard`

```dart
class AgentChatDashboard extends StatefulWidget {
  final String tenantId;
  const AgentChatDashboard({super.key, required this.tenantId});

  @override
  State<AgentChatDashboard> createState() => _AgentChatDashboardState();
}

class _AgentChatDashboardState extends State<AgentChatDashboard> {
  String? selectedChatId;
  String? selectedUserName;

  void _selectChat(String chatId, String userName) {
    setState(() {
      selectedChatId = chatId;
      selectedUserName = userName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Chat Support')),
      body: Row(
        children: [
          /// 🧭 LEFT PANEL: Chat list
          Container(
            width: 300,
            color: Colors.grey[100],
            child: ChatOverviewPane(
              tenantId: widget.tenantId,
              onChatSelected: _selectChat,
              selectedChatId: selectedChatId,
            ),
          ),

          /// 💬 RIGHT PANEL: Message window
          Expanded(
            child: selectedChatId == null
                ? const Center(child: Text('Select a conversation'))
                : ChatDetailPane(
                    tenantId: widget.tenantId,
                    chatId: selectedChatId!,
                    userName: selectedUserName ?? '',
                  ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🧭 ChatOverviewPane

```dart
class ChatOverviewPane extends StatelessWidget {
  final String tenantId;
  final String? selectedChatId;
  final void Function(String chatId, String userName) onChatSelected;

  const ChatOverviewPane({
    super.key,
    required this.tenantId,
    required this.onChatSelected,
    this.selectedChatId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection('chats')
          .orderBy('lastTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final chats = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (_, i) {
            final chat = chats[i];
            final data = chat.data() as Map<String, dynamic>;
            final isSelected = chat.id == selectedChatId;

            return ListTile(
              selected: isSelected,
              title: Text(data['userName'] ?? 'Unknown'),
              subtitle: Text(data['lastMessage'] ?? ''),
              onTap: () => onChatSelected(chat.id, data['userName'] ?? ''),
              trailing: data['isResolved'] == true
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            );
          },
        );
      },
    );
  }
}
```

---

## 💬 ChatDetailPane (from previous response)

Same as the `ChatDetailScreen`, just embedded directly. Example:

```dart
class ChatDetailPane extends StatefulWidget {
  final String tenantId;
  final String chatId;
  final String userName;

  const ChatDetailPane({
    super.key,
    required this.tenantId,
    required this.chatId,
    required this.userName,
  });

  @override
  State<ChatDetailPane> createState() => _ChatDetailPaneState();
}

class _ChatDetailPaneState extends State<ChatDetailPane> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = {
      'senderId': 'agent_123',
      'senderRole': 'agent',
      'message': text,
      'timestamp': DateTime.now(),
    };

    final messagesRef = FirebaseFirestore.instance
        .collection('tenants')
        .doc(widget.tenantId)
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');

    messagesRef.add(message);

    FirebaseFirestore.instance
        .collection('tenants')
        .doc(widget.tenantId)
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'lastMessage': text,
      'lastTimestamp': DateTime.now(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('tenants')
        .doc(widget.tenantId)
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp');

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: messagesRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final messages = snapshot.data!.docs;

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: messages.map((msg) {
                  final data = msg.data() as Map<String, dynamic>;
                  final isAgent = data['senderRole'] == 'agent';

                  return Align(
                    alignment: isAgent ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isAgent ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(data['message']),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Type a message...'),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

---

## ✅ Summary

| Feature                          | ✅ Implemented |
| -------------------------------- | ------------- |
| Split layout with `Row`          | ✅             |
| In-place chat loading (no route) | ✅             |
| Responsive and reactive          | ✅             |
| Scalable for multiple tenants    | ✅             |

---

### 👉 Want to Add:

* Responsive support for mobile?
* Chat status tags (e.g., unread, new)?
* Auto-scroll to bottom?

Let me know, and I’ll extend it accordingly!
*/
