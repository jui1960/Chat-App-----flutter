// lib/screens/chat_screen.dart (FINAL UPDATED CODE)

import 'package:flutter/material.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import 'user_profile_screen.dart';
import '../widgets/avatar_with_letter.dart';


class ChatScreen extends StatelessWidget {
  final String chatId;
  final String userName;
  final String userStatus;
  final String userImageUrl;


  // FIX: const keyword রিমুভ করা হলো
  ChatScreen({
    super.key,
    required this.chatId,
    required this.userName,
    required this.userStatus,
    required this.userImageUrl,
  });


  @override
  Widget build(BuildContext context) {
    // ... (rest of the build method is unchanged and correct)
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
            MessageInput(chatId: chatId),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildChatAppBar(BuildContext context, Color primaryColor, bool isDarkMode, String displayStatus, bool isOnline) {
    return AppBar(
      backgroundColor: isDarkMode ? Theme.of(context).appBarTheme.backgroundColor : Colors.white,
      elevation: 0,
      titleSpacing: 0,

      title: InkWell(
        onTap: () {
          // --- NAVIGATION TO USER PROFILE SCREEN ---
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                userName: userName,
                userStatus: displayStatus,
                userImageUrl: userImageUrl,
              ),
            ),
          );
          // ----------------------------------------
        },
        child: Row(
          children: [
            AvatarWithLetter(
              imageUrl: userImageUrl,
              userName: userName,
              radius: 20,
              isOnline: isOnline,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
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
          onPressed: () {},
        ),
      ],
    );
  }
}