import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme_notifier.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/screens/edit_profile_screen.dart';
import '../widgets/avatar_with_letter.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  Stream<DocumentSnapshot>? _userStream;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .snapshots();
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _editProfileName(BuildContext context, String currentName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(currentDisplayName: currentName),
      ),
    );
  }

  // ✅ নতুন ফাংশন: অ্যাকাউন্ট ডিলিট করার কনফার্মেশন ডায়ালগ
  void _showDeleteAccountDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final dialogBackgroundColor = isDarkMode ? theme.colorScheme.surface : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final contentColor = isDarkMode ? Colors.white70 : Colors.black87;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBackgroundColor,
        title: Text('Permanently Delete Account?', style: TextStyle(color: textColor)),
        content: Text(
          'WARNING: This action is irreversible. All your chats, profile data, and messages will be permanently deleted from our servers. Are you absolutely sure?',
          style: TextStyle(color: contentColor),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel', style: TextStyle(color: contentColor)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop(); // কনফার্মেশন ডায়ালগ বন্ধ
              _deleteAccountPermanently(context);
            },
          ),
        ],
      ),
    );
  }

  // ✅ নতুন ফাংশন: অ্যাকাউন্ট ডিলিট করার মূল লজিক
  void _deleteAccountPermanently(BuildContext context) async {
    final userId = _currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not found or logged out.')));
      return;
    }

    try {
      // ১. Firestore ডেটা ডিলিট (User Document)
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // ২. Firebase Auth থেকে ইউজার ডিলিট
      await _currentUser!.delete();

      // ৩. ডিলিট সফল হলে লগইন স্ক্রিনে নেভিগেট
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account permanently deleted.')));

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: ${e.message}. Please try logging in again and immediately deleting.')));
      // যদি ডিলিট ব্যর্থ হয়, ব্যবহারকারীকে লগআউট করা
      _logout(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')));
      _logout(context);
    }
  }


  @override
  Widget build(BuildContext context) {
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
          _buildProfileSection(context, surfaceColor),
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

          // ✅ নতুন বাটন: Account Delete Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _showDeleteAccountDialog(context),
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text('Delete Account', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900, // ডিলিট বাটন: গাঢ় লাল
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
            ),
          ),
          const SizedBox(height: 15),

          // বিদ্যমান লগআউট বাটন
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700, // লগআউট বাটন: হালকা লাল
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

  Widget _buildProfileSection(BuildContext context, Color cardColor) {
    if (_currentUser == null || _userStream == null) {
      return const Center(child: Text("User not logged in."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading profile: ${snapshot.error}'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        final userImageUrl = userData?['imageUrl'] ?? '';
        final displayName = userData?['fullName'] ?? userData?['username'] ?? 'New User';
        final email = _currentUser!.email ?? 'Email not available';

        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: (isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1)), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: Row(
            children: [
              AvatarWithLetter(
                imageUrl: userImageUrl,
                userName: displayName,
                radius: 35,
                isOnline: false,
                onlineIndicatorBackgroundColor: cardColor,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.lightBlueAccent),
                onPressed: () {
                  _editProfileName(context, displayName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Helper Widgets (Unchanged) ---
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