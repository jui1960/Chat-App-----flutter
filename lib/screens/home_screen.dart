import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NEW
import 'package:firebase_auth/firebase_auth.dart';     // NEW
import 'package:chat_app/menu_view.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/theme_notifier.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/search_screen.dart';
import 'login_screen.dart'; // Log out এর জন্য

// *** NOTE: Conversation Model is now OBSOLETE if we use Firestore data ***
// We will now fetch data directly from Firestore's 'users' collection.

// --- Chats View Widget (First Tab Content) ---
// Changed to StatefulWidget to handle Firebase StreamBuilder
class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  // বর্তমানে লগইন থাকা ইউজারের UID
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // দুটি ইউজারের UID ব্যবহার করে একটি ইউনিক চ্যাট আইডি তৈরি করা
  String _getChatId(String user1Id, String user2Id) {
    if (user1Id.compareTo(user2Id) > 0) {
      return '${user1Id}_$user2Id';
    } else {
      return '${user2Id}_$user1Id';
    }
  }

  // চ্যাট শুরু করার ফাংশন
  void _startChat(String peerId, String peerName, String peerImageUrl) {
    if (currentUserId == null) return;

    final chatId = _getChatId(currentUserId!, peerId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          userName: peerName,
          userStatus: 'Online',
          userImageUrl: peerImageUrl,
        ),
      ),
    );
  }

  // লগআউট ফাংশন
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // --- BUILD METHOD: Renders the List of All Users from Firestore ---
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor = isDarkMode ? Colors.white : Colors.black;
    final listBackgroundColor = isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white;

    return Column(
      children: [
        // --- Header with Title and Icons ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ChatApp",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: headerTextColor),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.search, color: Theme.of(context).colorScheme.secondary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                  ),
                  // Added Logout Button beside Search Icon
                  IconButton(
                    icon: Icon(Icons.exit_to_app, color: Theme.of(context).colorScheme.secondary),
                    onPressed: _logout,
                  ),
                ],
              )
            ],
          ),
        ),

        // --- List Content (Firebase StreamBuilder) ---
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: listBackgroundColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: StreamBuilder<QuerySnapshot>(
              // Firestore থেকে 'users' কালেকশনের ডেটা রিয়েল-টাইমে লোড করা হচ্ছে
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading users: ${snapshot.error}'));
                }

                // বর্তমানে লগইন থাকা ইউজারকে লিস্ট থেকে বাদ দেওয়া
                final allUsers = snapshot.data!.docs
                    .where((doc) => doc.id != currentUserId)
                    .toList();

                if (allUsers.isEmpty) {
                  return const Center(child: Text('You are the only user, start inviting friends!'));
                }

                // ইউজারদের লিস্ট প্রদর্শন
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allUsers.length,
                  separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 80,
                      endIndent: 10,
                      color: isDarkMode ? Colors.grey.shade800 : const Color(0xFFF1F1F1)),
                  itemBuilder: (context, index) {
                    final userData = allUsers[index].data() as Map<String, dynamic>;
                    final userId = allUsers[index].id;

                    final username = userData['fullName'] ?? userData['username'] ?? 'Chat User';
                    final userImageUrl = userData['imageUrl'] ?? 'https://via.placeholder.com/150';
                    final userEmail = userData['email'] ?? 'Tap to chat';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        backgroundImage: NetworkImage(userImageUrl),
                      ),
                      title: Text(username,
                          style: TextStyle(fontWeight: FontWeight.bold, color: headerTextColor)),
                      subtitle: Text(
                        userEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                      ),
                      trailing: Text('New User', // Placeholder for time/status
                          style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade600 : Colors.grey)),

                      // চ্যাট শুরু করার লজিক
                      onTap: () => _startChat(userId, username, userImageUrl),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// --- Rest of HomeScreen (unchanged structure) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _widgetOptions = <Widget>[
    const ChatsView(),
    const MenuView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF0F5F8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: isDarkMode ? Colors.white60 : Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? const Color(0xFF1E2733) : Colors.white,
      ),
    );
  }
}