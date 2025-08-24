import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/column_row_builder.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/live_support/data/models/live_chat_model.dart';
import 'package:assign_erp/features/live_support/presentation/bloc/chat/live_support_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatOverviewPane extends StatefulWidget {
  final String clientWorkspaceId;
  final String? selectedChatId;
  final void Function(String chatId, String userName) onChatSelected;

  const ChatOverviewPane({
    super.key,
    required this.clientWorkspaceId,
    required this.onChatSelected,
    this.selectedChatId,
  });

  @override
  State<ChatOverviewPane> createState() => _ChatOverviewPaneState();
}

class _ChatOverviewPaneState extends State<ChatOverviewPane>
    with SingleTickerProviderStateMixin {
  final _liveSupportService = LiveSupportService();
  bool previousIsResolved = false; // Track the previous state
  // Track the drag direction
  double dragPosition = 0.0; // Track horizontal drag position
  double previousDragPosition = 0.0;
  final double dragThreshold = 10.0;

  bool _isDrawerOpen = false;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  String get workspaceId => widget.clientWorkspaceId;

  String? get selectedChatId => widget.selectedChatId;
  final double _beginWidth = 50;
  late double _endWidth;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kAnimateDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _endWidth = context.screenWidth * (context.isMobile ? 0.64 : 0.3);
    _widthAnimation = Tween<double>(
      begin: _beginWidth,
      end: _endWidth,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleToggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      _isDrawerOpen ? _controller.forward() : _controller.reverse();
    });
  }

  void _expandDrawer() {
    setState(() {
      _isDrawerOpen = true;
      _controller.forward();
    });
  }

  void _collapseDrawer() {
    setState(() {
      _isDrawerOpen = false;
      _controller.reverse();
    });
  }

  Size _calculateDrawerSize() =>
      Size(_isDrawerOpen ? _widthAnimation.value : _beginWidth, _beginWidth);

  @override
  Widget build(BuildContext context) {
    /*BlocProvider<ChatBloc>(
      create: (context) =>
          ChatBloc(firestore: FirebaseFirestore.instance)
            ..add(LoadChatOverviews<LiveChatMessage>(workspaceId: workspaceId)),
      child: Container(
        color: kGrayColor.toAlpha(0.2)),
        child:*/
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _liveSupportService.getChatOverviews(workspaceId: workspaceId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return context.buildError('Something went wrong...');
        }

        return Container(
          decoration: BoxDecoration(
            color: kGrayColor.toAlpha(0.2),
            border: Border(
              right: BorderSide(width: 10, color: kPrimaryColor.toAlpha(1)),
            ),
          ),
          child: !snapshot.hasData || snapshot.data?.size == 0
              ? const SizedBox.shrink()
              : _buildChatOverviewContent(snapshot.data!.docs),
        );
      },
      // ),
      // ),
    );
  }

  /*Widget _buildBody() {
    return BlocBuilder<ChatOverviewBloc, LiveChatState<LiveChatOverview>>(
      builder: (context, state) {
        return switch (state) {
          LoadingChats<LiveChatOverview>() => context.loader,
          ChatOverviewLoaded<LiveChatOverview>(data: var results) => _buildChatOverviewContent(
            results,
          ),
          LiveChatError<LiveChatOverview>(error: final error) =>
            context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }*/

  Widget _buildChatOverviewContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> chats,
  ) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          children: [
            Expanded(
              child: context.isMobile
                  ? _buildSidePanel(context, chats: chats)
                  : MouseRegion(
                      onEnter: (_) => _expandDrawer(),
                      onExit: (_) => _collapseDrawer(),
                      child: _buildSidePanel(context, chats: chats),
                    ),
            ),
            const SizedBox(height: 10),
            _buildDrawerToggleButton(context),
          ],
        );
      },
    );
  }

  Widget _buildSidePanel(
    BuildContext context, {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> chats = const [],
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: _buildChatList(context, chats))],
    );
  }

  Widget _buildDrawerToggleButton(BuildContext context) {
    return IconButton(
      style: IconButton.styleFrom(
        alignment: Alignment.center,
        focusColor: kLightBlueColor,
        backgroundColor: kTransparentColor,
        shape: const RoundedRectangleBorder(),
        fixedSize: _calculateDrawerSize(),
      ),
      icon: Icon(Icons.menu),
      onPressed: _handleToggleDrawer,
    );
  }

  Widget _buildChatList(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> chats,
  ) {
    final double width = _widthAnimation.value.clamp(100, _endWidth);

    return context.columnBuilder(
      mainAxisSize: MainAxisSize.min,
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final doc = chats[index];
        final isSelected = doc.id == selectedChatId;
        final chat = LiveChatOverview.fromMap(doc.data());

        return SizedBox(
          width: width,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              final chatId = doc.id;
              final pos = details.localPosition.dx;

              // Only update if drag position has moved enough to justify an update
              if ((pos - previousDragPosition).abs() > dragThreshold) {
                setState(() => dragPosition = pos);

                // Drag right to resolve, drag left to unresolve
                if (pos > 10) {
                  _markChatResolved(chatId, isResolved: true);
                } else if (pos < -10) {
                  _markChatResolved(chatId, isResolved: false);
                }

                // Update previous drag position for future comparison
                previousDragPosition = pos;
              }
            },

            onHorizontalDragEnd: (details) {
              setState(() => dragPosition = 0.0);
              previousDragPosition = 0.0; // Reset
            },
            child: _buildChatListTile(isSelected, chat, doc),
          ),
        );
      },
    );
  }

  ListTile _buildChatListTile(
    bool isSelected,
    LiveChatOverview chat,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: _getDragColor(dragPosition, isSelected: isSelected),
      leading: _buildUserAvatarWithStatus(chat),
      title: _buildChatTileHeader(chat, isSelected),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: kTextColor),
      ),
      onTap: () {
        widget.onChatSelected(doc.id, chat.userName!);
        _collapseDrawer();
      },
    );
  }

  // Method to determine background color based on drag position
  Color _getDragColor(double dragPos, {bool isSelected = false}) {
    if (dragPos > 10) return kSuccessColor.toAlpha(0.3);
    if (dragPos < -10) return kDangerColor.toAlpha(0.3);
    return isSelected ? kPrimaryAccentColor.toAlpha(0.1) : kTransparentColor;
  }

  Row _buildChatTileHeader(LiveChatOverview chat, bool isSelected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            chat.userName ?? 'Unknown User',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? kPrimaryAccentColor : kDarkTextColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            '${chat.updatedAt?.chatDatetime}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: kTextColor),
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatarWithStatus(LiveChatOverview chat) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          backgroundColor: kGrayBlueColor,
          child: Text(
            chat.userName.isNullOrEmpty
                ? '?'
                : chat.userName![0].toUpperCaseAll,
            style: TextStyle(color: kLightColor),
          ),
        ),
        Positioned(
          right: -5,
          top: -5,
          child: chat.isResolved
              ? Icon(Icons.check_circle, color: kSuccessColor)
              : Icon(Icons.chat_bubble, color: kDangerColor),
        ),
      ],
    );
  }

  void _markChatResolved(String chatId, {required bool isResolved}) {
    // Only proceed if the resolved state has changed
    if (previousIsResolved != isResolved) {
      // Update Firestore or dispatch Bloc event
      _liveSupportService.updateChatResolvedStatus(
        chatId: chatId,
        isResolved: isResolved,
        workspaceId: workspaceId,
      );

      // Show the snack-bar only if the state changes
      context.showAlertOverlay(
        "Marked as ${isResolved ? 'resolved' : 'unresolved'}",
      );

      // Update the previous state to the new one
      previousIsResolved = isResolved;
    }
  }
}
