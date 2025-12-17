// lib/chat_screen.dart
import 'package:flutter/material.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import 'user_profile_screen.dart'; // <--- 1. Import the new screen (Ensure the path is correct)


class ChatScreen extends StatelessWidget {
  final String chatId;
  final String userName;
  final String userStatus;
  final String userImageUrl;


  const ChatScreen({
    super.key,
    required this.chatId,
    required this.userName,
    required this.userStatus,
    required this.userImageUrl,
  });


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.secondary;

    // NEW: Get the safe area padding from the bottom (System Navigation Bar Height)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      // Ensure Scaffold resizes when the keyboard opens
      resizeToAvoidBottomInset: true,
      appBar: _buildChatAppBar(context, primaryColor, isDarkMode),

      // UPDATED: Wrapping the body content with Padding to account for the System Navigation Bar
      body: Padding(
        // Apply bottom padding equal to the system's safe area height
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

  PreferredSizeWidget _buildChatAppBar(BuildContext context, Color primaryColor, bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode ? Theme.of(context).appBarTheme.backgroundColor : Colors.white,
      elevation: 0,
      titleSpacing: 0,
      // 2. Wrap the title content with InkWell for tapping
      title: InkWell(
        onTap: () {
          // --- NAVIGATION TO USER PROFILE SCREEN ---
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                userName: userName,
                userStatus: userStatus,
                userImageUrl: userImageUrl,
              ),
            ),
          );
          // ----------------------------------------
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(userImageUrl),
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
                  userStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: userStatus == 'Online' ? Colors.green : Colors.grey,
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