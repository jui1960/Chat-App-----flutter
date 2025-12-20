import 'package:flutter/material.dart';
import '../widgets/message_bubble.dart' as BubbleWidget;
import '../widgets/message_input.dart' as InputWidget;
import 'user_profile_screen.dart';
import '../widgets/avatar_with_letter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;
  final String userName;
  final String userStatus;
  final String userImageUrl;

  final String peerId;

  ChatScreen({
    super.key,
    required this.chatId,
    required this.userName,
    required this.userStatus,
    required this.userImageUrl,
  }) : peerId = _getPeerId(FirebaseAuth.instance.currentUser!.uid, chatId);

  static String _getPeerId(String currentUserId, String fullChatId) {
    final ids = fullChatId.split('_');
    return ids.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.secondary;

    String displayStatus;
    if (userStatus == 'Online') {
      displayStatus = 'Online';
    } else if (userStatus.isNotEmpty) {
      displayStatus = 'Last seen $userStatus';
    } else {
      displayStatus = 'Offline';
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _buildChatAppBar(context, primaryColor, isDarkMode, displayStatus, userStatus == 'Online'),

      body: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 0),
        child: Column(
          children: [
            Expanded(child: BubbleWidget.MessageBubble(chatId: chatId)),

            StreamBuilder<DocumentSnapshot>(
              stream: ChatService().getBlockStatus(chatId),
              builder: (context, snapshot) {
                final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                final chatData = snapshot.hasData && snapshot.data!.exists
                    ? snapshot.data!.data() as Map<String, dynamic>? ?? {}
                    : {};

                final isBlockedByMe = chatData['blockedBy_$currentUserId'] == true;
                final isBlockedByPeer = chatData['blockedBy_$peerId'] == true;

                if (isBlockedByMe) {
                  return _buildBlockedStatusWidget(context, 'You have blocked $userName.', isBlockedByMe);
                }

                if (isBlockedByPeer) {
                  return _buildBlockedStatusWidget(context, '$userName has blocked you. You cannot send messages.', isBlockedByPeer);
                }

                return InputWidget.MessageInput(chatId: chatId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedStatusWidget(BuildContext context, String message, bool isBlockedByMe) {
    final primaryColor = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isBlockedByMe ? Colors.red.shade100 : primaryColor.withOpacity(0.1),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isBlockedByMe ? Colors.red.shade800 : primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildChatAppBar(BuildContext context, Color primaryColor, bool isDarkMode, String displayStatus, bool isOnline) {
    void navigateToUserProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            userName: userName,
            userStatus: displayStatus,
            userImageUrl: userImageUrl,
            chatId: chatId,
          ),
        ),
      );
    }

    return AppBar(
      backgroundColor: isDarkMode ? Theme.of(context).appBarTheme.backgroundColor : Colors.white,
      elevation: 0,
      titleSpacing: 0,

      title: InkWell(
        onTap: navigateToUserProfile,
        child: Row(
          children: [
            AvatarWithLetter(
              imageUrl: userImageUrl,
              userName: userName,
              radius: 20,
              isOnline: isOnline,
            ),
            const SizedBox(width: 10),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
              builder: (context, chatSnapshot) {
                String displayedName = userName;
                String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

                if (chatSnapshot.hasData && currentUserId != null) {
                  final chatData = chatSnapshot.data!.data() as Map<String, dynamic>?;
                  final nicknameKey = 'nickname_$currentUserId';
                  final nickname = chatData?[nicknameKey] as String?;

                  if (nickname != null && nickname.isNotEmpty) {
                    displayedName = nickname;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayedName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      displayStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.videocam_outlined, color: primaryColor),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.call_outlined, color: primaryColor),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: navigateToUserProfile,
        ),
      ],
    );
  }
}