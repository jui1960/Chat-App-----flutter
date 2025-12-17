// lib/screens/user_profile_screen.dart (FINAL UPDATED CODE)

import 'package:flutter/material.dart';
import '../widgets/avatar_with_letter.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firebase ইমপোর্ট করা হলো

class UserProfileScreen extends StatelessWidget {
  final String userName;
  final String userStatus;
  final String userImageUrl;
  final String chatId; // ✅ chatId প্যারামিটার যোগ করা হলো

  const UserProfileScreen({
    super.key,
    required this.userName,
    required this.userStatus,
    required this.userImageUrl,
    required this.chatId, // ✅ chatId রিকোয়্যার্ড করা হলো
  });

  // ✅ নতুন ডিলিট ফাংশন: Firebase থেকে চ্যাট ডিলিট করবে
  Future<void> _deleteConversation(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('chats').doc(chatId);

    try {
      // 1. সাব-কালেকশন (messages) ডিলিট করা
      // (প্রোডাকশন অ্যাপে ক্লাউড ফাংশন বা batch delete ব্যবহার করা উচিত। এখানে সহজ লুপ দেখানো হলো)
      final messagesSnapshot = await chatRef.collection('messages').get();
      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. মেইন চ্যাট ডক ডিলিট করা
      await chatRef.delete();

      // ডিলিট সফল হলে UserProfileScreen এবং ChatScreen থেকে ব্যাক করা
      // এটি ডিলিট হওয়ার পর হোম স্ক্রিনে নিয়ে যাবে, যেখানে লিস্ট আপডেট হয়ে যাবে।
      Navigator.of(context)
        ..pop() // UserProfileScreen
        ..pop(); // ChatScreen

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversation with $userName deleted successfully!')),
      );

    } catch (e) {
      // ডিলিট ব্যর্থ হলে
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete chat: ${e.toString()}')),
      );
    }
  }


  void _handleMenuSelection(BuildContext context, String result) {
    switch (result) {
      case 'delete':
      // ✅ ডিলিট করার আগে কনফার্মেশন ডায়ালগ দেখানো
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Conversation?'),
            content: Text('Are you sure you want to delete all messages with $userName? This action cannot be undone and will remove the chat from your list.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
              TextButton(
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(ctx).pop(); // ডায়ালগ বন্ধ
                  _deleteConversation(context); // ডিলিট ফাংশন কল করা
                },
              ),
            ],
          ),
        );
        break;
      case 'block':
        debugPrint('Blocking user $userName');
        break;
      case 'report':
        debugPrint('Reporting user $userName');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.secondary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final isOnline = userStatus == 'Online';


    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildCustomAppBar(context, primaryColor, isDarkMode, _handleMenuSelection, backgroundColor),

          SliverList(
            delegate: SliverChildListDelegate(
              [
                // 1. Profile Details (Pic, Name, Status)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
                  child: Column(
                    children: [
                      AvatarWithLetter(
                        imageUrl: userImageUrl,
                        userName: userName,
                        radius: 40,
                        isOnline: isOnline,
                        onlineIndicatorBackgroundColor: backgroundColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        userStatus,
                        style: TextStyle(
                          fontSize: 14,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Audio/Video/Mute Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionIcon(Icons.call, 'Call', primaryColor, () {}),
                          const SizedBox(width: 30),
                          _buildActionIcon(Icons.videocam, 'Video', primaryColor, () {}),
                          const SizedBox(width: 30),
                          _buildActionIcon(Icons.notifications_off, 'Mute', primaryColor, () {}),
                        ],
                      ),
                    ],
                  ),
                ),

                Divider(color: dividerColor),

                // 2. Customization Block
                _buildSectionHeader('Customization', isDarkMode),
                _buildSettingsItem(
                    context, Icons.person_outline, 'Set Nickname', primaryColor,
                        () {}),
                _buildSettingsItem(context, Icons.group_add_outlined,
                    'Create Group Chat with $userName', primaryColor, () {}),
                _buildSettingsItem(
                    context, Icons.push_pin_outlined, 'Pinned Messages', primaryColor,
                        () {}),

                Divider(color: dividerColor),

                // 3. Search in Conversation
                _buildSettingsItem(
                    context, Icons.search, 'Search in Conversation', primaryColor,
                        () {}),
                _buildSettingsItem(context, Icons.notifications_none,
                    'Notifications & Sounds', primaryColor, () {}),

                Divider(color: dividerColor),

                // 4. Privacy & Support
                _buildSectionHeader('Privacy & Support', isDarkMode),
                _buildSettingsItem(context, Icons.cancel_outlined, 'Restrict', primaryColor,
                        () {}),
                _buildSettingsItem(
                    context, Icons.block_outlined, 'Block', primaryColor, () {}),
                _buildSettingsItem(
                    context, Icons.flag_outlined, 'Report', primaryColor, () {}),
                _buildSettingsItem(
                    context, Icons.delete_outline, 'Delete Chat', primaryColor, () => _handleMenuSelection(context, 'delete')), // ✅ Delete বাটনে ক্লিক করলে ডিলিট লজিক কল হবে

                // Safe Area Padding
                SizedBox(height: bottomPadding + 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets (Unchanged) ---
  SliverAppBar _buildCustomAppBar(
      BuildContext context, Color primaryColor, bool isDarkMode, void Function(BuildContext, String) onSelect, Color backgroundColor) {
    return SliverAppBar(
      backgroundColor: backgroundColor,
      pinned: true,
      elevation: 1,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Text(
        userName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Theme.of(context).textTheme.bodyLarge?.color),
          color: isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
          onSelected: (String result) => onSelect(context, result),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete Conversation', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            ),
            PopupMenuItem<String>(
              value: 'block',
              child: Text('Block', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            ),
            PopupMenuItem<String>(
              value: 'report',
              child: Text('Report', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            ),
          ],
        ),
      ],
    );
  }

  // (বাকি helper functions unchanged)
  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, IconData icon, String title,
      Color primaryColor, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildActionIcon(
      IconData icon, String label, Color primaryColor, VoidCallback onTap) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: primaryColor, size: 24),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: primaryColor, fontSize: 12),
        ),
      ],
    );
  }
}