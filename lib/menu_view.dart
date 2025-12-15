import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'package:chat_app/screens/login_screen.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF1E2733) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
            child: Text(
              'Settings & Profile',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color
              ),
            ),
          ),
          _buildProfileSection(context, user, surfaceColor),
          const SizedBox(height: 25),
          _buildSectionHeader(context, 'Account & Tools'),
          _buildSettingsCard(
            context,
            surfaceColor,
            [
              _buildOptionTile(context, Icons.people_outline, 'Friends & Connections', Icons.arrow_forward_ios),
              _buildOptionTile(context, Icons.security_outlined, 'Privacy Settings', Icons.arrow_forward_ios),
              _buildOptionTile(context, Icons.notifications_none, 'Notifications', Icons.arrow_forward_ios),
            ],
          ),
          const SizedBox(height: 25),
          _buildSectionHeader(context, 'Preferences'),
          _buildSettingsCard(
            context,
            surfaceColor,
            [
              _buildDarkModeTile(context),
              _buildOptionTile(context, Icons.language_outlined, 'Language', Icons.arrow_forward_ios,
                  subtitle: 'English (US)'),
            ],
          ),
          const SizedBox(height: 25),
          _buildSectionHeader(context, 'Support'),
          _buildSettingsCard(
            context,
            surfaceColor,
            [
              _buildOptionTile(context, Icons.help_outline, 'Help Center', null),
              _buildOptionTile(context, Icons.info_outline, 'About ChatApp', null),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, User? user, Color cardColor) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Safety check: Get the first letter of the display name
    String initials = 'U';
    String? displayName = user?.displayName;

    if (displayName != null && displayName.isNotEmpty) {
      // FIX: Ensure the string is not empty before calling substring(0, 1)
      initials = displayName.substring(0, 1).toUpperCase();
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: (isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1)), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: theme.colorScheme.secondary,
            child: Text(
              initials, // Use the safely determined initial
              style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName ?? 'New User',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'Status: Available',
                  style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.lightBlueAccent),
            onPressed: () {
              // TODO: Navigate to Edit Profile Screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, Color cardColor, List<Widget> children) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: (isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1)), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int index = entry.key;
          Widget tile = entry.value;
          bool isLast = index == children.length - 1;

          return Column(
            children: [
              tile,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptionTile(
      BuildContext context, IconData icon, String title, IconData? trailingIcon,
      {String? subtitle}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.secondary),
      title: Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: theme.textTheme.bodySmall?.color))
          : null,
      trailing: trailingIcon != null
          ? Icon(trailingIcon, size: 16, color: theme.iconTheme.color)
          : null,
      onTap: () {
        // Handle navigation for each setting
      },
    );
  }

  Widget _buildDarkModeTile(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return ListTile(
      leading: Icon(
          themeNotifier.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: theme.colorScheme.secondary),
      title: Text('Dark Mode', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
      trailing: Switch(
        value: themeNotifier.isDarkMode,
        onChanged: (value) {
          themeNotifier.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
        },
        activeColor: theme.colorScheme.secondary,
      ),
      onTap: () {
        themeNotifier.setThemeMode(!themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light);
      },
    );
  }
}