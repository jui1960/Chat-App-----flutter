// lib/screens/chat_screen.dart (FINAL CODE WITH BLOCK CHECK LOGIC)

import 'package:flutter/material.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import 'user_profile_screen.dart';
import '../widgets/avatar_with_letter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart'; // ✅ ChatService ইমপোর্ট করা হলো

class ChatScreen extends StatelessWidget {
  final String chatId;
  final String userName;
  final String userStatus;
  final String userImageUrl;

  // ✅ peerId বের করা হলো
  final String peerId;

  ChatScreen({
    super.key,
    required this.chatId,
    required this.userName,
    required this.userStatus,
    required this.userImageUrl,
  }) : peerId = _getPeerId(FirebaseAuth.instance.currentUser!.uid, chatId);

  // peerId বের করার ফাংশন
  static String _getPeerId(String currentUserId, String fullChatId) {
    // chatId ফরম্যাট: uid1_uid2 (যেখানে uid1 < uid2)
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
            Expanded(child: MessageBubble(chatId: chatId)),

            // ✅ StreamBuilder: ব্লক স্ট্যাটাস চেক করা এবং কন্ডিশনালি MessageInput রেন্ডার করা
            StreamBuilder<DocumentSnapshot>(
              stream: ChatService().getBlockStatus(chatId),
              builder: (context, snapshot) {
                final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                // Firestore থেকে ব্লকিং স্ট্যাটাস চেক
                final chatData = snapshot.hasData && snapshot.data!.exists
                    ? snapshot.data!.data() as Map<String, dynamic>? ?? {}
                    : {};

                // চেক: আমি কি ইউজারকে ব্লক করেছি?
                final isBlockedByMe = chatData['blockedBy_$currentUserId'] == true;

                // চেক: ইউজার কি আমাকে ব্লক করেছে?
                final isBlockedByPeer = chatData['blockedBy_$peerId'] == true;

                if (isBlockedByMe) {
                  return _buildBlockedStatusWidget(context, 'You have blocked $userName.', isBlockedByMe);
                }

                if (isBlockedByPeer) {
                  return _buildBlockedStatusWidget(context, '$userName has blocked you. You cannot send messages.', isBlockedByMe);
                }

                // যদি কেউ ব্লক না করে, তবে মেসেজ ইনপুট দেখাও
                return MessageInput(chatId: chatId);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ নতুন উইজেট: ব্লক স্ট্যাটাস দেখানোর জন্য
  Widget _buildBlockedStatusWidget(BuildContext context, String message, bool isBlockedByMe) {
    final primaryColor = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // আমি ব্লক করলে একটু ভিন্ন রং ব্যবহার করতে পারি
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
    // --- কমন নেভিগেশন ফাংশন ---
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
    // ----------------------------

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
            // ✅ StreamBuilder to dynamically show Nickname or Original Name
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
                      displayedName, // ✅ নিকনেম দেখানো হলো (You ছাড়া)
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