// lib/screens/user_profile_screen.dart (FINAL UPDATED CODE with const fixes)

import 'package:flutter/material.dart';
import '../widgets/avatar_with_letter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatelessWidget {
// ... (Constructor and _setNickname, _showSetNicknameDialog, _deleteConversation, _handleMenuSelection methods are unchanged and correct)

  final String userName;
  final String userStatus;
  final String userImageUrl;
  final String chatId;

  const UserProfileScreen({
    super.key,
    required this.userName,
    required this.userStatus,
    required this.userImageUrl,
    required this.chatId,
  });

  // ✅ নিকনেম সেভ করা/মুছে ফেলা (unchanged)
  Future<void> _setNickname(BuildContext context, String? newNickname) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not logged in.')),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('chats').doc(chatId);
    final nicknameKey = 'nickname_$currentUserId';

    try {
      if (newNickname == null || newNickname.isEmpty) {
        // Nickname মুছে ফেলা (Clear Nickname)
        await chatRef.update({
          nicknameKey: FieldValue.delete(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nickname cleared for $userName')),
        );
      } else {
        // Nickname সেট করা
        await chatRef.set({
          nicknameKey: newNickname,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nickname set to "$newNickname" for $userName')),
        );
      }
      if(Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // ডায়ালগ বন্ধ করা
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update nickname: ${e.toString()}')),
      );
    }
  }

  // ✅ নিকনেম ডায়ালগ দেখানো (টাইপিং ফিক্সড, unchanged)
  void _showSetNicknameDialog(BuildContext context) {
    final controller = TextEditingController();
    final primaryColor = Theme.of(context).colorScheme.secondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // ডায়ালগের কনটেন্ট কালার কঠোরভাবে সাদা রাখা হলো
        backgroundColor: Colors.white,
        title: Text('Set Nickname for $userName',
            style: const TextStyle(color: Colors.black)),
        content: TextField(
          controller: controller,
          // ✅ FIX: ইনপুট টেক্সট কালার কঠোরভাবে কালো সেট করা হলো
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: "Enter Nickname",
            hintStyle: const TextStyle(color: Colors.grey),
            // ফোকাস থাকার সময় আন্ডারলাইন কালার নিশ্চিত করা হলো
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            // সাধারণ আন্ডারলাইন কালার
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: Text('Set', style: TextStyle(color: primaryColor)),
            onPressed: () {
              _setNickname(context, controller.text.trim());
            },
          ),
        ],
      ),
    );
  }

  // ডিলিট ফাংশন (unchanged)
  Future<void> _deleteConversation(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('chats').doc(chatId);

    try {
      final messagesSnapshot = await chatRef.collection('messages').get();
      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      await chatRef.delete();

      Navigator.of(context)
        ..pop()
        ..pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversation with $userName deleted successfully!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete chat: ${e.toString()}')),
      );
    }
  }


  void _handleMenuSelection(BuildContext context, String result) {
    switch (result) {
      case 'delete':
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
                  Navigator.of(ctx).pop();
                  _deleteConversation(context);
                },
              ),
            ],
          ),
        );
        break;
    //...
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
                      // ✅ StreamBuilder: নিকনেম/আসল নাম ডিসপ্লে (You ছাড়া)
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

                          return Text(
                            displayedName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          );
                        },
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
                // Nickname সেট করার অপশন
                _buildSettingsItem(
                    context, Icons.person_outline, 'Set Nickname', primaryColor,
                        () => _showSetNicknameDialog(context)),

                // ✅ অপশন: Clear Nickname
                _buildSettingsItem(
                    context, Icons.clear_all, 'Clear Nickname', primaryColor,
                        () => _setNickname(context, null)),

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
                    context, Icons.delete_outline, 'Delete Chat', primaryColor, () => _handleMenuSelection(context, 'delete')),

                // Safe Area Padding
                SizedBox(height: bottomPadding + 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets (Const keyword removed) ---
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
    // এখানে const ব্যবহার করা যেত না কারণ Theme.of(context) const নয়
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
    // এখানে const ব্যবহার করা যেত না কারণ primaryColor একটি final রানটাইম ভেরিয়েবল
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