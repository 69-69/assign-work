import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/access_control/presentation/cubit/access_control_cubit.dart';
import 'package:assign_erp/features/auth/data/model/workspace_model.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/live_support/data/models/live_chat_model.dart';
import 'package:assign_erp/features/live_support/presentation/bloc/chat/chat_bloc.dart';
import 'package:assign_erp/features/live_support/presentation/bloc/live_chat_bloc.dart';
import 'package:assign_erp/features/live_support/presentation/widget/chat_input.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientChatDashboard extends StatefulWidget {
  final String chatId;
  const ClientChatDashboard({super.key, required this.chatId});

  @override
  State<ClientChatDashboard> createState() => _ClientChatDashboardState();
}

class _ClientChatDashboardState extends State<ClientChatDashboard> {
  final ScrollController _scrollController = ScrollController();
  final _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Workspace? get _workspace => context.workspace;
  Employee? get _employee => context.employee;
  String get _chatId => widget.chatId;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage(String? senderRole) async {
    final msg = _controller.text.trim();
    if (msg.isEmpty || senderRole == null) return;

    final workspaceId = _workspace?.id ?? '';
    final employeeId = _employee?.id ?? '';
    final userName = _employee?.username ?? 'Unknown User';

    /// 2. Create message with embedded summary
    final message = LiveChatMessage(
      senderId: employeeId,
      senderRole: senderRole,
      message: msg,
    );

    /// 3. Add message to BLoC
    context.read<ChatBloc>().add(
      AddChat<LiveChatMessage>(
        workspaceId: workspaceId,
        userName: userName,
        message: message,
        chatId: _chatId,
      ),
    );

    _controller.clear();
    // After adding the message, scroll to the bottom
    _scrollToBottom();
    // Refocus the TextField
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    final senderRole = context.getRoleName;

    return CustomScaffold(
      title: liveSupportScreenTitle,
      body: _buildMessageList(),
      actions: const [],
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: ChatInput(
          controller: _controller,
          focusNode: _focusNode,
          onFieldSubmitted: () => _sendMessage(senderRole),
        ),
      ),
      floatingActionBtnLocation: FloatingActionButtonLocation.miniCenterFloat,
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

    /*return StreamBuilder<List<LiveChatMessage>>(
      stream: _chatService.getChatMessages(
        workspaceId: workspaceId,
        userId: chatId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (!snapshot.hasData) {
          return Center(child: context.loader);
        }

        final messages = snapshot.data!;
        return _buildMessageBody(messages, chatId);
      },
    );*/
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

    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == _chatId;

        return _listCard(isMe, message);
      },
    );
  }

  Align _listCard(bool isMe, LiveChatMessage message) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: context.screenWidth * 0.7),
        decoration: BoxDecoration(
          color: isMe ? kSuccessColor : kGrayBlueColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message.message,
          style: const TextStyle(color: kWhiteColor),
        ),
      ),
    );
  }
}

/// -------------End-------
/*class _ClientChatDashboardState extends State<ClientChatDashboard> {
  final _chatService = LiveSupportService();
  final _controller = TextEditingController();

  Workspace? get _workspace => context.workspace;
  Employee? get _employee => context.employee;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final workspaceId = _workspace?.id ?? '';
    final chatId = _employee?.id ?? '';
    final senderRole = _employee?.role.name ?? '';
    final userName = _employee?.username ?? 'Unknown User';

    try {
      await _chatService.sendMessageAndUpdateChat(
        workspaceId: workspaceId,
        chatId: chatId,
        senderId: chatId,
        senderRole: senderRole,
        messageText: text,
        userName: userName,
      );
      _controller.clear();
    } catch (e) {
      debugPrint('Failed to send message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: liveSupportScreenTitle,
      body: _buildMessageList(),
      actions: const [],
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: _buildChatInput(),
      ),
      floatingActionBtnLocation: FloatingActionButtonLocation.miniCenterFloat,
    );
  }

  Widget _buildMessageList() {
    final workspaceId = _workspace?.id ?? '';
    final chatId = _employee?.id ?? '';

    return StreamBuilder<List<LiveSupportMessage>>(
      stream: _chatService.getChatMessages(
        workspaceId: workspaceId,
        userId: chatId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (!snapshot.hasData) {
          return Center(child: context.loader);
        }

        final messages = snapshot.data!;
        return _buildMessageBody(messages, chatId);
      },
    );
  }

  ListView _buildMessageBody(List<LiveSupportMessage> messages, String chatId) {
    return ListView.builder(
      itemCount: messages.length,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == chatId;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
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

/*class _TenantChatDashboardState extends State<TenantChatDashboard> {
  final _chatService = LiveSupportService();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage(String workspaceId, String userId) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = LiveSupportMessage(
      senderId: userId,
      message: text,
      senderRole: context.employee?.role.name ?? '',
      timestamp: DateTime.now(),
    );

    _chatService.sendMessage(
      workspaceId: workspaceId,
      userId: userId,
      message: message,
    );

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final workspaceId = context.workspace?.id ?? '';
    final userId = context.employee?.id ?? '';

    return CustomScaffold(
      title: TenantChatDashboardTitle,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text('Side Users'), _buildMessageList(workspaceId, userId)],
      ),
      actions: const [],
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: _buildChatInput(workspaceId, userId),
      ),
      floatingActionBtnLocation: FloatingActionButtonLocation.miniCenterFloat,
    );
  }

  Widget _buildMessageList(String workspaceId, String userId) {
    return StreamBuilder<List<LiveSupportMessage>>(
      stream: _chatService.getChatMessages(
        workspaceId: workspaceId,
        userId: userId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (!snapshot.hasData) {
          return Center(child: context.loader);
        }

        final messages = snapshot.data!;
        return _buildMessageBody(messages, userId);
      },
    );
  }

  ListView _buildMessageBody(List<LiveSupportMessage> messages, String userId) {
    return ListView.builder(
      itemCount: messages.length,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == userId;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatInput(String workspaceId, String userId) {
    return CustomTextField(
      key: const Key('live_support_field'),
      controller: _controller,
      keyboardType: TextInputType.text,
      onFieldSubmitted: (_) => _sendMessage(workspaceId, userId),
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
          onPressed: () => _sendMessage(workspaceId, userId),
        ),
      ),
    );
  }
}*/
