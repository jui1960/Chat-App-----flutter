// lib/screens/user_profile_screen.dart

import 'package:flutter/material.dart';
// ✅ AvatarWithLetter উইজেটটি ইমপোর্ট করা হয়েছে
import '../widgets/avatar_with_letter.dart';

class UserProfileScreen extends StatelessWidget {
  final String userName;
  final String userStatus;
  final String userImageUrl;

  const UserProfileScreen({
    super.key,
    required this.userName,
    required this.userStatus,
    required this.userImageUrl,
  });

  void _handleMenuSelection(BuildContext context, String result) {
    switch (result) {
      case 'delete':
        Navigator.of(context)
          ..pop()
          ..pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversation with $userName deleted.')),
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

    // স্ট্যাটাস থেকে Online চেক করা হচ্ছে
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
                      // 🛑 FIX: CircleAvatar-কে AvatarWithLetter দিয়ে রিপ্লেস করা হলো
                      AvatarWithLetter(
                        imageUrl: userImageUrl,
                        userName: userName,
                        radius: 40,
                        isOnline: isOnline,
                        // প্রোফাইল স্ক্রিনের ব্যাকগ্রাউন্ড কালার ইন্ডিকেটরের জন্য পাস করা হলো
                        onlineIndicatorBackgroundColor: backgroundColor,
                      ),
                      // --------------------------------------------------------
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
                    context, Icons.delete_outline, 'Delete Chat', primaryColor, () {}),

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