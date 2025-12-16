// lib/user_profile_screen.dart
import 'package:flutter/material.dart';

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
      // Pop UserProfileScreen, then pop ChatScreen to go back to the chat list
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

    // FIX 1: Get the correct background color from the theme
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // FIX 2: Set divider color based on the theme
    final dividerColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      // FIX 3: Ensure Scaffold uses the theme's background color
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // FIX 4: Pass the correct theme colors to the AppBar builder
          _buildCustomAppBar(context, primaryColor, isDarkMode, _handleMenuSelection, backgroundColor),

          SliverList(
            delegate: SliverChildListDelegate(
              [
                // 1. Profile Details (Pic, Name, Status)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(userImageUrl),
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
                          color: userStatus == 'Online' ? Colors.green : Colors.grey,
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

                // FIX: Use the theme-specific divider color
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

  // --- Helper Widgets ---

  // NOTE: Function signature updated to include 'backgroundColor'
  SliverAppBar _buildCustomAppBar(
      BuildContext context, Color primaryColor, bool isDarkMode, void Function(BuildContext, String) onSelect, Color backgroundColor) {
    return SliverAppBar(
      // FIX 5: Use the calculated background color for the AppBar
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
        // 3-dot Menu (Dropdown)
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Theme.of(context).textTheme.bodyLarge?.color),
          // FIX 6: Explicitly set background color for the popup menu (optional, but good practice)
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

  // (Other helper widgets remain the same, using the context theme data)
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